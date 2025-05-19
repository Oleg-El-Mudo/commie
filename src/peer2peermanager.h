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

    Q_INVOKABLE void connectToPeer(const QString &ip, quint16 port);
    Q_INVOKABLE QString getCurrentIpAddress() const;
    Q_INVOKABLE quint16 getCurrentPort() const;
    Q_INVOKABLE void startServer();
    Q_INVOKABLE bool isConnected() const;

    Q_INVOKABLE bool hasActiveConnection(const QString &ip, quint16 port) const;

signals:
    void newConnection(QTcpSocket *socket);
    void connectionError(QAbstractSocket::SocketError socketError);
    void peerConnected();
    void peerDisconnected();
    void remotePeerConnected();

private:
    QTcpServer *m_server;
    QTcpSocket *m_socket;
    quint16 m_serverPort;
    QList<QTcpSocket*> m_activeSockets;
};

#endif // PEER2PEERMANAGER_H
