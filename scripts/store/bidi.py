"""Minimal WebDriver BiDi client for a Firefox started with --remote-debugging-port.

Used by store-publish.py to drive store.kde.org in a real browser: the store
sits behind an anti-bot check and has no upload API, so a logged-in browser
is the only way in. Firefox keeps one BiDi session at a time and does not
end it when a client disconnects, so the session is always ended on exit.
"""
import asyncio
import atexit
import base64
import itertools
import json
import time

import websockets

PORT = 9333


class Browser:
    def __init__(self, port=PORT, wait=30):
        self.loop = asyncio.new_event_loop()
        self.ids = itertools.count(1)
        deadline = time.time() + wait
        while True:
            try:
                self.ws = self.loop.run_until_complete(websockets.connect(
                    f"ws://127.0.0.1:{port}/session", max_size=64 * 1024 * 1024))
                break
            except OSError:
                if time.time() > deadline:
                    raise
                time.sleep(1)
        self.call("session.new", {"capabilities": {"unhandledPromptBehavior": {"default": "accept"}}})
        atexit.register(self.close)
        self.ctx = self.call("browsingContext.getTree", {})["contexts"][0]["context"]

    # ── protocol ──
    def call(self, method, params):
        return self.loop.run_until_complete(self._call(method, params))

    async def _call(self, method, params):
        i = next(self.ids)
        await self.ws.send(json.dumps({"id": i, "method": method, "params": params}))
        while True:
            msg = json.loads(await asyncio.wait_for(self.ws.recv(), 120))
            if msg.get("id") == i:
                if msg.get("type") == "error":
                    raise RuntimeError(f"{method}: {msg.get('error')}: {msg.get('message')}")
                return msg["result"]

    def close(self):
        for step in (lambda: self.call("session.end", {}),
                     lambda: self.loop.run_until_complete(self.ws.close())):
            try:
                step()
            except Exception:
                pass

    # ── page ──
    def goto(self, url):
        return self.call("browsingContext.navigate", {"context": self.ctx, "url": url, "wait": "complete"})

    def js(self, expr):
        r = self.call("script.evaluate", {"expression": expr, "target": {"context": self.ctx},
                                          "awaitPromise": True, "resultOwnership": "none"})
        if r.get("type") == "exception":
            raise RuntimeError(r["exceptionDetails"].get("text"))
        return _value(r["result"])

    def wait_for(self, expr, timeout=30, every=1.0, poke=None):
        """Poll a JS expression until truthy; `poke` (JS) runs every few polls."""
        deadline, n = time.time() + timeout, 0
        while time.time() < deadline:
            value = self.js(expr)
            if value:
                return value
            n += 1
            if poke and n % 4 == 0:
                self.js(poke)
            time.sleep(every)
        return self.js(expr)

    def node(self, expr):
        r = self.call("script.evaluate", {"expression": expr, "target": {"context": self.ctx},
                                          "awaitPromise": False, "resultOwnership": "root"})
        res = r.get("result", {})
        if res.get("type") != "node":
            raise RuntimeError(f"not an element: {expr} -> {res.get('type')}")
        return {"sharedId": res["sharedId"]}

    def set_files(self, expr, paths):
        self.call("input.setFiles", {"context": self.ctx, "element": self.node(expr), "files": list(paths)})

    def shot(self, path, element=None):
        params = {"context": self.ctx}
        if element:
            params.update(origin="document", clip={"type": "element", "element": self.node(element)})
        data = self.call("browsingContext.captureScreenshot", params)["data"]
        with open(path, "wb") as f:
            f.write(base64.b64decode(data))


def _value(v):
    t = v.get("type")
    if t in ("string", "number", "boolean"):
        return v.get("value")
    if t in ("null", "undefined"):
        return None
    if t == "array":
        return [_value(x) for x in v.get("value", [])]
    if t == "object":
        return {k if isinstance(k, str) else _value(k): _value(x) for k, x in v.get("value", [])}
    return v.get("value", t)
