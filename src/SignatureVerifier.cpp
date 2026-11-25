#include "SignatureVerifier.hpp"
#include <QByteArray>
#include <openssl/evp.h>

// PLACEHOLDER — generate your keypair offline with:
//   openssl genpkey -algorithm ED25519 -out ccs_store_ed25519.pem
// then paste the corresponding public key hex here (tools/sign_manifest.py prints it).
const char *SignatureVerifier::PINNED_PUBKEY_HEX =
    "0000000000000000000000000000000000000000000000000000000000000000";

SignatureVerifier::SignatureVerifier(QObject *parent) : QObject(parent) {}

static QByteArray pubkeyFromHex(const char *hex)
{
    return QByteArray::fromHex(QByteArray(hex));
}

bool SignatureVerifier::verifyManifest(const QByteArray &manifest, const QString &base64Signature)
{
    const QByteArray pubRaw = pubkeyFromHex(PINNED_PUBKEY_HEX);
    const QByteArray sig = QByteArray::fromBase64(base64Signature.toLatin1());

    if (pubRaw.size() != ED25519_PUBKEY_LEN || manifest.isEmpty() || sig.size() != ED25519_SIG_LEN)
        return false;

    EVP_PKEY *pubkey = EVP_PKEY_new_raw_public_key(
        EVP_PKEY_ED25519, nullptr,
        reinterpret_cast<const unsigned char *>(pubRaw.constData()),
        static_cast<size_t>(pubRaw.size()));
    if (!pubkey)
        return false;

    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    bool ok = false;
    if (ctx) {
        ok = EVP_DigestVerifyInit(ctx, nullptr, nullptr, nullptr, pubkey) == 1
          && EVP_DigestVerify(ctx,
                              reinterpret_cast<const unsigned char *>(sig.constData()),
                              static_cast<size_t>(sig.size()),
                              reinterpret_cast<const unsigned char *>(manifest.constData()),
                              static_cast<size_t>(manifest.size())) == 1;
    }
    EVP_MD_CTX_free(ctx);
    EVP_PKEY_free(pubkey);
    return ok;
}
