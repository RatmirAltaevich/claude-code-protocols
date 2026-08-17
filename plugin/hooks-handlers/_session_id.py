#!/usr/bin/env python3
"""Resolve the current session id from a hook payload.

Single source of truth for session-id handling. Every hook handler and the
handoff skill go through this so the normalization rules cannot drift apart.

Reads the hook payload JSON on stdin, prints a normalized id that is always
safe to use as exactly one path segment under .protocol/runtime/.

Source order:
  1. payload["session_id"]   — the documented hook input field
  2. $CLAUDE_CODE_SESSION_ID — the variable Claude Code actually exports
  3. "unknown"

CLAUDE_SESSION_ID is deliberately never consulted: no such variable exists in
Claude Code. Reading it yields an empty id, which makes a session fail to
recognize its own runtime directory and report itself as an aborted session.
"""

import hashlib
import json
import os
import re
import sys

SAFE_SEGMENT = re.compile(r"[A-Za-z0-9._-]{1,128}")


def normalize(raw):
    """Return a path segment that cannot escape .protocol/runtime/.

    A character-class check alone is not enough: "." and ".." consist only of
    permitted characters yet still resolve to the runtime directory and its
    parent, which would point session bookkeeping at .protocol/ itself.
    """
    if not raw:
        return "unknown"
    if SAFE_SEGMENT.fullmatch(raw) and raw.strip(".") != "":
        return raw
    digest = hashlib.sha256(raw.encode("utf-8", errors="replace")).hexdigest()[:16]
    return "invalid-" + digest


def resolve(payload):
    raw = ""
    try:
        data = json.loads(payload) if payload.strip() else {}
        if isinstance(data, dict) and data.get("session_id") is not None:
            raw = str(data["session_id"])
    except Exception:
        raw = ""
    if not raw:
        raw = os.environ.get("CLAUDE_CODE_SESSION_ID", "")
    return normalize(raw)


if __name__ == "__main__":
    try:
        stdin_payload = sys.stdin.read()
    except Exception:
        stdin_payload = ""
    sys.stdout.write(resolve(stdin_payload))
