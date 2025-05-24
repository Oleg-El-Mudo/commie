#ifndef CRYPTOMANAGER_H
#define CRYPTOMANAGER_H
#include <QObject>
#include <QString>
#include <QString>
class CryptoManager : public QObject
{
    Q_OBJECT
public:
    //Q_INVOKABLE позволяет запускать код из c++ в qml
    //1. хэширование паролей
    Q_INVOKABLE QString hashPassword(const QString &password);
    //2. методы, необходимые для добавления контактов и переписки
    //генерирование приватного ключа
    Q_INVOKABLE QString generatePrivateKey();
    //генерирование публичного ключа на основе приватного
    Q_INVOKABLE QString generatePublicKey(const QString &privateKey);
    // Новые методы для ECDH и шифрования
    Q_INVOKABLE QByteArray generateX25519KeyPair();  // Возвращает JSON с ключами
    Q_INVOKABLE QByteArray generateSharedSecret(const QByteArray &localPrivateKey, const QByteArray &remotePublicKey);
    Q_INVOKABLE QByteArray encryptMessage(const QByteArray &message, const QByteArray &sharedSecret);
    Q_INVOKABLE QByteArray decryptMessage(const QByteArray &encryptedData, const QByteArray &sharedSecret);

    Q_INVOKABLE QByteArray signMessage(const QByteArray &message, const QString &privateKey);
    Q_INVOKABLE bool verifyMessage(const QByteArray &message, const QByteArray &signature, const QString &publicKey);
    Q_INVOKABLE QByteArray encryptWithSharedSecret(const QByteArray &message, const QByteArray &sharedSecret);
    Q_INVOKABLE QByteArray decryptWithSharedSecret(const QByteArray &encryptedData, const QByteArray &sharedSecret);

private:
    static const int X25519_KEY_LENGTH = 32;  // Длина ключа X25519 в байтах
    static const int NONCE_LENGTH = 24;       // XChaCha20-Poly1305 nonce
    static const int TAG_LENGTH = 16;         // Poly1305 MAC
};


#endif // CRYPTOMANAGER_H

