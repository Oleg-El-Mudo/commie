#include "cryptomanager.h"
//библиотека для хэшей
#include <QCryptographicHash>
//Библиотека для генерации ключей
#include <sodium.h>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>
#include <QByteArray>


//метод хэширования паролей
QString CryptoManager::hashPassword(const QString &password)
{
    //переводим пароль в кодировку utf8
    QByteArray passwordBytes = password.toUtf8();
    //хэшируем пароль протоколом sha3-512
    QByteArray hashBytes = QCryptographicHash::hash(passwordBytes, QCryptographicHash::Sha3_512);
    //возвращаем захэшированный пароль
    return QString(hashBytes.toHex());
}
//метод генерации приватного ключа
QString CryptoManager::generatePrivateKey()
{
    //приватный ключ, который остаётся на устройстве
    unsigned char privateKey[crypto_sign_ed25519_SECRETKEYBYTES];
    //публичный ключ, который передаётся контактам
    unsigned char publicKey[crypto_sign_ed25519_PUBLICKEYBYTES];
    //генерация пары ключей
    crypto_sign_ed25519_keypair(privateKey, publicKey);
    return QString::fromLatin1(QByteArray(reinterpret_cast<const char*>(privateKey), crypto_sign_ed25519_SECRETKEYBYTES).toBase64());
}
//метод генерации публичного ключа
QString CryptoManager::generatePublicKey(const QString &privateKey)
{
    unsigned char publicKey[crypto_sign_ed25519_PUBLICKEYBYTES];
    unsigned char privateKeyBytes[crypto_sign_ed25519_SECRETKEYBYTES];
    memcpy(privateKeyBytes, QByteArray::fromBase64(privateKey.toLatin1()), crypto_sign_ed25519_SECRETKEYBYTES);
    crypto_sign_ed25519_sk_to_pk(publicKey, privateKeyBytes);
    return QString::fromLatin1(QByteArray(reinterpret_cast<const char*>(publicKey), crypto_sign_ed25519_PUBLICKEYBYTES).toBase64());
}

// Новые методы для X25519 и шифрования
QByteArray CryptoManager::generateX25519KeyPair() {
    unsigned char publicKey[crypto_box_PUBLICKEYBYTES];
    unsigned char privateKey[crypto_box_SECRETKEYBYTES];
    crypto_box_keypair(publicKey, privateKey);

    QJsonObject keys;
    // Преобразуем QByteArray в QString перед добавлением в JSON
    keys["private_key"] = QString(QByteArray(reinterpret_cast<char*>(privateKey),
                                           crypto_box_SECRETKEYBYTES).toBase64());
    keys["public_key"] = QString(QByteArray(reinterpret_cast<char*>(publicKey),
                                          crypto_box_PUBLICKEYBYTES).toBase64());

    return QJsonDocument(keys).toJson();
}

QByteArray CryptoManager::generateSharedSecret(const QByteArray &localPrivateKey, const QByteArray &remotePublicKey) {
    unsigned char sharedSecret[crypto_scalarmult_BYTES];
    QByteArray localKey = QByteArray::fromBase64(localPrivateKey);
    QByteArray remoteKey = QByteArray::fromBase64(remotePublicKey);

    if (crypto_scalarmult(sharedSecret,
                         reinterpret_cast<const unsigned char*>(localKey.constData()),
                         reinterpret_cast<const unsigned char*>(remoteKey.constData())) != 0) {
        qWarning() << "Failed to generate shared secret";
        return QByteArray();
    }
    return QByteArray(reinterpret_cast<char*>(sharedSecret), crypto_scalarmult_BYTES);
}

QByteArray CryptoManager::encryptMessage(const QByteArray &message, const QByteArray &sharedSecret) {
    unsigned char nonce[crypto_aead_xchacha20poly1305_ietf_NPUBBYTES];
    randombytes_buf(nonce, sizeof(nonce));

    QByteArray ciphertext(message.size() + crypto_aead_xchacha20poly1305_ietf_ABYTES, 0);
    unsigned long long ciphertextLen;

    crypto_aead_xchacha20poly1305_ietf_encrypt(
        reinterpret_cast<unsigned char*>(ciphertext.data()), &ciphertextLen,
        reinterpret_cast<const unsigned char*>(message.constData()), message.size(),
        nullptr, 0, nullptr, nonce,
        reinterpret_cast<const unsigned char*>(sharedSecret.constData())
    );

    ciphertext.prepend(reinterpret_cast<char*>(nonce), sizeof(nonce));
    return ciphertext.toBase64();
}

QByteArray CryptoManager::decryptMessage(const QByteArray &encryptedData, const QByteArray &sharedSecret) {
    QByteArray data = QByteArray::fromBase64(encryptedData);
    if (data.size() < crypto_aead_xchacha20poly1305_ietf_NPUBBYTES) {
        qWarning() << "Invalid encrypted data size";
        return QByteArray();
    }

    QByteArray decrypted(data.size() - crypto_aead_xchacha20poly1305_ietf_ABYTES, 0);
    unsigned long long decryptedLen;

    if (crypto_aead_xchacha20poly1305_ietf_decrypt(
        reinterpret_cast<unsigned char*>(decrypted.data()), &decryptedLen,
        nullptr,
        reinterpret_cast<const unsigned char*>(data.constData() + crypto_aead_xchacha20poly1305_ietf_NPUBBYTES),
        data.size() - crypto_aead_xchacha20poly1305_ietf_NPUBBYTES,
        nullptr, 0,
        reinterpret_cast<const unsigned char*>(data.constData()),
        reinterpret_cast<const unsigned char*>(sharedSecret.constData())
    ) != 0) {
        qWarning() << "Decryption failed";
        return QByteArray();
    }

    return decrypted.left(decryptedLen);
}


QByteArray CryptoManager::signMessage(const QByteArray &message, const QString &privateKeyStr)
{
    QByteArray privateKey = QByteArray::fromBase64(privateKeyStr.toUtf8());

    if (privateKey.size() != crypto_sign_ed25519_SECRETKEYBYTES) {
        qWarning() << "Invalid private key size";
        return QByteArray();
    }

    QByteArray signature(crypto_sign_ed25519_BYTES, 0);

    unsigned long long outLen;
    if (crypto_sign_ed25519(
            reinterpret_cast<unsigned char*>(signature.data()),
            &outLen,
            reinterpret_cast<const unsigned char*>(message.constData()),
            message.size(),
            reinterpret_cast<const unsigned char*>(privateKey.constData())) != 0) {
        qWarning() << "Failed to sign message";
        return QByteArray();
    }

    return signature.toBase64();
}

bool CryptoManager::verifyMessage(const QByteArray &message, const QByteArray &signatureBase64, const QString &publicKeyStr)
{
    QByteArray publicKey = QByteArray::fromBase64(publicKeyStr.toUtf8());
    QByteArray signature = QByteArray::fromBase64(signatureBase64);

    if (publicKey.size() != crypto_sign_ed25519_PUBLICKEYBYTES) {
        qWarning() << "Invalid public key size";
        return false;
    }

    if (signature.size() != crypto_sign_ed25519_BYTES) {
        qWarning() << "Invalid signature size";
        return false;
    }

    int result = crypto_sign_ed25519_open(
        reinterpret_cast<unsigned char*>(const_cast<char*>(reinterpret_cast<const char*>(message.constData()))),
        nullptr,
        reinterpret_cast<const unsigned char*>(signature.constData()),
        signature.size(),
        reinterpret_cast<const unsigned char*>(publicKey.constData()));

    return result == 0;
}
