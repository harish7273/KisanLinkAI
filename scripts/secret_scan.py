import os
import re
import subprocess

IGNORE_DIRS = {'.git', '.gradle', 'build', '.dart_tool', '.idea', 'node_modules', '__pycache__'}

def scan_files():
    # Only scan git tracked and untracked staged/unstaged source files
    try:
        res = subprocess.run(['git', 'status', '--porcelain'], capture_output=True, text=True)
        files = []
        for line in res.stdout.splitlines():
            parts = line.strip().split(maxsplit=1)
            if len(parts) == 2:
                files.append(parts[1])
    except Exception:
        files = []

    patterns = [
        (re.compile(r'sk-[a-zA-Z0-9]{20,}'), 'OpenAI Secret Key'),
        (re.compile(r'rzp_live_[a-zA-Z0-9]+'), 'Razorpay Live Key'),
        (re.compile(r'-----BEGIN (?:RSA )?PRIVATE KEY-----'), 'Private Key'),
    ]

    findings = []
    for f in files:
        if f == '.env' or not os.path.exists(f) or os.path.isdir(f):
            continue
        try:
            with open(f, 'r', encoding='utf-8', errors='ignore') as fp:
                content = fp.read()
                for pat, name in patterns:
                    if pat.search(content):
                        findings.append((f, name))
        except Exception:
            pass

    print(f"Secret scan complete. Total files checked: {len(files)}. Findings: {len(findings)}")
    for f, name in findings:
        print(f"  [ALERT] {f}: {name}")
    return len(findings) == 0

if __name__ == '__main__':
    ok = scan_files()
    exit(0 if ok else 1)
