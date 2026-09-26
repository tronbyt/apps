#!/usr/bin/env python3
"""
Spotify Refresh Token Generator - Ultimate Edition

A robust setup tool for obtaining Spotify OAuth refresh tokens for use
with the Tronbyt/Tidbyt Spotify Now Playing app.

Features:
- Interactive CLI with clear guidance
- Automatic browser launch for authorization
- Local callback server with timeout handling
- Token validation and testing
- Optional credential file export
- Environment variable support
- Retry logic for failed requests
- Detailed error messages

Requirements:
- Python 3.6+
- No external dependencies (uses only stdlib)

Usage:
    python get_refresh_token.py [--test-only] [--output FILE]

Author: gshepperd
Version: 2.0.0
"""

import http.server
import urllib.parse
import urllib.request
import urllib.error
import webbrowser
import base64
import json
import sys
import os
import socket
import argparse
import threading
import time
from typing import Optional, Tuple, Dict, Any

# =============================================================================
# CONFIGURATION
# =============================================================================

REDIRECT_URI = "http://127.0.0.1:8888/callback"
REDIRECT_PORT = 8888
AUTH_URL = "https://accounts.spotify.com/authorize"
TOKEN_URL = "https://accounts.spotify.com/api/token"
PROFILE_URL = "https://api.spotify.com/v1/me"
NOW_PLAYING_URL = "https://api.spotify.com/v1/me/player/currently-playing"

# Scopes needed for the app
SCOPES = [
    "user-read-currently-playing",  # Get currently playing track
    "user-read-playback-state",     # Get player state (device, shuffle, etc.)
    "user-read-recently-played",    # Get recently played tracks
]

# HTTP timeouts
REQUEST_TIMEOUT = 30  # seconds
CALLBACK_TIMEOUT = 300  # 5 minutes to complete auth

# Retry configuration
MAX_RETRIES = 3
RETRY_DELAY = 2  # seconds

# =============================================================================
# COLORS AND FORMATTING
# =============================================================================

class Colors:
    """ANSI color codes for terminal output."""
    RESET = "\033[0m"
    BOLD = "\033[1m"
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    CYAN = "\033[96m"
    
    @classmethod
    def disable(cls):
        """Disable colors (for non-TTY output)."""
        cls.RESET = ""
        cls.BOLD = ""
        cls.RED = ""
        cls.GREEN = ""
        cls.YELLOW = ""
        cls.BLUE = ""
        cls.CYAN = ""

# Disable colors if not a TTY
if not sys.stdout.isatty():
    Colors.disable()

def print_header(text: str):
    """Print a formatted header."""
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'=' * 60}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}  {text}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'=' * 60}{Colors.RESET}\n")

def print_success(text: str):
    """Print success message."""
    print(f"{Colors.GREEN}✓ {text}{Colors.RESET}")

def print_error(text: str):
    """Print error message."""
    print(f"{Colors.RED}✗ {text}{Colors.RESET}")

def print_warning(text: str):
    """Print warning message."""
    print(f"{Colors.YELLOW}⚠ {text}{Colors.RESET}")

def print_info(text: str):
    """Print info message."""
    print(f"{Colors.BLUE}ℹ {text}{Colors.RESET}")

def print_step(num: int, text: str):
    """Print a numbered step."""
    print(f"{Colors.BOLD}[{num}]{Colors.RESET} {text}")

# =============================================================================
# HTTP UTILITIES
# =============================================================================

def make_request(
    url: str,
    method: str = "GET",
    headers: Optional[Dict[str, str]] = None,
    data: Optional[bytes] = None,
    timeout: int = REQUEST_TIMEOUT,
    retries: int = MAX_RETRIES,
) -> Tuple[int, Dict[str, Any], bytes]:
    """
    Make an HTTP request with retry logic.
    
    Returns: (status_code, json_data or None, raw_body)
    """
    headers = headers or {}
    last_error = None
    
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, data=data, headers=headers, method=method)
            
            with urllib.request.urlopen(req, timeout=timeout) as response:
                status = response.status
                body = response.read()
                
                try:
                    json_data = json.loads(body.decode('utf-8'))
                except (json.JSONDecodeError, UnicodeDecodeError):
                    json_data = None
                
                return status, json_data, body
                
        except urllib.error.HTTPError as e:
            status = e.code
            body = e.read()
            
            try:
                json_data = json.loads(body.decode('utf-8'))
            except (json.JSONDecodeError, UnicodeDecodeError):
                json_data = None
            
            return status, json_data, body
            
        except urllib.error.URLError as e:
            last_error = f"Network error: {e.reason}"
        except socket.timeout:
            last_error = "Request timed out"
        except Exception as e:
            last_error = str(e)
        
        if attempt < retries - 1:
            time.sleep(RETRY_DELAY * (attempt + 1))
    
    raise Exception(last_error or "Unknown error")

# =============================================================================
# CALLBACK SERVER
# =============================================================================

class AuthCallbackHandler(http.server.BaseHTTPRequestHandler):
    """HTTP handler for OAuth callback."""
    
    auth_code: Optional[str] = None
    auth_error: Optional[str] = None
    
    def do_GET(self):
        """Handle GET request (OAuth callback)."""
        parsed = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed.query)
        
        if 'code' in params:
            AuthCallbackHandler.auth_code = params['code'][0]
            self._send_success_page()
        elif 'error' in params:
            AuthCallbackHandler.auth_error = params.get('error', ['Unknown'])[0]
            error_desc = params.get('error_description', [''])[0]
            self._send_error_page(AuthCallbackHandler.auth_error, error_desc)
        else:
            self.send_response(404)
            self.end_headers()
    
    def _send_success_page(self):
        """Send success HTML page."""
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.end_headers()
        
        html = """<!DOCTYPE html>
<html>
<head>
    <title>Authorization Successful</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #191414 0%, #1DB954 100%);
            color: white;
        }
        .container {
            text-align: center;
            padding: 40px;
            background: rgba(0, 0, 0, 0.5);
            border-radius: 16px;
            backdrop-filter: blur(10px);
        }
        .success-icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        h1 {
            margin: 0 0 16px 0;
            font-size: 28px;
        }
        p {
            margin: 0;
            opacity: 0.9;
            font-size: 16px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success-icon">✓</div>
        <h1>Authorization Successful!</h1>
        <p>You can close this window and return to the terminal.</p>
    </div>
</body>
</html>"""
        self.wfile.write(html.encode('utf-8'))
    
    def _send_error_page(self, error: str, description: str):
        """Send error HTML page."""
        self.send_response(400)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.end_headers()
        
        html = f"""<!DOCTYPE html>
<html>
<head>
    <title>Authorization Failed</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #191414 0%, #e74c3c 100%);
            color: white;
        }}
        .container {{
            text-align: center;
            padding: 40px;
            background: rgba(0, 0, 0, 0.5);
            border-radius: 16px;
            backdrop-filter: blur(10px);
        }}
        .error-icon {{
            font-size: 64px;
            margin-bottom: 20px;
        }}
        h1 {{
            margin: 0 0 16px 0;
            font-size: 28px;
        }}
        .error-msg {{
            background: rgba(255, 255, 255, 0.1);
            padding: 12px 20px;
            border-radius: 8px;
            margin: 16px 0;
            font-family: monospace;
        }}
        p {{
            margin: 0;
            opacity: 0.9;
            font-size: 16px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="error-icon">✗</div>
        <h1>Authorization Failed</h1>
        <div class="error-msg">{error}</div>
        <p>{description or 'Please try again or check your Spotify app settings.'}</p>
    </div>
</body>
</html>"""
        self.wfile.write(html.encode('utf-8'))
    
    def log_message(self, format, *args):
        """Suppress default logging."""
        pass


def wait_for_callback(timeout: int = CALLBACK_TIMEOUT) -> Tuple[Optional[str], Optional[str]]:
    """
    Start local server and wait for OAuth callback.
    
    Returns: (auth_code, error)
    """
    # Reset class variables
    AuthCallbackHandler.auth_code = None
    AuthCallbackHandler.auth_error = None
    
    # Try to create server - bind to all interfaces for maximum compatibility
    # This handles cases where browser uses IPv4 vs IPv6
    server = None
    bind_addresses = [
        ('127.0.0.1', REDIRECT_PORT),  # IPv4 loopback
        ('', REDIRECT_PORT),            # All interfaces
        ('0.0.0.0', REDIRECT_PORT),     # All IPv4 interfaces
    ]
    
    for bind_addr in bind_addresses:
        try:
            server = http.server.HTTPServer(bind_addr, AuthCallbackHandler)
            print_info(f"Server listening on {bind_addr[0] or 'all interfaces'}:{REDIRECT_PORT}")
            break
        except OSError as e:
            continue
    
    if server is None:
        return None, f"Could not bind to port {REDIRECT_PORT}"
    
    server.timeout = 1  # Check for shutdown every second
    
    start_time = time.time()
    
    try:
        while True:
            # Check if we got a response
            if AuthCallbackHandler.auth_code:
                return AuthCallbackHandler.auth_code, None
            if AuthCallbackHandler.auth_error:
                return None, AuthCallbackHandler.auth_error
            
            # Check timeout
            if time.time() - start_time > timeout:
                return None, "Timeout waiting for authorization"
            
            # Handle one request
            server.handle_request()
    finally:
        server.server_close()

# =============================================================================
# SPOTIFY AUTHENTICATION
# =============================================================================

def build_auth_url(client_id: str) -> str:
    """Build the Spotify authorization URL."""
    params = {
        'client_id': client_id,
        'response_type': 'code',
        'redirect_uri': REDIRECT_URI,
        'scope': ' '.join(SCOPES),
        'show_dialog': 'true',  # Always show auth dialog
    }
    return f"{AUTH_URL}?{urllib.parse.urlencode(params)}"


def exchange_code(
    code: str,
    client_id: str,
    client_secret: str,
) -> Tuple[Optional[Dict[str, str]], Optional[str]]:
    """
    Exchange authorization code for tokens.
    
    Returns: (tokens_dict, error)
    """
    # Build Basic auth
    credentials = f"{client_id}:{client_secret}"
    encoded = base64.b64encode(credentials.encode()).decode()
    
    headers = {
        'Authorization': f'Basic {encoded}',
        'Content-Type': 'application/x-www-form-urlencoded',
    }
    
    body = urllib.parse.urlencode({
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': REDIRECT_URI,
    }).encode()
    
    try:
        status, data, _ = make_request(TOKEN_URL, method='POST', headers=headers, data=body)
        
        if status == 200 and data:
            return data, None
        elif data and 'error' in data:
            error_desc = data.get('error_description', data.get('error', 'Unknown error'))
            return None, f"Token exchange failed: {error_desc}"
        else:
            return None, f"Token exchange failed with status {status}"
    
    except Exception as e:
        return None, f"Token exchange error: {e}"


def refresh_access_token(
    refresh_token: str,
    client_id: str,
    client_secret: str,
) -> Tuple[Optional[str], Optional[str]]:
    """
    Use refresh token to get new access token.
    
    Returns: (access_token, error)
    """
    credentials = f"{client_id}:{client_secret}"
    encoded = base64.b64encode(credentials.encode()).decode()
    
    headers = {
        'Authorization': f'Basic {encoded}',
        'Content-Type': 'application/x-www-form-urlencoded',
    }
    
    body = urllib.parse.urlencode({
        'grant_type': 'refresh_token',
        'refresh_token': refresh_token,
    }).encode()
    
    try:
        status, data, _ = make_request(TOKEN_URL, method='POST', headers=headers, data=body)
        
        if status == 200 and data:
            return data.get('access_token'), None
        elif data and 'error' in data:
            return None, data.get('error_description', data.get('error'))
        else:
            return None, f"Refresh failed with status {status}"
    
    except Exception as e:
        return None, str(e)

# =============================================================================
# SPOTIFY API TESTING
# =============================================================================

def get_user_profile(access_token: str) -> Tuple[Optional[Dict], Optional[str]]:
    """Get user profile to verify token works."""
    headers = {'Authorization': f'Bearer {access_token}'}
    
    try:
        status, data, _ = make_request(PROFILE_URL, headers=headers)
        
        if status == 200:
            return data, None
        elif status == 401:
            return None, "Token invalid or expired"
        else:
            return None, f"Profile request failed: {status}"
    
    except Exception as e:
        return None, str(e)


def get_now_playing(access_token: str) -> Tuple[Optional[Dict], Optional[str]]:
    """Get currently playing track."""
    headers = {'Authorization': f'Bearer {access_token}'}
    
    try:
        status, data, _ = make_request(NOW_PLAYING_URL, headers=headers)
        
        if status == 200:
            return data, None
        elif status == 204:
            return None, None  # Nothing playing, but no error
        elif status == 401:
            return None, "Token invalid or expired"
        else:
            return None, f"Request failed: {status}"
    
    except Exception as e:
        return None, str(e)

# =============================================================================
# CREDENTIAL MANAGEMENT
# =============================================================================

def save_credentials(
    filepath: str,
    client_id: str,
    client_secret: str,
    refresh_token: str,
) -> Optional[str]:
    """
    Save credentials to a file.
    
    Returns: error message or None on success
    """
    try:
        content = f"""# Spotify Credentials for Tronbyt
# Generated by get_refresh_token.py
# Keep this file secure!

CLIENT_ID={client_id}
CLIENT_SECRET={client_secret}
REFRESH_TOKEN={refresh_token}
"""
        with open(filepath, 'w') as f:
            f.write(content)
        
        # Set restrictive permissions on Unix
        try:
            os.chmod(filepath, 0o600)
        except OSError:
            pass
        
        return None
    
    except Exception as e:
        return str(e)


def load_credentials(filepath: str) -> Tuple[Optional[str], Optional[str], Optional[str], Optional[str]]:
    """
    Load credentials from file.
    
    Returns: (client_id, client_secret, refresh_token, error)
    """
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        creds = {}
        for line in content.split('\n'):
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                creds[key.strip()] = value.strip()
        
        client_id = creds.get('CLIENT_ID')
        client_secret = creds.get('CLIENT_SECRET')
        refresh_token = creds.get('REFRESH_TOKEN')
        
        if not all([client_id, client_secret, refresh_token]):
            return None, None, None, "Missing required credentials in file"
        
        return client_id, client_secret, refresh_token, None
    
    except FileNotFoundError:
        return None, None, None, "File not found"
    except Exception as e:
        return None, None, None, str(e)

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================

def check_port_available() -> bool:
    """Check if the callback port is available."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(('127.0.0.1', REDIRECT_PORT))
            return True
    except socket.error:
        return False


def run_authorization_flow(client_id: str, client_secret: str) -> Tuple[Optional[str], Optional[str]]:
    """
    Run the full authorization flow.
    
    Returns: (refresh_token, error)
    """
    # Check port
    if not check_port_available():
        return None, f"Port {REDIRECT_PORT} is in use. Close any application using it."
    
    # Build auth URL
    auth_url = build_auth_url(client_id)
    
    print_info("Opening browser for Spotify authorization...")
    print()
    print("If the browser doesn't open, visit this URL manually:")
    print(f"{Colors.CYAN}{auth_url}{Colors.RESET}")
    print()
    
    # Open browser
    try:
        webbrowser.open(auth_url)
    except Exception:
        print_warning("Could not open browser automatically")
    
    print_info(f"Waiting for authorization (timeout: {CALLBACK_TIMEOUT}s)...")
    
    # Wait for callback
    code, error = wait_for_callback()
    
    if error:
        return None, error
    
    if not code:
        return None, "No authorization code received"
    
    print_success("Authorization code received!")
    print_info("Exchanging for tokens...")
    
    # Exchange code for tokens
    tokens, error = exchange_code(code, client_id, client_secret)
    
    if error:
        return None, error
    
    refresh_token = tokens.get('refresh_token')
    if not refresh_token:
        return None, "No refresh token in response"
    
    return refresh_token, None


def validate_and_test(
    client_id: str,
    client_secret: str,
    refresh_token: str,
) -> Tuple[bool, str]:
    """
    Validate credentials and test API access.
    
    Returns: (success, message)
    """
    # Test refresh
    print_info("Testing token refresh...")
    access_token, error = refresh_access_token(refresh_token, client_id, client_secret)
    
    if error:
        return False, f"Token refresh failed: {error}"
    
    if not access_token:
        return False, "No access token received"
    
    print_success("Token refresh works!")
    
    # Test profile
    print_info("Testing API access...")
    profile, error = get_user_profile(access_token)
    
    if error:
        return False, f"Profile fetch failed: {error}"
    
    if profile:
        display_name = profile.get('display_name', 'Unknown')
        print_success(f"Connected as: {display_name}")
    
    # Test now playing
    print_info("Testing now playing endpoint...")
    now_playing, error = get_now_playing(access_token)
    
    if error:
        print_warning(f"Now playing test: {error}")
    elif now_playing:
        item = now_playing.get('item', {})
        track = item.get('name', 'Unknown')
        artists = item.get('artists', [{}])
        artist = artists[0].get('name', 'Unknown') if artists else 'Unknown'
        print_success(f"Currently playing: {track} by {artist}")
    else:
        print_info("Now playing: Nothing playing (API working)")
    
    return True, "All tests passed!"


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Spotify Refresh Token Generator for Tronbyt/Tidbyt',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python get_refresh_token.py                    # Interactive setup
  python get_refresh_token.py --output creds.env # Save to file
  python get_refresh_token.py --test-only        # Test existing credentials
        """
    )
    parser.add_argument(
        '--output', '-o',
        metavar='FILE',
        help='Save credentials to file',
    )
    parser.add_argument(
        '--test-only', '-t',
        action='store_true',
        help='Test existing credentials from environment or file',
    )
    parser.add_argument(
        '--credentials', '-c',
        metavar='FILE',
        help='Load credentials from file',
    )
    
    args = parser.parse_args()
    
    print_header("Spotify Refresh Token Generator")
    
    # Handle test-only mode
    if args.test_only:
        print_info("Test mode - checking existing credentials...")
        
        # Try to load from file or environment
        client_id = os.environ.get('SPOTIFY_CLIENT_ID')
        client_secret = os.environ.get('SPOTIFY_CLIENT_SECRET')
        refresh_token = os.environ.get('SPOTIFY_REFRESH_TOKEN')
        
        if args.credentials:
            client_id, client_secret, refresh_token, error = load_credentials(args.credentials)
            if error:
                print_error(f"Failed to load credentials: {error}")
                sys.exit(1)
        
        if not all([client_id, client_secret, refresh_token]):
            print_error("Missing credentials. Set environment variables or use --credentials FILE")
            sys.exit(1)
        
        success, message = validate_and_test(client_id, client_secret, refresh_token)
        if success:
            print_success(message)
        else:
            print_error(message)
            sys.exit(1)
        
        sys.exit(0)
    
    # Interactive setup
    print("Before you begin, make sure you have:")
    print()
    print_step(1, "Created a Spotify Developer app at:")
    print(f"   {Colors.CYAN}https://developer.spotify.com/dashboard{Colors.RESET}")
    print()
    print_step(2, "Added this Redirect URI in app settings:")
    print(f"   {Colors.CYAN}{REDIRECT_URI}{Colors.RESET}")
    print()
    print("-" * 60)
    
    # Get client ID
    client_id = os.environ.get('SPOTIFY_CLIENT_ID')
    if client_id:
        print_info(f"Using CLIENT_ID from environment")
    else:
        client_id = input(f"\n{Colors.BOLD}Enter Spotify Client ID:{Colors.RESET} ").strip()
    
    if not client_id:
        print_error("Client ID is required")
        sys.exit(1)
    
    # Get client secret
    client_secret = os.environ.get('SPOTIFY_CLIENT_SECRET')
    if client_secret:
        print_info(f"Using CLIENT_SECRET from environment")
    else:
        client_secret = input(f"{Colors.BOLD}Enter Spotify Client Secret:{Colors.RESET} ").strip()
    
    if not client_secret:
        print_error("Client Secret is required")
        sys.exit(1)
    
    print()
    print_header("Authorization")
    
    # Run auth flow
    refresh_token, error = run_authorization_flow(client_id, client_secret)
    
    if error:
        print_error(f"Authorization failed: {error}")
        sys.exit(1)
    
    print_success("Refresh token obtained!")
    print()
    
    # Validate
    print_header("Validation")
    
    success, message = validate_and_test(client_id, client_secret, refresh_token)
    
    if not success:
        print_error(f"Validation failed: {message}")
        sys.exit(1)
    
    # Output credentials
    print_header("Your Credentials")
    
    print("Add these to your Tronbyt Spotify app configuration:")
    print()
    print(f"{Colors.BOLD}CLIENT_ID:{Colors.RESET}     {client_id}")
    print(f"{Colors.BOLD}CLIENT_SECRET:{Colors.RESET} {client_secret}")
    print(f"{Colors.BOLD}REFRESH_TOKEN:{Colors.RESET} {refresh_token}")
    print()
    
    # Save to file if requested
    if args.output:
        error = save_credentials(args.output, client_id, client_secret, refresh_token)
        if error:
            print_warning(f"Could not save to file: {error}")
        else:
            print_success(f"Credentials saved to: {args.output}")
            print_info("File permissions set to owner-only (600)")
    
    print("-" * 60)
    print()
    print_success("Setup complete!")
    print()
    print_info("The refresh token is permanent until you revoke access.")
    print_info("Store these credentials securely!")
    print()


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print()
        print_warning("Cancelled by user")
        sys.exit(130)
    except Exception as e:
        print_error(f"Unexpected error: {e}")
        sys.exit(1)
