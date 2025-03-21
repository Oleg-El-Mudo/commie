#ifndef CRYPTOMANAGER_H
#define CRYPTOMANAGER_H
#include <QObject>
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
};
#endif // CRYPTOMANAGER_H

