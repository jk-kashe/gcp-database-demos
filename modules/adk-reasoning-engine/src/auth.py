import sys
import time
import google.auth
import google.auth.transport.requests
import google.oauth2.id_token

# --- Token Caching ---
_cached_token = None
_token_expiry_time = 0
# Refresh token 5 minutes before it expires (tokens last 1 hour)
_token_refresh_buffer_seconds = 300

def get_id_token(audience: str) -> str:
    """
    Get a cached ID token, refreshing it if it's close to expiring.
    """
    global _cached_token, _token_expiry_time

    current_time = time.time()

    # If the token is missing or is about to expire, fetch a new one.
    if not _cached_token or current_time > _token_expiry_time - _token_refresh_buffer_seconds:
        print("Fetching new ID token for audience...", file=sys.stderr)
        try:
            creds, project = google.auth.default()
            if hasattr(creds, 'service_account_email'):
                print(f"Running as service account: {creds.service_account_email}", file=sys.stderr)
        except Exception as e:
            print(f"Error getting default credentials: {e}", file=sys.stderr)

        auth_req = google.auth.transport.requests.Request()
        new_token = google.oauth2.id_token.fetch_id_token(auth_req, audience)
        
        _cached_token = new_token
        _token_expiry_time = current_time + 3600  # 1 hour in seconds
        print(f"ID token refreshed. New expiry in approx 1 hour.", file=sys.stderr)
    
    return _cached_token
