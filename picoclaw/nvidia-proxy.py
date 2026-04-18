#!/usr/bin/env python3
"""
PiCore — NVIDIA NIM Prefix Proxy
Solves: PicoClaw strips vendor prefix from model names.
NVIDIA requires full path e.g. "nvidia/nemotron-3-super-120b-a12b"
PicoClaw sends only "nemotron-3-super-120b-a12b" → 404.

This proxy runs on localhost:9099, adds the prefix back, forwards to NVIDIA.
Set api_base in PicoClaw config to http://127.0.0.1:9099

Usage: python3 nvidia-proxy.py &
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.request
import urllib.error
import json
import os

NVIDIA_API_KEY = os.environ.get(
    "NVIDIA_API_KEY",
    "YOUR_NVIDIA_API_KEY_HERE"
)
NVIDIA_BASE_URL = "https://integrate.api.nvidia.com/v1"

# Models that need nvidia/ prefix
NVIDIA_MODELS = {
    "nemotron-3-super-120b-a12b",
    "nemotron-3-nano-30b-a3b",
    "nemotron-4-340b-instruct",
    "nemotron-mini-4b-instruct",
    "llama-3.1-nemotron-70b-instruct",
    "llama-3.1-nemotron-nano-8b-v1",
    "llama-3.3-nemotron-super-49b-v1",
    "mistral-nemo-minitron-8b-8k-instruct",
}

# Models that need meta/ prefix
META_MODELS = {
    "llama-3.1-8b-instruct",
    "llama-3.1-70b-instruct",
    "llama-3.2-3b-instruct",
    "llama-3.3-70b-instruct",
}


def add_vendor_prefix(model: str) -> str:
    """Add correct vendor prefix if missing."""
    if "/" in model:
        return model  # Already has prefix
    if model in NVIDIA_MODELS:
        return f"nvidia/{model}"
    if model in META_MODELS:
        return f"meta/{model}"
    # Default: try nvidia/ prefix
    return f"nvidia/{model}"


class ProxyHandler(BaseHTTPRequestHandler):

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length)

        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            self.send_error(400, "Invalid JSON")
            return

        # Fix model prefix
        original_model = data.get("model", "")
        data["model"] = add_vendor_prefix(original_model)

        if original_model != data["model"]:
            print(f"[proxy] Model: {original_model} → {data['model']}")

        # Forward to NVIDIA
        target_url = f"{NVIDIA_BASE_URL}{self.path}"
        request_body = json.dumps(data).encode("utf-8")

        req = urllib.request.Request(
            target_url,
            data=request_body,
            headers={
                "Authorization": f"Bearer {NVIDIA_API_KEY}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            method="POST",
        )

        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                response_body = resp.read()
                self.send_response(resp.status)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(response_body)

        except urllib.error.HTTPError as e:
            error_body = e.read()
            print(f"[proxy] NVIDIA error {e.code}: {error_body[:200]}")
            self.send_response(e.code)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(error_body)

        except Exception as e:
            print(f"[proxy] Unexpected error: {e}")
            self.send_error(502, str(e))

    def do_GET(self):
        """Forward GET requests (e.g. /v1/models) directly."""
        target_url = f"{NVIDIA_BASE_URL}{self.path}"
        req = urllib.request.Request(
            target_url,
            headers={"Authorization": f"Bearer {NVIDIA_API_KEY}"},
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                response_body = resp.read()
                self.send_response(resp.status)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(response_body)
        except Exception as e:
            self.send_error(502, str(e))

    def log_message(self, fmt, *args):
        """Suppress default access log noise."""
        pass


if __name__ == "__main__":
    HOST = "127.0.0.1"
    PORT = 9099
    print(f"[proxy] NVIDIA prefix proxy starting on {HOST}:{PORT}")
    print(f"[proxy] Forwarding to: {NVIDIA_BASE_URL}")
    print(f"[proxy] API key: {'*' * 20}{NVIDIA_API_KEY[-6:]}")
    server = HTTPServer((HOST, PORT), ProxyHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[proxy] Stopped.")
