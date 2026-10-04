#!/usr/bin/env python3
"""Static checks for the TapCare project.

The Flutter SDK is not available in this environment, so `flutter analyze`
cannot run. These checks cover the classes of error that a rename or a new
feature can introduce, which would otherwise only surface at build time:

  1. every import (relative and `package:`) resolves to a real file
  2. every `t('key')` used anywhere exists in BOTH hi and en
  3. no leftover references to the old package/application id
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures = []


def dart_files():
    for base in ("lib", "test"):
        for dirpath, _dirs, names in os.walk(os.path.join(ROOT, base)):
            for n in names:
                if n.endswith(".dart"):
                    yield os.path.join(dirpath, n)


def rel(path):
    return os.path.relpath(path, ROOT)


# ---- 1. imports resolve -------------------------------------------------
IMPORT_RE = re.compile(r"""import\s+'([^']+)'""")
for path in dart_files():
    src = open(path, encoding="utf-8").read()
    for target in IMPORT_RE.findall(src):
        if target.startswith("dart:"):
            continue
        if target.startswith("package:tapcare/"):
            candidate = os.path.join(ROOT, "lib", target[len("package:tapcare/"):])
        elif target.startswith("package:"):
            # Third-party package (flutter_riverpod, go_router, home_widget,
            # ...) — resolved by pub, not by this script.
            continue
        else:
            candidate = os.path.join(os.path.dirname(path), target)
        if not os.path.isfile(candidate):
            failures.append(f"{rel(path)}: unresolved import '{target}'")

# ---- 2. string keys exist in hi and en ----------------------------------
strings_src = open(os.path.join(ROOT, "lib/config/strings.dart"), encoding="utf-8").read()
# Entries are written across multiple lines and the English value is
# sometimes double-quoted (e.g. 'quoteOfDay': {'hi': '...', 'en': "..."}),
# so both quote styles are accepted.
VAL = r"""(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')"""
entry_re = re.compile(
    r"'([A-Za-z0-9_]+)'\s*:\s*\{\s*'hi'\s*:\s*" + VAL + r"\s*,\s*"
    r"'en'\s*:\s*" + VAL + r"\s*,?\s*\}",
    re.DOTALL,
)
entries = {m.group(1) for m in entry_re.finditer(strings_src)}

# any key present but missing one language
all_key_re = re.compile(r"'([A-Za-z0-9_]+)'\s*:\s*\{")
declared = set(all_key_re.findall(strings_src))
for key in declared:
    if key not in entries:
        failures.append(f"lib/config/strings.dart: key '{key}' missing 'hi' or 'en'")

USE_RE = re.compile(r"""\.t\(\s*'([A-Za-z0-9_]+)'""")
used = set()
for path in dart_files():
    src = open(path, encoding="utf-8").read()
    for key in USE_RE.findall(src):
        # `Strings(app.locale).t('key')` appears in the Strings doc comment.
        if key == "key":
            continue
        used.add(key)
        if key not in entries:
            failures.append(f"{rel(path)}: t('{key}') has no hi/en entry")

# keys built dynamically via s.t(currentSlot().key()) and the bear mood
# switch in lib/widgets/bear_pair.dart
DYNAMIC = {
    "morning",
    "afternoon",
    "evening",
    "night",
    "bearMoodLoving",
    "bearMoodHappy",
    "bearMoodCalm",
    "bearMoodSulky",
    "bearMoodSad",
    "bearMoodAngry",
}
for key in DYNAMIC:
    if key not in entries:
        failures.append(f"dynamic key '{key}' missing from strings.dart")

# ---- 4. Android splash theme attributes must really exist ----------------
# Regression guard: `android:windowSplashScreenIconBackgroundSize` was
# invented and broke `processDebugResources` with
# "style attribute ... not found". Well-formed XML is NOT enough — aapt
# validates attribute names. This check is deliberately narrow so it can
# never false-positive: it only inspects the `windowSplashScreen*` family,
# whose complete API 31 set is small and stable.
VALID_SPLASH_ATTRS = {
    "windowSplashScreenBackground",
    "windowSplashScreenAnimatedIcon",
    "windowSplashScreenIconBackgroundColor",
    "windowSplashScreenAnimationDuration",
    "windowSplashScreenBrandingImage",
}

for base, _dirs, names in os.walk(os.path.join(ROOT, "android")):
    for n in names:
        if not n.endswith("styles.xml"):
            continue
        p = os.path.join(base, n)
        raw = open(p, encoding="utf-8").read()
        raw = re.sub(r"<!--.*?-->", "", raw, flags=re.S)  # aapt ignores comments
        for attr in set(re.findall(r"android:(windowSplashScreen\w*)", raw)):
            if attr not in VALID_SPLASH_ATTRS:
                failures.append(
                    f"{rel(p)}: android:{attr} is not a real Android attribute"
                )

# ---- 4b. the native launch window stays artwork-free --------------------
# Regression guard for the screen the user deleted: a big pink heart with no
# text between the OS splash and the Flutter splash. Android 12 cannot skip its
# splash screen, but the splash *icon* can be made invisible, so BOTH native
# launch stages have to stay artwork-free — otherwise the app opens on a plain
# heart again and never reaches the "TapCare" splash on the first frame.
RES = os.path.join(ROOT, "android/app/src/main/res")
BLANK_SPLASH_ICON = "@drawable/ic_tapcare_splash_blank"

for rel_path in (
    "drawable/launch_background.xml",
    "drawable-v21/launch_background.xml",
):
    p = os.path.join(RES, rel_path)
    raw = re.sub(r"<!--.*?-->", "", open(p, encoding="utf-8").read(), flags=re.S)
    if "@drawable/" in raw:
        failures.append(
            f"{rel(p)}: must be blush only — any artwork here becomes a "
            f"text-less heart screen before the Flutter splash"
        )

p31 = os.path.join(ROOT, "android/app/src/main/res/values-v31/styles.xml")
raw31 = re.sub(r"<!--.*?-->", "", open(p31, encoding="utf-8").read(), flags=re.S)
icons = re.findall(
    r"android:windowSplashScreenAnimatedIcon\">([^<]+)<", raw31
)
if not icons:
    failures.append(
        f"{rel(p31)}: windowSplashScreenAnimatedIcon must be set explicitly to "
        f"{BLANK_SPLASH_ICON}; omitted, Android 12 falls back to the launcher icon"
    )
for icon in icons:
    if icon != BLANK_SPLASH_ICON:
        failures.append(
            f"{rel(p31)}: windowSplashScreenAnimatedIcon is '{icon}'; the only "
            f"allowed icon is {BLANK_SPLASH_ICON} (invisible) — a heart or logo "
            f"here is the text-less splash screen the user removed"
        )

# ---- 4c. project-owned res references must resolve ----------------------
# aapt reports a dangling `@drawable/...` only at `processDebugResources`,
# after a long wait. Only names this project owns (the `tapcare*` /
# `ic_tapcare*` convention) are checked, so framework and AndroidX resources
# can never false-positive.
def res_definitions():
    defined = set()
    for folder in os.listdir(RES):
        full = os.path.join(RES, folder)
        if not os.path.isdir(full):
            continue
        kind = folder.split("-")[0]
        if kind == "values":
            # colors/strings/styles are declared by NAME inside values/*.xml,
            # not by file name.
            for n in os.listdir(full):
                if not n.endswith(".xml"):
                    continue
                raw = open(os.path.join(full, n), encoding="utf-8").read()
                raw = re.sub(r"<!--.*?-->", "", raw, flags=re.S)
                for tag, name in re.findall(r'<(color|string|style)\s+name="([^"]+)"', raw):
                    defined.add((tag, name))
                    defined.add(("any", name))
            continue
        for n in os.listdir(full):
            stem = n.split(".")[0]
            defined.add((kind, stem))
            defined.add(("any", stem))
    return defined


RES_DEFS = res_definitions()
REF_RE = re.compile(r"@(drawable|mipmap|color|style|string|layout|xml)/([A-Za-z0-9_]+)")
android_xml = []
for base, _dirs, names in os.walk(os.path.join(ROOT, "android/app/src/main")):
    for n in names:
        if n.endswith(".xml"):
            android_xml.append(os.path.join(base, n))
for p in android_xml:
    raw = re.sub(r"<!--.*?-->", "", open(p, encoding="utf-8").read(), flags=re.S)
    for kind, name in REF_RE.findall(raw):
        if not name.startswith(("tapcare", "ic_tapcare")):
            continue
        if (kind, name) not in RES_DEFS:
            failures.append(f"{rel(p)}: @{kind}/{name} does not exist in res/")

# ---- 5. declared assets must exist on disk -------------------------------
# `flutter build` fails late and with an opaque message when pubspec points at
# a folder that is not in the repo, so it is checked here instead.
PUBSPEC = os.path.join(ROOT, "pubspec.yaml")
pubspec_src = open(PUBSPEC, encoding="utf-8").read()
for entry in re.findall(r"^\s*-\s+(assets/\S+)\s*$", pubspec_src, re.M):
    path = os.path.join(ROOT, entry.rstrip("/"))
    if not os.path.isdir(path):
        failures.append(f"pubspec.yaml: asset entry '{entry}' is not in the repo")

# Every artwork path the bears ask for must be a real file, or at least be
# documented in the folder README. The artwork PNGs are added by hand, so this
# is what catches a typo that would otherwise silently ship a placeholder.
ART_RE = re.compile(r"assets/[A-Za-z0-9_./-]+")
art_needed = set()
for path in dart_files():
    with open(path, encoding="utf-8") as fh:
        art_needed.update(ART_RE.findall(fh.read()))
for art in sorted(art_needed):
    folder = os.path.dirname(os.path.join(ROOT, art))
    if not os.path.isdir(folder):
        failures.append(f"artwork '{art}' has no folder in the repo")
        continue
    if os.path.isfile(os.path.join(ROOT, art)):
        continue
    readme = os.path.join(folder, "README.md")
    with open(readme, encoding="utf-8") as fh:
        documented = fh.read()
    if os.path.basename(art) not in documented:
        failures.append(
            f"artwork '{art}' is neither in the repo nor documented in "
            f"{rel(readme)} \u2014 the bears would render the placeholder"
        )

# ---- 6. no leftovers from the old name ----------------------------------
STALE = ("com.nudgebuddy", "package:nudgebuddy", "NudgeBuddyApp")
for dirpath, dirs, names in os.walk(ROOT):
    dirs[:] = [d for d in dirs if d not in (".git", "build", ".dart_tool")]
    for n in names:
        if not n.endswith((".dart", ".kts", ".xml", ".yml", ".yaml", ".json", ".html")):
            continue
        p = os.path.join(dirpath, n)
        try:
            src = open(p, encoding="utf-8").read()
        except (UnicodeDecodeError, OSError):
            continue
        for bad in STALE:
            if bad in src:
                failures.append(f"{rel(p)}: leftover '{bad}'")

# ---- report -------------------------------------------------------------
print(f"strings: {len(entries)} keys declared, {len(used)} keys used")
if failures:
    print(f"\nFAIL ({len(failures)})")
    for f in failures:
        print("  -", f)
    sys.exit(1)
print("\nOK: imports resolve, every t() key has hi+en, no stale identifiers")
