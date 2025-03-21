import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Dialog {
    id: loadingPage
    allowedOrientations: Orientation.All

    // Параметры, переданные с предыдущей страницы
    property string nick
    property string password

    // Объект для работы с БД SQLite
    Dao {
        id: dao
    }

    // Верхнее меню приложения
    DialogHeader {
        id: header
        title: qsTr("Wait please")
        acceptText: qsTr("")
        cancelText: qsTr("")
        background: true
    }

    // Индикатор загрузки
    BusyIndicator {
        anchors.centerIn: parent
        running: true
        size: BusyIndicatorSize.Large
    }

    Timer {
        id: operationTimer
        interval: 100 // Задержка перед началом выполнения операций
        running: false
        repeat: false
        onTriggered: {
            console.log("Timer triggered, starting operations");

            // Выполняем фоновые операции
            var user = dao.getUserByNickname(loadingPage.nick);
            var hashedPassword = crypto.hashPassword(loadingPage.password);
            var isValid = (user !== null) && (hashedPassword === user.password);
            var result = isValid ? "success" : "failure";

            console.log("Authentication result:", result);

            if (isValid) {
                console.log("Password is valid, activating user and navigating to PersonalChatsPage");
                dao.activate(loadingPage.nick);
                navigationTimer.start(); // Запуск таймера для выполнения навигации
            } else {
                console.log("Authentication failed, navigating back to LoginPage");
                errorTimer.start(); // Запуск таймера для выполнения возврата
            }
        }
    }

    Timer {
        id: navigationTimer
        interval: 500 // Задержка перед выполнением навигации
        running: false
        repeat: false
        onTriggered: {
            pageStack.replace(Qt.resolvedUrl("PersonalChatsPage.qml"));
        }
    }

    Timer {
        id: errorTimer
        interval: 500 // Задержка перед выполнением возврата
        running: false
        repeat: false
        onTriggered: {
            pageStack.pop();
            Notices.show(qsTr("Authentication failed"),
                         Notice.Short,
                         Notice.Bottom,
                         0,
                         -Theme.horizontalPageMargin);
        }
    }

    onOpened: {
        var params = pageStack.currentPage.itemParams;
        if (params) {
            loadingPage.nick = params.nick;
            loadingPage.password = params.password;
            console.log("Accepted parameters:", loadingPage.nick, loadingPage.password);
            operationTimer.start();
        } else {
            console.log("No parameters received");
            operationTimer.start();
        }
    }
}
