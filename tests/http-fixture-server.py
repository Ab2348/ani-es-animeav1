#!/usr/bin/env python3
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

fixtures = Path(__file__).with_name("fixtures")
port_file = Path(sys.argv[1])
range_log = Path(sys.argv[2])


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_args):
        pass

    def send_body(self, status, content_type, body, honor_range=True):
        request_range = self.headers.get("Range", "")
        total = len(body)
        with range_log.open("a", encoding="utf-8") as log:
            log.write(f"{self.path}\t{request_range}\n")
        if status == 200 and honor_range and request_range == "bytes=0-1023":
            body = body[:1024]
            status = 206
            self.send_response(status)
            self.send_header("Content-Range", f"bytes 0-{max(0, len(body)-1)}/{total}")
        else:
            self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def do_GET(self):
        if self.path == "/valid.m3u8":
            self.send_body(200, "application/vnd.apple.mpegurl", (fixtures / "zilla-valid.m3u8").read_bytes())
        elif self.path == "/missing.m3u8":
            self.send_body(404, "text/plain", b"Not Found")
        elif self.path == "/invalid.m3u8":
            self.send_body(200, "text/html", (fixtures / "zilla-invalid.html").read_bytes())
        elif self.path == "/good.mp4":
            self.send_body(200, "application/octet-stream", b"\x00\x00\x00\x20ftypisom" + b"0" * 2048)
        elif self.path == "/large.mp4":
            self.send_body(200, "video/mp4", b"\x00\x00\x00\x20ftypisom" + b"0" * 524288, honor_range=False)
        else:
            self.send_body(404, "text/plain", b"Not Found")


server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
port_file.write_text(str(server.server_port), encoding="utf-8")
server.serve_forever()
