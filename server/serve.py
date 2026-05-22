#!/usr/bin/env python3
import http.server
import socket
import sys

def get_lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except Exception:
        return "unavailable"
    finally:
        s.close()

class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
directory = sys.argv[2] if len(sys.argv) > 2 else "."
lan_ip = get_lan_ip()

handler = lambda *args, **kwargs: Handler(*args, directory=directory, **kwargs)
with http.server.HTTPServer(("", port), handler) as httpd:
    print(f"Serving {directory} on all interfaces")
    print(f"  Local : http://localhost:{port}/")
    print(f"  LAN   : http://{lan_ip}:{port}/")
    httpd.serve_forever()
