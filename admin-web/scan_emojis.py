import os
import re

EMOJI_PATTERN = re.compile(r'[\U00010000-\U0010ffff]|[\u2600-\u26FF]|[\u2700-\u27BF]|[\u2B50-\u2B55]|[\u2300-\u23FF]|[\u20D0-\u20FF]|[\u2190-\u21FF]|[\u2900-\u297F]|[\u25A0-\u25FF]|[\u2500-\u257F]')
PROHIBITED_TOKENS = ['carto.com', 'apikey', 'vidhai', '10.88.', '192.168.']

def scan_files():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    files_to_check = [
        "index.html",
        "preview.html",
        os.path.join("js", "role-store.js"),
        os.path.join("js", "i18n.js"),
        os.path.join("js", "data-store.js"),
        os.path.join("js", "map-engine.js"),
        os.path.join("js", "kisan-map.js"),
        os.path.join("js", "icons-manifest.js"),
        os.path.join("css", "tokens.css"),
        os.path.join("css", "components.css"),
    ]

    violations = []
    
    for rel_path in files_to_check:
        full_path = os.path.join(base_dir, rel_path)
        if not os.path.exists(full_path):
            continue
        with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()
            for line_no, line in enumerate(lines, 1):
                # Emoji check
                matches = EMOJI_PATTERN.findall(line)
                if matches:
                    hex_matches = [f"U+{ord(m):04X}" for m in matches]
                    violations.append(f"[{rel_path}:{line_no}] Emoji {hex_matches}: {line.strip()[:60]}")
                # Prohibited tokens
                line_lower = line.lower()
                for tok in PROHIBITED_TOKENS:
                    if tok in line_lower:
                        violations.append(f"[{rel_path}:{line_no}] Prohibited token '{tok}': {line.strip()[:60]}")

    print("====================================================")
    print("  ZERO-EMOJI & CLEAN CODEBASE CI SCAN")
    print("====================================================")
    
    if violations:
        print(f"FAILED: Found {len(violations)} violation(s):\n")
        for item in violations:
            print(f"  {item}")
        return False
    else:
        print("PASSED: 0 violations. Clean production codebase.")
        return True

if __name__ == "__main__":
    ok = scan_files()
    exit(0 if ok else 1)
