import os
import re

matches = []
for root, dirs, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8', errors='ignore') as fp:
                content = fp.read()
                urls = re.findall(r'https?://[^\s\'"\)]+', content)
                ips = re.findall(r'\b(?:10\.\d+|192\.168\.\d+|127\.0\.0\.1|localhost)\b[^\s\'"\)]*', content)
                if urls or ips:
                    matches.append((path, urls, ips))

for path, urls, ips in matches:
    print(f'File: {path}')
    if urls:
        print(f'  URLs: {urls[:5]}')
    if ips:
        print(f'  IPs: {ips[:5]}')
