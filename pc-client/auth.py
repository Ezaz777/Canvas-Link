"""
Authentication module for WallpaperSync PC client.
Opens browser for Pinterest OAuth via the Cloudflare backend,
captures the JWT token via a local HTTP server.
"""

import json
import logging
import os
import threading
import webbrowser
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

from config import API_BASE_URL, TOKEN_FILE, LOCAL_AUTH_PORT, LOCAL_AUTH_HOST

logger = logging.getLogger("WallpaperSync")

# Global variable to store the received token
_received_token = None


class CallbackHandler(BaseHTTPRequestHandler):
    """HTTP handler that captures the JWT token from the OAuth callback redirect."""

    def do_GET(self):
        global _received_token
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)

        if parsed.path == "/callback" and "token" in params:
            _received_token = params["token"][0]
            # Send a success response
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            response = """<!DOCTYPE html>
<html>
<head><title>WallpaperSync</title>
<style>
    body {
        font-family: 'Segoe UI', sans-serif;
        background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
        color: #fff; display: flex; align-items: center;
        justify-content: center; min-height: 100vh; margin: 0;
    }
    .card {
        background: rgba(255,255,255,0.08); backdrop-filter: blur(20px);
        border-radius: 20px; padding: 40px; text-align: center;
        border: 1px solid rgba(255,255,255,0.15);
        box-shadow: 0 25px 50px rgba(0,0,0,0.4);
    }
</style></head>
<body><div class="card">
    <h1>✅ Authenticated!</h1>
    <p>You can close this window and return to the app.</p>
</div></body></html>"""
            self.wfile.write(response.encode())
            logger.info("Token received successfully via local callback.")
        else:
            self.send_response(404)
            self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Private-Network", "true")
        self.end_headers()

    def log_message(self, format, *args):
        """Suppress default HTTP server logs."""
        pass


def login():
    """
    Initiate the OAuth flow:
    1. Start a local HTTP server to capture the callback
    2. Open the browser to the Pinterest OAuth URL
    3. Wait for the token to arrive
    4. Save it locally
    """
    global _received_token
    _received_token = None

    # Start local callback server
    server = HTTPServer((LOCAL_AUTH_HOST, LOCAL_AUTH_PORT), CallbackHandler)
    server.timeout = 1  # 1 second timeout for handle_request

    def serve_until_token():
        import time
        start_time = time.time()
        while _received_token is None and (time.time() - start_time) < 120:
            server.handle_request()

    server_thread = threading.Thread(target=serve_until_token, daemon=True)
    server_thread.start()

    # Open browser to start OAuth flow
    auth_url = f"{API_BASE_URL}/auth/pinterest"
    logger.info(f"Opening browser for Pinterest login: {auth_url}")
    webbrowser.open(auth_url)

    # Wait for the callback
    server_thread.join(timeout=125)
    server.server_close()

    if _received_token:
        save_token(_received_token)
        logger.info("Login successful! Token saved.")
        return _received_token
    else:
        logger.error("Login timed out.")
        return None


def save_token(token: str):
    """Save the JWT token to the local token file."""
    data = {"token": token}
    with open(TOKEN_FILE, "w") as f:
        json.dump(data, f)
    logger.info(f"Token saved to {TOKEN_FILE}")


def load_token() -> str | None:
    """Load the JWT token from the local token file."""
    if not os.path.exists(TOKEN_FILE):
        return None
    try:
        with open(TOKEN_FILE, "r") as f:
            data = json.load(f)
        return data.get("token")
    except (json.JSONDecodeError, IOError):
        return None


def clear_token():
    """Delete the stored token (logout)."""
    if os.path.exists(TOKEN_FILE):
        os.remove(TOKEN_FILE)
        logger.info("Token cleared.")


def is_logged_in() -> bool:
    """Check if a token is stored."""
    return load_token() is not None
