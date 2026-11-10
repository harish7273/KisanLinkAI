with open('admin-web/js/data-store.js', 'r', encoding='utf-8') as f:
    text = f.read()

import re
text = re.sub(r'fetch\(\$\{base\}/health', 'fetch(`${base}/health`', text)
text = re.sub(r'fetch\(\$\{base\}/api/v1/orders\?limit=100\)', 'fetch(`${base}/api/v1/orders?limit=100`)', text)
text = re.sub(r'fetch\(\$\{base\}/api/v1/kyc/queue\)', 'fetch(`${base}/api/v1/kyc/queue`)', text)
text = re.sub(r'EventSource\(\$\{base\}/api/v1/realtime/stream\)', 'EventSource(`${base}/api/v1/realtime/stream`)', text)

with open('admin-web/js/data-store.js', 'w', encoding='utf-8') as f:
    f.write(text)

print('fix_datastore.py completed successfully.')
