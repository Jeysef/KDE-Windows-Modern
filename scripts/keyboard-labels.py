#!/usr/bin/env python3
"""Label keyboard layouts the Windows way: by language, in capitals.

Windows shows the input language in the tray ("ENG", "CES", "DEU"); Plasma's
keyboard-layout widget shows the XKB layout code ("us", "cz", "de") unless the
layout has a label (System Settings → Keyboard → Layouts → Label). This fills
in those labels from XKB's own layout database, which lists the ISO 639
language of (almost) every layout, so it works for any language without a
hand-made table.

Rules:
- A label you set yourself is never touched.
- A variant's own language wins over its layout's ("ca(fr)" is French).
- Two layouts with the same language (us + gb) keep their codes, so you can
  still tell them apart.
- Layouts added later get labelled the next time this runs (it runs with
  `./install.sh layout`, and on its own).

Usage: scripts/keyboard-labels.py [--dry-run] [--self-test]
"""
import argparse
import pathlib
import subprocess
import sys
import xml.etree.ElementTree as ET

RULES = [pathlib.Path(p) for p in ("/usr/share/X11/xkb/rules/evdev.xml",
                                   "/usr/share/xkeyboard-config-2/rules/evdev.xml")]


def load_languages(rules):
    """{(layout, variant): ISO 639 code}; variant "" is the layout itself."""
    langs = {}
    for layout in ET.parse(rules).getroot().iterfind("./layoutList/layout"):
        name = layout.findtext("configItem/name")
        own = [c.text for c in layout.iterfind("configItem/languageList/iso639Id")]
        if own:
            langs[(name, "")] = own[0]
        for variant in layout.iterfind("variantList/variant"):
            vlangs = [c.text for c in variant.iterfind("configItem/languageList/iso639Id")]
            if vlangs:
                langs[(name, variant.findtext("configItem/name"))] = vlangs[0]
    return langs


def labels_for(layouts, variants, current, langs):
    """New label list: current labels kept, empty ones filled where the
    language is known and unique among the configured layouts."""
    codes = [langs.get((lay, var)) or langs.get((lay, "")) for lay, var in zip(layouts, variants)]
    out = []
    for cur, code in zip(current, codes):
        if cur or not code or codes.count(code) > 1:
            out.append(cur)
        else:
            out.append(code.upper())
    return out


def kread(key):
    r = subprocess.run(["kreadconfig6", "--file", "kxkbrc", "--group", "Layout", "--key", key],
                       capture_output=True, text=True, check=False)
    return r.stdout.strip()


def pad(values, n):
    return (values + [""] * n)[:n]


def self_test(langs):
    assert langs[("us", "")] == "eng" and langs[("cz", "")] == "ces", "base layouts"
    assert labels_for(["us", "cz"], ["", ""], ["", ""], langs) == ["ENG", "CES"]
    assert labels_for(["us", "cz"], ["", ""], ["", "CZ"], langs) == ["ENG", "CZ"], "keeps user labels"
    assert labels_for(["us", "gb"], ["", ""], ["", ""], langs) == ["", ""], "same language stays apart"
    assert labels_for(["de", "nonexistent"], ["", ""], ["", ""], langs) == ["DEU", ""], "unknown layout"
    print("keyboard-labels self-test passed")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--dry-run", action="store_true", help="print the labels, change nothing")
    ap.add_argument("--self-test", action="store_true", help="check the lookup against this system's XKB data")
    args = ap.parse_args()

    rules = next((p for p in RULES if p.exists()), None)
    if rules is None:
        print("XKB rules (evdev.xml) not found — skipped")
        return 77 if args.self_test else 0
    langs = load_languages(rules)
    if args.self_test:
        self_test(langs)
        return 0

    layouts = [x for x in kread("LayoutList").split(",") if x]
    if not layouts:
        print("No keyboard layouts configured in Plasma — nothing to label.")
        return 0
    variants = pad(kread("VariantList").split(","), len(layouts))
    current = pad(kread("DisplayNames").split(","), len(layouts))
    new = labels_for(layouts, variants, current, langs)
    for lay, var, old, lab in zip(layouts, variants, current, new):
        name = f"{lay}({var})" if var else lay
        print(f"  {name:12} {lab or name}" + ("" if lab == old else "   (new)"))
    if new == current or args.dry_run:
        return 0
    # --notify: KWin re-reads kxkbrc through a KConfigWatcher, which only
    # hears writes that announce themselves.
    subprocess.run(["kwriteconfig6", "--notify", "--file", "kxkbrc", "--group", "Layout",
                    "--key", "DisplayNames", ",".join(new)], check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
