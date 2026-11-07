import os
import re

EMOJI_PATTERN = re.compile(r'[\U00010000-\U0010ffff]|[\u2600-\u26FF]|[\u2700-\u27BF]|[\u2B50-\u2B55]|[\u2300-\u23FF]|[\u20D0-\u20FF]|[\u2190-\u21FF]|[\u2900-\u297F]|[\u25A0-\u25FF]|[\u2500-\u257F]')

def scan_files():
    base_dir = r"d:\Kisan AI app\admin_dashboard"
    files_to_check = [
        "index.html",
        "preview.html",
        os.path.join("js", "role-store.js"),
        os.path.join("js", "i18n.js"),
        os.path.join("js", "data-store.js"),
        os.path.join("js", "map-engine.js"),
        os.path.join("js", "icons-manifest.js"),
        os.path.join("css", "tokens.css"),
        os.path.join("css", "components.css"),
    ]

    found_emojis = []
    
    for rel_path in files_to_check:
        full_path = os.path.join(base_dir, rel_path)
        if not os.path.exists(full_path):
            continue
        with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()
            for line_no, line in enumerate(lines, 1):
                matches = EMOJI_PATTERN.findall(line)
                if matches:
                    hex_matches = [f"U+{ord(m):04X}" for m in matches]
                    found_emojis.append({
                        "file": rel_path,
                        "line": line_no,
                        "hex": hex_matches,
                        "content": line.strip().encode('ascii', 'backslashreplace').decode('ascii')
                    })

    print("====================================================")
    print("  ZERO-EMOJI ENFORCEMENT LINT SCAN")
    print("====================================================")
    
    if found_emojis:
        print(f"FAILED: Found {len(found_emojis)} line(s) containing emojis/pictographs:\n")
        for item in found_emojis:
            print(f"[{item['file']}:{item['line']}] {item['hex']}")
            print(f"  > {item['content']}\n")
        return False
    else:
        print("PASSED: 0 emojis or unicode pictographs found across the entire UI codebase!")
        return True

if __name__ == "__main__":
    success = scan_files()
    if not success:
        exit(1)
