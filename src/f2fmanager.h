#ifndef F2FMANAGER_H
#define F2FMANAGER_H
#include <QObject>
#include <QString>
#include <QMap>
class F2FManager : public QObject
{
    Q_OBJECT
public:
    //Q_INVOKABLE позволяет запускать код из c++ в qml
    //генерация пригласительныъ ссылок
    //в ссылку собираются: логин, публичный ключ, ip, порт, псевдоним, аватар
    Q_INVOKABLE QString generateInviteLink(const QString &login, const QString &publicKey, const QString &ip, int port, const QString &alias, const QString &avatar);
    //парсинг пригласительных ссылок
    QMap<QString, QString> parseInviteLink(const QString &inviteLink);
    //получение по отдельности логина, публичного ключа, айпи и порта
    Q_INVOKABLE QString getLoginFromParsedLink(const QString &inviteLink);
    Q_INVOKABLE QString getPublicKeyFromParsedLink(const QString &inviteLink);
    Q_INVOKABLE QString getIpFromParsedLink(const QString &inviteLink);
    Q_INVOKABLE int getPortFromParsedLink(const QString &inviteLink);
    Q_INVOKABLE QString getAliasFromParsedLink(const QString &inviteLink);
    Q_INVOKABLE QString getAvatarFromParsedLink(const QString &inviteLink);
};
#endif // F2FMANAGER_H
