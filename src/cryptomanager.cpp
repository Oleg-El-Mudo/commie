#include "cryptomanager.h"
//библиотека для хэшей
#include <QCryptographicHash>
//Библиотека для генерации ключей
#include <sodium.h>
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
