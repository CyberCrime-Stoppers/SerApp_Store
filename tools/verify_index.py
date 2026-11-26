#!/usr/bin/env python3
"""Diagnose Serene App Store signature failures.

Checks, in order:
  1. Derives the Ed25519 PUBLIC key from the private key PEM and prints it
     in hex — compare against the PINNED_PUBKEY_HEX constant in
     src/SignatureVerifier.cpp. If they differ, that is the root cause:
     the index was signed with a different keypair than the client trusts.
  2. Re-signs each entry of the given index.json (canonical form WITHOUT
     the "signature" field, sorted keys, compact separators) and compares
     against the signature actually stored in the file. Reports per entry
     whether the stored signature is valid for THIS key.

Usage:
    python3 tools/verify_index.py <index.json> <private_key.pem>

Example:
    python3 tools/verify_index.py \
        /run/user/1001/gvfs/sftp:host=hlws/var/www/apps/public_html/index.json \
        ~/.serene-store-keys/ccs_store_ed25519.pem
"""

import base64
import json
import sys

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

# Must match SignatureVerifier.cpp
PINNED_PUBKEY_HEX = "e514e76f1ce1f64ff3e0f07180e2b568485abf85f19b16bfa5ad60d44ab3d4a8"


def canonicalize(obj: dict) -> bytes:
    """Must match sign_manifest.py: sorted keys, compact, UTF-8, no signature."""
    obj = dict(obj)
    obj.pop("signature", None)
    return json.dumps(obj, sort_keys=True, separators=(",", ":"),
                      ensure_ascii=False).encode("utf-8")


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)

    index_path, key_path = sys.argv[1], sys.argv[2]

    with open(key_path, "rb") as f:
        key = serialization.load_pem_private_key(f.read(), password=None)
    if not isinstance(key, Ed25519PrivateKey):
        sys.exit("ERROR: key is not an Ed25519 private key")

    pub_hex = key.public_key().public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw,
    ).hex()

    print("=" * 62)
    print("Derived PUBLIC key (hex) from", key_path)
    print(" ", pub_hex)
    print("Pinned key in SignatureVerifier.cpp")
    print(" ", PINNED_PUBKEY_HEX)
    if pub_hex == PINNED_PUBKEY_HEX:
        print("MATCH — client pins the right key.")
    else:
        print("*** MISMATCH *** — this is the root cause.")
        print("Either update PINNED_PUBKEY_HEX to the derived key and")
        print("rebuild the client, or re-sign the index with the pinned")
        print("keypair. NEVER mix keys between index releases.")
    print("=" * 62)

    with open(index_path, "rb") as f:
        index = json.load(f)

    all_ok = True
    for entry in index:
        app_id = entry.get("appId", "(unknown)")
        stored_sig_b64 = entry.get("signature", "")
        try:
            stored_sig = base64.b64decode(stored_sig_b64)
            key.verify(stored_sig, canonicalize(entry))
            print(f"  OK    {app_id}: stored signature valid for THIS key")
        except Exception:
            all_ok = False
            print(f"  BAD   {app_id}: stored signature INVALID for THIS key")
            print("        → re-run: python3 tools/sign_manifest.py "
                  f"{index_path} {key_path}")
            print("        and deploy the re-signed output.")

    print("=" * 62)
    if all_ok:
        print("All entries verify with this key. If the client still rejects,")
        print("check the canonicalization (QJsonDocument compact, sorted)")
        print("or whether the client binary was rebuilt after the fix.")
    else:
        print("Action: re-sign the index with this key and redeploy.")


if __name__ == "__main__":
    main()
