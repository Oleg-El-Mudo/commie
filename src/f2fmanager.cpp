#include "f2fmanager.h"
#include <QUrl>
#include <QUrlQuery>
#include <QJsonDocument>
#include <QJsonObject>
//генерация пригласительной ссылки
QString F2FManager::generateInviteLink(const QString &login, const QString &publicKey, const QString &ip, int port, const QString &alias, const QString &avatar, const QString &encPublicKey)
{
    //создает json объект и вставляем в него логин, публичный ключ, айпи и порт после соотвествующих меток
    QJsonObject data;
    data.insert("login", login);
    data.insert("publicKey", publicKey);
    data.insert("ip", ip);
    data.insert("port", QString::number(port));
    data.insert("encPublicKey", encPublicKey);
    //если у пользователя есть псевдоним (может отсутствовать)
    if (!alias.isEmpty()) {
        data.insert("alias", alias);
    }
    //если у пользователя есть аватар (может отсутсвовать)
    if (!avatar.isEmpty()) {
        data.insert("avatar", avatar);
    }

    //формируется json документ по данным
    QJsonDocument doc(data);
    //упаковываем данные в json из utf8
    QString encodedData = QString::fromUtf8(doc.toJson(QJsonDocument::Compact));
    //добавляем в начало ссылки оформление
    QUrl inviteUrl("commie://");
    QUrlQuery query;
    //также оформление ссылки
    query.addQueryItem("data", QString(encodedData.toLatin1().toBase64()));
    inviteUrl.setQuery(query);
    //возвращаем готовую ссылку
    return inviteUrl.toString();
}
//парсинг пригласительных ссылок
QMap<QString, QString> F2FManager::parseInviteLink(const QString &inviteLink)
{
    //получаем ссылку
    QUrl inviteUrl(inviteLink);
    QUrlQuery query(inviteUrl.query());
    //получаем данные data из ссылки
    QString encodedData = query.queryItemValue("data");
    //получаем документ из json ссылки
    QJsonDocument doc = QJsonDocument::fromJson(QByteArray::fromBase64(encodedData.toLatin1()));
    //создаем объект из ссылки
    QJsonObject data = doc.object();
    //создаем карту с результатом создания объекта
    QMap<QString, QString> result;
    //получаем данные из ссылки в формате QMap
    //получаем из data логин и приводим к строке
    result["login"] = data["login"].toString();
    //получаем из data публичный ключ и приводим к строке
    result["publicKey"] = data["publicKey"].toString();
    //получаем из data айпишник и приводим к строке
    result["ip"] = data["ip"].toString();
    //получаем из data порт и приводим к строке
    result["port"] = data["port"].toString();
    result["encPublicKey"] = data["encPublicKey"].toString();
    //если в полученных данных есть псевдоним, получаем его и приводим к строке
    if (data.contains("alias")) {
        result["alias"] = data["alias"].toString();
    }
    //если в полученных данных есть аватар, получаем его и приводим к строке (тип данных BLOB)
    if (data.contains("avatar")) {
        result["avatar"] = data["avatar"].toString();
    }
    //возвращаем полученную карту
    return result;
}
//получаем отдельно логин
QString F2FManager::getLoginFromParsedLink(const QString &inviteLink)
{
    QMap<QString, QString> data = parseInviteLink(inviteLink);
    return data["login"];
}
//получаем отдельно публичный ключ
QString F2FManager::getPublicKeyFromParsedLink(const QString &inviteLink)
{
    QMap<QString, QString> data = parseInviteLink(inviteLink);
    return data["publicKey"];
}
//получаем отдельно айпи
QString F2FManager::getIpFromParsedLink(const QString &inviteLink)
{
    QMap<QString, QString> data = parseInviteLink(inviteLink);
    return data["ip"];
}
//получаем отдельно порт
int F2FManager::getPortFromParsedLink(const QString &inviteLink)
{
    QMap<QString, QString> data = parseInviteLink(inviteLink);
    return data["port"].toInt();
}
QString F2FManager::getAliasFromParsedLink(const QString &inviteLink)
{
    QMap<QString, QString> data = parseInviteLink(inviteLink);
    //если псевдоним есть, возвращаем его, если нет - пустую строку
    if (data.contains("alias")) {
        return data["alias"];
    }
    return "";
}

// получаем отдельно avatar
QString F2FManager::getAvatarFromParsedLink(const QString &inviteLink)
{
    QMap<QString, QString> data = parseInviteLink(inviteLink);
    //если аватар есть, возвращаем его, если нет - пустой массив
    if (data.contains("avatar")) {
        return data["avatar"];
    }
    return "";
}
QString F2FManager::getEncPublicKeyFromParsedLink(const QString &inviteLink) {
    QMap<QString, QString> data = parseInviteLink(inviteLink);
    // Возвращаем пустую строку, если ключа нет
    if (data.contains("encPublicKey")) {
        return data["encPublicKey"];
    }
    return "";
}
