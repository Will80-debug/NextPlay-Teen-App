#!/usr/bin/env python3
import http.server
import socketserver
import os

PORT = 5000
DIRECTORY = "dist"

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()

    def do_GET(self):
        # Serve index.html for all routes (SPA support)
        if self.path and not self.path.startswith('/assets') and not os.path.exists(DIRECTORY + self.path):
            self.path = '/index.html'
        return super().do_GET()

os.chdir('/home/user/webapp/nextplay-app')

with socketserver.TCPServer(("0.0.0.0", PORT), MyHTTPRequestHandler) as httpd:
    print(f"Server running at http://0.0.0.0:{PORT}/")
    print(f"Serving files from: {os.path.abspath(DIRECTORY)}")
    httpd.serve_forever()
