#ifndef PEER2PEERMANAGER_H
#define PEER2PEERMANAGER_H
#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QNetworkInterface>
class Peer2PeerManager : public QObject
{
    Q_OBJECT
public:
    explicit Peer2PeerManager(QObject *parent = nullptr);
    ~Peer2PeerManager();
    //подключение к другим узлам сети по айпи и порту
    void connectToPeer(const QString &ip, quint16 port);
    //Q_INVOKABLE позволяет запускать код из c++ в qml
    //получение текущего айпи
    Q_INVOKABLE QString getCurrentIpAddress() const;
    //получение текущего порта
    Q_INVOKABLE quint16 getCurrentPort() const;
    //запуск сервера
    Q_INVOKABLE void startServer();
signals:
    void newConnection(QTcpSocket *socket);
    void connectionError(QAbstractSocket::SocketError socketError);
private:
    QTcpServer *m_server;
    QTcpSocket *m_socket;
    quint16 m_serverPort;
};
#endif // PEER2PEERMANAGER_H
