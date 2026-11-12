#!/usr/bin/env python3
"""Publish Windows Modern to the KDE Store (store.kde.org).

The store has no upload API and sits behind an anti-bot check, so this
drives a real Firefox with its own profile (WebDriver BiDi, see bidi.py).
Sign in to the store once in that window; the login lasts about a month.

    store-publish.py launch                  # open the store Firefox (sign in once)
    store-publish.py status [NAME ...]       # version and files per product
    store-publish.py create NAME ... --images DIR
    store-publish.py update NAME ...|all [--changelog FILE]
    store-publish.py close                   # quit the store Firefox

Products, categories and texts: products.json and descriptions/*.md.
Zips come from dist/ (scripts/package.sh); the version is the release's.
"""
import argparse
import json
import pathlib
import subprocess
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
from bidi import PORT, Browser  # noqa: E402

PROFILE = pathlib.Path.home() / ".local/share/windows-modern/store-firefox"
STORE = "https://store.kde.org"
REPO_URL = "https://github.com/Jeysef/KDE-Windows-Modern"
PRODUCTS_FILE = HERE / "products.json"
FILES_STEP = "#add-product-form-t-2"
CHANGELOG_STEP = "#add-product-form-t-3"


def load():
    data = json.loads(PRODUCTS_FILE.read_text())
    return {k: v for k, v in data.items() if not k.startswith("_")}, data


def save_ids(products):
    data = json.loads(PRODUCTS_FILE.read_text())
    for name, p in products.items():
        data[name]["id"] = p["id"]
    PRODUCTS_FILE.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def release_version():
    meta = ROOT / "plasma/look-and-feel/org.kde.windowsmodern.dark/metadata.json"
    return json.loads(meta.read_text())["KPlugin"]["Version"]


def description(p):
    text = (HERE / "descriptions" / p["description"]).read_text().rstrip("\n")
    if "variant" in p:
        text = text.replace("{VARIANT}", p["variant"][0]).replace("{OTHER}", p["variant"][1])
    return text


def js_str(s):
    return json.dumps(s)


# ── browser ────────────────────────────────────────────────────────────
def launch(_args):
    PROFILE.mkdir(parents=True, exist_ok=True)
    subprocess.Popen(["firefox", "--profile", str(PROFILE), "--no-remote", "--new-instance",
                      "--remote-debugging-port", str(PORT), "--width", "1400", "--height", "1000",
                      f"{STORE}/u/Jeysef/products"],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    print("Store Firefox started. Sign in there if the page asks you to.")


def close(_args):
    subprocess.run(["pkill", "-f", "--", f"--profile {PROFILE}"])


def edit_page(b, pid, step=None):
    b.goto(f"{STORE}/p/{pid}/edit/")
    b.wait_for("!!document.querySelector('#add-product-form') && !!window.jQuery", timeout=30)
    time.sleep(3)  # the wizard sets itself up after load
    if step:
        b.js(f"document.querySelector('{step}').click()")
        time.sleep(1)


def open_files(b, pid):
    edit_page(b, pid, FILES_STEP)
    if not b.wait_for("document.querySelectorAll('[data-file_name]').length", timeout=40,
                      poke=f"document.querySelector('{FILES_STEP}').click()"):
        raise RuntimeError(f"{pid}: the file list did not load")
    time.sleep(1.5)


ROW = "(n => document.querySelector(`tr [data-file_name=\"${n}\"]`)?.closest('tr'))"


def file_rows(b):
    return b.js("""[...document.querySelectorAll('tr')].filter(r => r.querySelector('[data-file_name]')).map(r => ({
        name: r.querySelector('[data-file_name]').getAttribute('data-file_name'),
        version: r.querySelector('[data-ppload-file-version]')?.value || '',
        desc: r.querySelector('[data-ppload-file-description]')?.value || '',
        downloads: (r.children[7]?.innerText || '').trim()}))""")


def basics(b):
    return b.js("""({version: document.querySelector('input[name=version]').value,
                     description: document.querySelector('textarea[name=description]').value})""")


# ── status ─────────────────────────────────────────────────────────────
def status(args):
    products, _ = load()
    b = Browser()
    for name in args.names or products:
        p = products[name]
        if not p["id"]:
            print(f"{name}: not on the store yet")
            continue
        try:
            open_files(b, p["id"])
            rows = file_rows(b)
        except RuntimeError:
            edit_page(b, p["id"])
            rows = []
        print(f"{name} ({p['id']}): version {basics(b)['version']}")
        for r in rows:
            print(f"    {r['name']}  version={r['version'] or '-'}  downloads={r['downloads']}")


# ── update ─────────────────────────────────────────────────────────────
def upload_zip(b, pid, zip_path):
    """Upload to the Files step, which must be open."""
    if b.js(f"!!{ROW}({js_str(zip_path.name)})"):
        return False
    b.js("(() => { const c = document.querySelector('input[data-accept-checkbox]'); if (!c.checked) c.click(); })()")
    b.set_files("document.querySelector('input[type=file][data-file-upload][multiple]')", [str(zip_path)])
    if b.wait_for(f"!!{ROW}({js_str(zip_path.name)})", timeout=120):
        return True
    # On a product without files the new row only shows after a reload.
    open_files(b, pid)
    if not b.js(f"!!{ROW}({js_str(zip_path.name)})"):
        raise RuntimeError(f"{pid}: upload of {zip_path.name} did not finish")
    return True


def tidy_files(b, pid, zip_name, version, file_desc):
    """Label the current zip and archive every other one (downloads are kept)."""
    for attempt in range(4):  # the page saves these in the background; repeat until they stick
        open_files(b, pid)
        rows = file_rows(b)
        cur = next((r for r in rows if r["name"] == zip_name), None)
        old = [r["name"] for r in rows if r["name"] != zip_name]
        if cur and cur["version"] == version and cur["desc"] == file_desc and not old:
            return
        if attempt == 3:
            break
        b.js(f"""(() => {{ const row = {ROW}({js_str(zip_name)});
          for (const [sel, val] of [['[data-ppload-file-version]', {js_str(version)}], ['[data-ppload-file-description]', {js_str(file_desc)}]]) {{
            const i = row.querySelector(sel); i.focus(); i.value = val;
            i.dispatchEvent(new Event('input', {{bubbles: true}})); i.dispatchEvent(new Event('change', {{bubbles: true}})); i.blur(); }}
        }})()""")
        time.sleep(6)
        for name in old:
            b.js(f"{ROW}({js_str(name)})?.querySelector('[data-deletepploadfile-btn]')?.click()")
            time.sleep(4)  # a confirm() prompt, accepted by the session
    raise RuntimeError(f"{pid}: could not label/archive files: {file_rows(b)}")


def set_basics(b, pid, version, desc):
    edit_page(b, pid)
    b.js(f"""(() => {{
      const set = (el, v) => {{ el.value = v; el.dispatchEvent(new Event('input', {{bubbles: true}})); el.dispatchEvent(new Event('change', {{bubbles: true}})); }};
      set(document.querySelector('input[name=version]'), {js_str(version)});
      const ta = document.querySelector('textarea[name=description]'); set(ta, {js_str(desc)});
      const cm = ta.parentElement.querySelector('.CodeMirror'); if (cm && cm.CodeMirror) cm.CodeMirror.setValue({js_str(desc)});
    }})()""")
    b.js("document.querySelector('a[href=\"#finish\"]').click()")
    b.wait_for("!location.pathname.includes('/edit')", timeout=30)
    edit_page(b, pid)
    got = basics(b)
    if got["version"] != version or got["description"].strip() != desc.strip():
        raise RuntimeError(f"{pid}: version/description did not save")


def add_changelog(b, pid, title, text):
    edit_page(b, pid, CHANGELOG_STEP)
    entries = """(() => { const t = document.querySelector('#add-product-form-p-3')?.innerText || '';
                   const i = t.indexOf('Your Entries:'); return i >= 0 ? t.slice(i) : ''; })()"""
    if title in b.js(entries):
        return False
    b.js(f"""(() => {{
      document.querySelector('#update-title').value = {js_str(title)};
      document.querySelector('#modal-changlog .CodeMirror').CodeMirror.setValue({js_str(text)});
      document.querySelector('#update-text').value = {js_str(text)};
      [...document.querySelectorAll('#modal-changlog button')].find(e => /save/i.test(e.innerText)).click();
    }})()""")
    time.sleep(3)
    edit_page(b, pid, CHANGELOG_STEP)
    if title not in b.js(entries):
        raise RuntimeError(f"{pid}: changelog entry did not save")
    return True


def update(args):
    products, _ = load()
    version = release_version()
    names = list(products) if args.names == ["all"] else args.names
    changelog = pathlib.Path(args.changelog).read_text().rstrip("\n") if args.changelog else None
    b = Browser()
    for name in names:
        p = products[name]
        if not p["id"]:
            print(f"{name}: not on the store yet (use create)")
            continue
        zip_path = ROOT / "dist" / p["zip"].format(v=version)
        if not zip_path.exists():
            raise SystemExit(f"{zip_path} missing: run scripts/package.sh")
        open_files(b, p["id"])
        if upload_zip(b, p["id"], zip_path):
            print(f"{name}: uploaded {zip_path.name}")
        tidy_files(b, p["id"], zip_path.name, version, p["file_desc"])
        set_basics(b, p["id"], version, description(p))
        if changelog and add_changelog(b, p["id"], f"Version {version}", changelog):
            print(f"{name}: changelog added")
        print(f"{name}: {version} ✓  {STORE}/p/{p['id']}/")


# ── create ─────────────────────────────────────────────────────────────
def create(args):
    products, _ = load()
    version = release_version()
    images = pathlib.Path(args.images)
    b = Browser()
    for name in args.names:
        p = products[name]
        if p["id"]:
            print(f"{name}: already on the store ({p['id']})")
            continue
        b.goto(f"{STORE}/product/add")
        b.wait_for("!!document.querySelector('#title') && !!window.jQuery", timeout=30)
        time.sleep(3)
        desc = description(p)
        b.js(f"""(() => {{
          const set = (el, v) => {{ el.value = v; el.dispatchEvent(new Event('input', {{bubbles: true}})); el.dispatchEvent(new Event('change', {{bubbles: true}})); }};
          set(document.querySelector('#title'), {js_str(p['title'])});
          set(document.querySelector('#project_category_id'), {js_str(str(p['category']))});
          const ta = document.querySelector('textarea[name=description]'); set(ta, {js_str(desc)});
          const cm = ta.parentElement.querySelector('.CodeMirror'); if (cm && cm.CodeMirror) cm.CodeMirror.setValue({js_str(desc)});
          set(document.querySelector('#version'), {js_str(version)});
          set(document.querySelector('#source_url'), {js_str(REPO_URL)});
          set(document.querySelector('select[name=is_original_or_modification]'), {js_str(str(p['original']))});
          if ({js_str(str(p['license'] or ''))}) set(document.querySelector('#license_tag_id'), {js_str(str(p['license'] or ''))});
        }})()""")
        logo, *gallery = [images / i for i in p["images"] if (images / i).exists()]
        # Images travel with the form (multipart): no separate upload to wait for.
        b.set_files("document.querySelector('#image_small_upload')", [str(logo)])
        time.sleep(1)
        for i, pic in enumerate(gallery):
            sel = f"document.querySelectorAll('input.gallery-picture')[{i}]"
            if not b.wait_for(f"!!{sel}", timeout=5):
                break
            b.set_files(sel, [str(pic)])
            time.sleep(2)
        # The wizard unlocks each step only after validating the previous one.
        for _ in range(3):
            if b.js("!!document.querySelector('a[href=\"#finish\"]')?.offsetParent"):
                break
            b.js("document.querySelector('a[href=\"#next\"]').click()")
            time.sleep(2)
        if args.dry_run:
            print(f"{name}: dry run, stopped before saving")
            print("  step:", b.js("document.querySelector('.steps li.current')?.innerText.trim()"))
            print("  errors:", b.js("[...document.querySelectorAll('label.error, .has-error, .alert-danger')].filter(e => e.offsetParent).map(e => e.innerText.trim()).filter(Boolean)"))
            print("  fields:", b.js("({title: document.querySelector('#title').value, cat: document.querySelector('#project_category_id').value, version: document.querySelector('#version').value, license: document.querySelector('#license_tag_id').value, logo: document.querySelector('#image_small_upload').files.length, gallery: [...document.querySelectorAll('input.gallery-picture')].map(i => i.files.length)})"))
            b.shot(f"/tmp/store-dry-{name}.png")
            continue
        b.js("document.querySelector('a[href=\"#finish\"]').click()")
        if not b.wait_for("!location.pathname.includes('/product/add')", timeout=60):
            errs = b.js("[...document.querySelectorAll('.error, .has-error, label.error, .alert-danger')].map(e => e.innerText.trim()).filter(Boolean)")
            raise RuntimeError(f"{name}: the store did not accept the product: {errs}")
        b.goto(f"{STORE}/u/Jeysef/products")
        time.sleep(3)
        pid = b.js(f"""(() => {{ const a = [...document.querySelectorAll('a[href*="/p/"]')].find(a => a.innerText.trim().startsWith({js_str(p['title'])}));
                       return a ? Number(a.href.match(/\\/p\\/(\\d+)/)[1]) : null; }})()""")
        if not pid:
            raise RuntimeError(f"{name}: created, but its id was not found on the products page")
        p["id"] = pid
        save_ids(products)
        print(f"{name}: created {STORE}/p/{pid}/")
        zip_path = ROOT / "dist" / p["zip"].format(v=version)
        open_files_or_empty(b, pid)
        upload_zip(b, pid, zip_path)
        tidy_files(b, pid, zip_path.name, version, p["file_desc"])
        print(f"{name}: {zip_path.name} attached")


def open_files_or_empty(b, pid):
    edit_page(b, pid, FILES_STEP)
    b.wait_for("!!document.querySelector('input[type=file][data-file-upload][multiple]')", timeout=20)
    time.sleep(3)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("launch").set_defaults(fn=launch)
    sub.add_parser("close").set_defaults(fn=close)
    s = sub.add_parser("status"); s.add_argument("names", nargs="*"); s.set_defaults(fn=status)
    u = sub.add_parser("update"); u.add_argument("names", nargs="+"); u.add_argument("--changelog")
    u.set_defaults(fn=update)
    c = sub.add_parser("create"); c.add_argument("names", nargs="+"); c.add_argument("--images", required=True)
    c.add_argument("--dry-run", action="store_true")
    c.set_defaults(fn=create)
    args = ap.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
