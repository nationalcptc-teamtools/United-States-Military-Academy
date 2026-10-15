"""Small reusable identity/time/hash helpers; no tool-output envelope."""
from datetime import datetime, timezone
from hashlib import sha256
from uuid import uuid4
def new_id(): return uuid4().hex
def timestamp(): return datetime.now(timezone.utc).isoformat()
def checksum(raw): return sha256(raw).hexdigest()
