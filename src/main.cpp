#include <auroraapp.h>
#include <QtQuick>
//подключение мэнеджера, отвечающего за криптографию
#include "cryptomanager.h"
//подключение мэнеджера, отвечающего за систему контактов
#include "f2fmanager.h"
//подключение мэнеджера, отвечающего за работу с одноранговой сетью
#include "peer2peermanager.h"

int main(int argc, char *argv[])
{
    //регистрация типов для использования c++ кода в qml
    //модуль криптографии
    qmlRegisterType<CryptoManager>("Crypto.Module", 1,0, "Crypto");
    //модуль добавления контактов
    qmlRegisterType<F2FManager>("Friends.Module", 1,0, "Friends");
    //модуль однорангового соединения
    qmlRegisterType<Peer2PeerManager>("Peers.Module", 1,0, "Peers");

    //инициализация приложения
    QScopedPointer<QGuiApplication> application(Aurora::Application::application(argc, argv));
    //установка организации
    application->setOrganizationName(QStringLiteral("psuti.fishman"));
    //установка имени приложения
    application->setApplicationName(QStringLiteral("messenger"));

    //создается представление приложения
    QScopedPointer<QQuickView> view(Aurora::Application::createView());
    //указывается точка входа qml
    view->setSource(Aurora::Application::pathTo(QStringLiteral("qml/messenger.qml")));
    //представление включается в отображение
    view->show();

    //возвращается запуск приложения
    return application->exec();
}
