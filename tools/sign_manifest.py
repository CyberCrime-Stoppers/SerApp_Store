#!/usr/bin/env python3
"""Offline signer for .serapp canonical manifests (Ed25519, OpenSSL-compatible).

Requires:  pip install cryptography
Usage:     ./sign_manifest.py manifest.json secret_key.pem
           ./sign_manifest.py --genkey secret_key.pem        (generate keypair)
           ./sign_manifest.py --index index.json secret_key.pem   (sign whole index)

Prints the hex public key to pin in src/SignatureVerifier.cpp and the signed
JSON (signature added as "signature" field) to stdout.

IMPORTANT: run this OFFLINE. Keep the private key on removable media or a
dedicated signing host — never on the repo/CI machine.
"""

import argparse
import base64
import json
import sys

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey


def canonicalize(obj: dict) -> bytes:
    """Deterministic form: sorted keys, compact separators, UTF-8.

    NOTE: must match what the client verifies. Qt-side the client does
    QJsonDocument(obj).toJson(Compact) — QJsonDocument sorts keys
    alphabetically, matching sort_keys=True here.
    """
    return json.dumps(obj, sort_keys=True, separators=(",", ":"),
                      ensure_ascii=False).encode("utf-8")


def load_key(pem_path: str) -> Ed25519PrivateKey:
    with open(pem_path, "rb") as f:
        key = serialization.load_pem_private_key(f.read(), password=None)
    if not isinstance(key, Ed25519PrivateKey):
        sys.exit("ERROR: key is not an Ed25519 private key")
    return key


def pubkey_hex(key: Ed25519PrivateKey) -> str:
    raw = key.public_key().public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw,
    )
    return raw.hex()


def sign_entry(obj: dict, key: Ed25519PrivateKey) -> dict:
    obj = dict(obj)
    obj.pop("signature", None)
    sig = key.sign(canonicalize(obj))
    obj["signature"] = base64.b64encode(sig).decode()
    return obj


def main() -> None:
    ap = argparse.ArgumentParser(description="Sign .serapp manifests")
    ap.add_argument("file", nargs="?", help="manifest.json or index.json")
    ap.add_argument("key", nargs="?", help="Ed25519 private key PEM")
    ap.add_argument("--genkey", metavar="OUT.pem",
                    help="generate a new Ed25519 keypair and exit")
    args = ap.parse_args()

    if args.genkey:
        key = Ed25519PrivateKey.generate()
        pem = key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        )
        with open(args.genkey, "wb") as f:
            f.write(pem)
        import os
        os.chmod(args.genkey, 0o400)
        print("Private key written:", args.genkey)
        print("Public key to pin (hex):", pubkey_hex(key))
        return

    if not args.file or not args.key:
        ap.print_help()
        sys.exit(1)

    key = load_key(args.key)

    with open(args.file, "rb") as f:
        payload = json.loads(f.read())

    if isinstance(payload, list):
        signed = [sign_entry(entry, key) for entry in payload]
    elif isinstance(payload, dict):
        signed = sign_entry(payload, key)
    else:
        sys.exit("ERROR: input must be a JSON object or array")

    print("Public key pinned in client (hex):", pubkey_hex(key))
    print()
    print(json.dumps(signed, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
