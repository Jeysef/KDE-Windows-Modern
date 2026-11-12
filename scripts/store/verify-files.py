#!/usr/bin/env python3
"""Check that each store product carries exactly this release's zip, intact.

Reads the file list (name, MD5) from each product's edit page and compares
it with dist/. The public API lags by several minutes, so it is not used.

Usage: scripts/store/verify-files.py [NAME ...]
"""
import hashlib
import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("publish", HERE / "store-publish.py")
publish = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publish)

products, _ = publish.load()
version = publish.release_version()
names = sys.argv[1:] or list(products)
b = publish.Browser()
bad = 0
for name in names:
    p = products[name]
    zip_name = p["zip"].format(v=version)
    local = hashlib.md5((publish.ROOT / "dist" / zip_name).read_bytes()).hexdigest()
    publish.open_files(b, p["id"])
    rows = b.js("""[...document.querySelectorAll('tr')].filter(r => r.querySelector('[data-file_name]')).map(r =>
        [r.querySelector('[data-file_name]').getAttribute('data-file_name'), r.children[1].innerText.trim(),
         r.querySelector('[data-ppload-file-version]')?.value || ''])""")
    ok = rows == [[zip_name, local, version]]
    bad += not ok
    print(f"{name:20} {'OK' if ok else 'PROBLEM'}  {rows if not ok else zip_name}")
sys.exit(1 if bad else 0)
