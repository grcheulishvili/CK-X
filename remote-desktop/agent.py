import json
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer


def _set_clipboard(text):
    """Write text to both X selections.

    Content is passed on stdin rather than interpolated into a shell command, so
    quotes, newlines and shell metacharacters in a snippet cannot break the call
    or be executed. 'clipboard' serves Ctrl+V / Ctrl+Shift+V; 'primary' serves
    middle-click paste.
    """
    data = text.encode("utf-8")
    for selection in ("clipboard", "primary"):
        try:
            p = subprocess.Popen(
                ["xclip", "-selection", selection],
                stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                env={"DISPLAY": ":1", "PATH": "/usr/bin:/bin:/usr/local/bin"},
            )
            p.communicate(input=data, timeout=5)
        except Exception:
            # A failure on one selection should not block the other.
            pass


class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/restart-vnc-session':
            try:
                subprocess.Popen("vncserver -kill :1 && vncserver :1", shell=True,
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                self.respond(200, {})
            except Exception as e:
                self.respond(500, {"error": str(e)})
        else:
            self.respond(404, {"error": "not found"})

    def do_POST(self):
        if self.path == '/clipboard-paste':
            try:
                length = int(self.headers.get('Content-Length') or 0)
            except ValueError:
                self.respond(400, {"error": "Invalid Content-Length"})
                return
            # Bound the read so a huge body cannot exhaust memory.
            if length <= 0 or length > 1_000_000:
                self.respond(400, {"error": "Body must be between 1 byte and 1 MB"})
                return

            post_data = self.rfile.read(length).decode("utf-8", "replace")
            try:
                content = json.loads(post_data).get("content")
                if not content:
                    self.respond(400, {"error": "Missing clipboard content"})
                    return
                _set_clipboard(content)
                self.respond(200, {})
            except Exception as e:
                self.respond(500, {"error": str(e)})
        else:
            self.respond(404, {"error": "not found"})

    def log_message(self, fmt, *args):
        pass  # keep container logs quiet

    def respond(self, status_code, response_data):
        body = json.dumps(response_data).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == '__main__':
    HTTPServer(('0.0.0.0', 5000), RequestHandler).serve_forever()
