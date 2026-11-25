#pragma once
#include <QObject>
#include <QString>

/*
 * Ed25519 detached-signature verifier for .serapp manifests.
 *
 * Uses OpenSSL EVP (Qt already links OpenSSL on KDE Neon — no extra dep).
 * The CCS/SereneForge public key is PINNED in the binary. Never load it
 * from disk or network: that would let an attacker swap the trust anchor.
 */
class SignatureVerifier : public QObject
{
    Q_OBJECT
public:
    static constexpr int ED25519_SIG_LEN = 64;   // Ed25519 signatures are always 64 bytes
    static constexpr int ED25519_PUBKEY_LEN = 32;

    // Trust anchor for SerApp Store (CCS / SereneForge).
    // Hex-encoded Ed25519 PUBLIC key. The PRIVATE key lives offline only —
    // never commit it. Replace the placeholder with `openssl genpkey -algorithm ED25519`
    // output's public counterpart (tools/sign_manifest.py prints the hex to pin).
    static const char *PINNED_PUBKEY_HEX;

    explicit SignatureVerifier(QObject *parent = nullptr);

    // Verifies a base64 Ed25519 detached signature over `manifest` bytes.
    // Returns true only if the signature is cryptographically valid.
    bool verifyManifest(const QByteArray &manifest, const QString &base64Signature);
};
