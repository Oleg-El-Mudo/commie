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

QByteArray CryptoManager::decryptWithSharedSecret(const QByteArray &encryptedData, const QByteArray &sharedSecret) {
    qDebug() << "DecryptWithSharedSecret: Encrypted data size (base64 decoded):" << encryptedData.size();
    qDebug() << "DecryptWithSharedSecret: Shared secret (hex):" << sharedSecret.toHex();

    QByteArray data = QByteArray::fromBase64(encryptedData);

    if (data.size() < crypto_aead_xchacha20poly1305_ietf_NPUBBYTES) {
        qWarning() << "Invalid encrypted data size";
        return QByteArray();
    }

    int cipherTextSize = data.size() - crypto_aead_xchacha20poly1305_ietf_NPUBBYTES;

    // Извлекаем nonce и шифртекст
    QByteArray nonce = data.left(crypto_aead_xchacha20poly1305_ietf_NPUBBYTES);
    const unsigned char *cipherText = reinterpret_cast<const unsigned char*>(data.constData()) +
                                      crypto_aead_xchacha20poly1305_ietf_NPUBBYTES;

    // Буфер под расшифрованный текст
    QByteArray decrypted;
    decrypted.resize(cipherTextSize); // Не инициализируем содержимое

    unsigned long long decryptedLen;

    int result = crypto_aead_xchacha20poly1305_ietf_decrypt(
        reinterpret_cast<unsigned char*>(decrypted.data()), &decryptedLen,
        nullptr,
        cipherText,
        cipherTextSize,
        nullptr, 0,
        reinterpret_cast<const unsigned char*>(nonce.constData()),
        reinterpret_cast<const unsigned char*>(sharedSecret.constData())
    );

    if (result != 0) {
        qWarning() << "Decryption failed with error code:" << result;
        return QByteArray();
    }

    decrypted.resize(static_cast<int>(decryptedLen)); // Обрезаем до реального размера
    qDebug() << "DecryptWithSharedSecret: Decrypted message length:" << decryptedLen;
    return decrypted;
}

QByteArray CryptoManager::encryptWithSharedSecret(const QByteArray &message, const QByteArray &sharedSecret) {
    qDebug() << "EncryptWithSharedSecret: Plaintext message (UTF-8):" << message;
    qDebug() << "EncryptWithSharedSecret: Message size:" << message.size();
    qDebug() << "EncryptWithSharedSecret: Shared secret (hex):" << sharedSecret.toHex();

    // Генерируем случайный nonce
    unsigned char nonce[crypto_aead_xchacha20poly1305_ietf_NPUBBYTES];
    randombytes_buf(nonce, sizeof(nonce));

    // Подготавливаем буфер под зашифрованное сообщение
    QByteArray ciphertext;
    ciphertext.resize(message.size() + crypto_aead_xchacha20poly1305_ietf_ABYTES); // Выделяем нужный объём

    unsigned long long ciphertextLen;

    // Шифруем
    crypto_aead_xchacha20poly1305_ietf_encrypt(
        reinterpret_cast<unsigned char*>(ciphertext.data()), &ciphertextLen,
        reinterpret_cast<const unsigned char*>(message.constData()), message.size(),
        nullptr, 0, nullptr, nonce,
        reinterpret_cast<const unsigned char*>(sharedSecret.constData())
    );

    // Обрезаем до реального размера
    ciphertext.resize(static_cast<int>(ciphertextLen));

    // Добавляем nonce в начало
    ciphertext.prepend(reinterpret_cast<char*>(nonce), crypto_aead_xchacha20poly1305_ietf_NPUBBYTES);

    qDebug() << "EncryptWithSharedSecret: Ciphertext length (with nonce):" << ciphertext.size();
    return ciphertext.toBase64();
}
