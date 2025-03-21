#include "peer2peermanager.h"
//конструктор
Peer2PeerManager::Peer2PeerManager(QObject *parent) : QObject(parent), m_serverPort(0)
{
    //инициализация объекта tcp сервера
    m_server = new QTcpServer(this);
    //инициализация объекта tcp сокета (клиент)
    m_socket = new QTcpSocket(this);

    //метод для установления соединения по ip и порту
    connect(m_server, &QTcpServer::newConnection, this, [this]() {
        emit newConnection(m_server->nextPendingConnection());
    });

    //абстрактный метод для установления соединения со стороны сокета
    connect(m_socket, static_cast<void (QAbstractSocket::*)(QAbstractSocket::SocketError)>(&QAbstractSocket::error),
            this, &Peer2PeerManager::connectionError);
}
//деструктор
Peer2PeerManager::~Peer2PeerManager()
{
    //закрывается сервер
    m_server->close();
    //закрывается сокет
    m_socket->close();
}
//функция запуска сервера
void Peer2PeerManager::startServer()
{
    //запускается сервер на любом доступном хосте
    m_server->listen(QHostAddress::Any, 0);
}
//функция подключения к другим узлам сети
void Peer2PeerManager::connectToPeer(const QString &ip, quint16 port)
{
    //сокет подключается к хосту по ip и порту
    m_socket->connectToHost(ip, port);
}
//функция получения текущего айпи адреса
QString Peer2PeerManager::getCurrentIpAddress() const
{
    //формируется список из ip адресов
    const QList<QHostAddress> addresses = QNetworkInterface::allAddresses();
    //перебор каждого из записанных в список адресов
    for (const QHostAddress &address : addresses) {
        //если адрес - ipv4
        if (address.protocol() == QAbstractSocket::IPv4Protocol && !address.isLoopback()) {
            //возвращается адрес в формате строки
            return address.toString();
        }
    }
    //иначе возвращается пустая строка
    return "";
}
//функция получения текущего порта
quint16 Peer2PeerManager::getCurrentPort() const
{
    //возвращает текущий порт
    return m_serverPort;
}
