#include "peer2peermanager.h"
//конструктор
Peer2PeerManager::Peer2PeerManager(QObject *parent) : QObject(parent), m_serverPort(0)
{
    //инициализация объекта tcp сервера
    m_server = new QTcpServer(this);
    //инициализация объекта tcp сокета (клиент)
    m_socket = new QTcpSocket(this);

    //абстрактный метод для установления соединения со стороны сокета
    connect(m_socket, static_cast<void (QAbstractSocket::*)(QAbstractSocket::SocketError)>(&QAbstractSocket::error),
            this, &Peer2PeerManager::connectionError);

    connect(m_socket, &QTcpSocket::connected, this, [this]() {
        emit peerConnected();
        m_socket->write("CONNECTION_ESTABLISHED\n");
    });

    connect(m_socket, &QTcpSocket::disconnected, this, [this]() {
        emit peerDisconnected();
    });


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
    m_server->listen(QHostAddress::Any, 0);
    m_serverPort = m_server->serverPort();

    connect(m_server, &QTcpServer::newConnection, this, [this]() {
        QTcpSocket *socket = m_server->nextPendingConnection();

        // Сохраняем сокет, чтобы не упал
        m_activeSockets.append(socket);

        connect(socket, &QTcpSocket::readyRead, this, [this, socket]() {
            if (!socket || socket->state() != QAbstractSocket::ConnectedState) {
                return;
            }

            QByteArray data = socket->readAll();
            qDebug() << "SERVER: Received data:" << data;

            if (data.contains("CONNECTION_ESTABLISHED")) {
                emit remotePeerConnected();
            }
        });

        connect(socket, &QTcpSocket::disconnected, this, [this, socket]() {
            m_activeSockets.removeOne(socket);
            socket->deleteLater();
        });

        // Убедись, что этот сигнал действительно нужен
        // emit newConnection(socket);
    });
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

bool Peer2PeerManager::isConnected() const {
    return (m_socket->state() == QAbstractSocket::ConnectedState);
}

bool Peer2PeerManager::hasActiveConnection(const QString &ip, quint16 port) const {
    // Проверяем исходящее соединение
    if (m_socket->state() == QAbstractSocket::ConnectedState &&
        m_socket->peerAddress().toString() == ip &&
        m_socket->peerPort() == port) {
        return true;
    }

    // Проверяем входящее соединение
    for (const auto &socket : m_server->findChildren<QTcpSocket *>()) {
        if (socket && socket->state() == QAbstractSocket::ConnectedState &&
            socket->peerAddress().toString() == ip &&
            socket->peerPort() == port) {
            return true;
        }
    }

    return false;
}
