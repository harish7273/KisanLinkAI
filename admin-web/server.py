import http.server
import os
import sys

PORT = 8080
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

class NoCacheHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

if __name__ == '__main__':
    try:
        httpd = http.server.ThreadingHTTPServer(("", PORT), NoCacheHTTPRequestHandler)
        print(f"KisanAI Dashboard Threaded Server running on http://localhost:{PORT} with strict No-Cache headers...")
        sys.stdout.flush()
        httpd.serve_forever()
    except Exception as e:
        print(f"Server error: {e}")
        sys.exit(1)
