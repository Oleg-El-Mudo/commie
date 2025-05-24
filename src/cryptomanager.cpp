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
    qDebug() << "[CryptoManager] generateSharedSecret() вызван";
    qDebug() << "Local private key (Base64):" << localPrivateKey;
    qDebug() << "Remote public key (Base64):" << remotePublicKey;

    // Декодируем из Base64
    QByteArray decodedLocalPriv = QByteArray::fromBase64(localPrivateKey);
    QByteArray decodedRemotePub = QByteArray::fromBase64(remotePublicKey);

    qDebug() << "Decoded local private key size:" << decodedLocalPriv.size();
    qDebug() << "Decoded remote public key size:" << decodedRemotePub.size();

    if (decodedLocalPriv.size() != crypto_scalarmult_BYTES ||
        decodedRemotePub.size() != crypto_scalarmult_BYTES) {
        qWarning() << "[CryptoManager] Неверный размер ключей для ECDH";
        return QByteArray();
    }

    unsigned char sharedSecret[crypto_scalarmult_BYTES];

    int result = crypto_scalarmult(
        sharedSecret,
        reinterpret_cast<const unsigned char*>(decodedLocalPriv.constData()),
        reinterpret_cast<const unsigned char*>(decodedRemotePub.constData())
    );

    if (result != 0) {
        qWarning() << "[CryptoManager] Ошибка при генерации общего секрета";
        return QByteArray();
    }

    QByteArray sharedSecretBytes(reinterpret_cast<char*>(sharedSecret), crypto_scalarmult_BYTES);
    qDebug() << "Сгенерированный общий секрет (hex):" << sharedSecretBytes.toHex();

    return sharedSecretBytes;
}
QByteArray CryptoManager::encryptMessage(const QByteArray &message, const QByteArray &sharedSecret) {
    // 🔍 Логируем входные данные
    qDebug() << "Encrypt: Plaintext message (UTF-8):" << message;
    qDebug() << "Encrypt: Message size:" << message.size();
    qDebug() << "Encrypt: Shared secret (hex):" << sharedSecret.toHex();

    // Генерируем случайный nonce
    unsigned char nonce[crypto_aead_xchacha20poly1305_ietf_NPUBBYTES];
    randombytes_buf(nonce, sizeof(nonce));

    // 🔍 Логируем nonce (только первые 8 байт для удобства)
    qDebug() << "Encrypt: Generated nonce (first 8 bytes):"
             << QByteArray(reinterpret_cast<char*>(nonce), 8).toHex();

    // Подготавливаем буфер для зашифрованного сообщения
    QByteArray ciphertext(message.size() + crypto_aead_xchacha20poly1305_ietf_ABYTES, 0);
    unsigned long long ciphertextLen;

    // Выполняем шифрование
    crypto_aead_xchacha20poly1305_ietf_encrypt(
        reinterpret_cast<unsigned char*>(ciphertext.data()), &ciphertextLen,
        reinterpret_cast<const unsigned char*>(message.constData()), message.size(),
        nullptr, 0, nullptr, nonce,
        reinterpret_cast<const unsigned char*>(sharedSecret.constData())
    );

    // Обрезаем до реального размера зашифрованного текста
    ciphertext.resize(ciphertextLen);

    // Добавляем nonce в начало зашифрованного сообщения
    ciphertext.prepend(reinterpret_cast<char*>(nonce), crypto_aead_xchacha20poly1305_ietf_NPUBBYTES);

    // 🔍 Логируем результат шифрования
    qDebug() << "Encrypt: Ciphertext length (with nonce):" << ciphertext.size();
    qDebug() << "Encrypt: Ciphertext (Base64):" << ciphertext.toBase64();

    return ciphertext.toBase64();
}
QByteArray CryptoManager::decryptMessage(const QByteArray &encryptedData, const QByteArray &sharedSecret) {
    QByteArray data = QByteArray::fromBase64(encryptedData);
    if (data.size() < crypto_aead_xchacha20poly1305_ietf_NPUBBYTES) {
        qWarning() << "Invalid encrypted data size";
        return QByteArray();
    }

    // 🔍 Логируем размер данных и sharedSecret
    qDebug() << "Decrypt: Encrypted data size (base64 decoded):" << data.size();
    qDebug() << "Decrypt: Shared secret (hex):" << sharedSecret.toHex();

    // 🔍 Выводим первые байты nonce для проверки
    qDebug() << "Decrypt: Nonce (first 8 bytes):" << data.left(crypto_aead_xchacha20poly1305_ietf_NPUBBYTES).toHex();

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

    qDebug() << "Decrypt: Decrypted message length:" << decryptedLen;
    qDebug() << "Decrypt: Decrypted message (UTF-8):" << decrypted.left(decryptedLen);

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

QByteArray CryptoManager::decryptWithSharedSecret(const QByteArray &encryptedData, const QByteArray &sharedSecret) {
    QByteArray data = QByteArray::fromBase64(encryptedData);
    if (data.size() < crypto_aead_xchacha20poly1305_ietf_NPUBBYTES) {
        qWarning() << "Invalid encrypted data size";
        return QByteArray();
    }

    QByteArray decrypted(data.size() - crypto_aead_xchacha20poly1305_ietf_ABYTES, 0);
    unsigned long long decryptedLen;

    int result = crypto_aead_xchacha20poly1305_ietf_decrypt(
        reinterpret_cast<unsigned char*>(decrypted.data()), &decryptedLen,
        nullptr,
        reinterpret_cast<const unsigned char*>(data.constData() + crypto_aead_xchacha20poly1305_ietf_NPUBBYTES),
        data.size() - crypto_aead_xchacha20poly1305_ietf_NPUBBYTES,
        nullptr, 0,
        reinterpret_cast<const unsigned char*>(data.constData()),
        reinterpret_cast<const unsigned char*>(sharedSecret.constData())
    );

    if (result != 0) {
        qWarning() << "Decryption failed";
        return QByteArray();
    }

    return decrypted.left(decryptedLen);
}

QByteArray CryptoManager::encryptWithSharedSecret(const QByteArray &message, const QByteArray &sharedSecret) {
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

    ciphertext.resize(ciphertextLen);
    ciphertext.prepend(reinterpret_cast<char*>(nonce), sizeof(nonce));
    return ciphertext.toBase64();
}
