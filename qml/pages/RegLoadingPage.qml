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
        title: qsTr("Wait, please")
        // Кнопки - они же стороны для свайпа диалога
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
            var passwordRegex = /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+])[A-Za-z\d!@#$%^&*()_+]{15,}$/;
            var isValid = (loadingPage.nick.length > 0) && (passwordRegex.test(loadingPage.password));
            var result = isValid ? "success" : "failure";

            console.log("Validation result:", result);

            if (isValid) {
                console.log("Password is valid, performing hashing and database operations");

                // Хэшируем пароль
                var hashedPassword = crypto.hashPassword(loadingPage.password);
                var privateKey = crypto.generatePrivateKey();
                var publicKey = crypto.generatePublicKey(privateKey);
                var ip = peers.getCurrentIpAddress();
                var port = peers.getCurrentPort();
                var isActive = true;

                // Попытка добавить в БД пользователя данные из формы регистрации
                try {
                    dao.insertUser(loadingPage.nick, hashedPassword, publicKey, privateKey, ip, port, isActive);
                    // Если успешно добавлено, навигация на страницу личных чатов
                    console.log("Navigation to PersonalChatsPage");
                    navigationTimer.start(); // Запуск таймера для выполнения навигации
                } catch (error) {
                    console.error("Failed to insert user:", error);
                    // Возврат на страницу регистрации с уведомлением о ошибке
                    errorTimer.start();
                    Notices.show(qsTr("A user with this login already exists."),
                                 Notice.Short,
                                 Notice.Bottom,
                                 0,
                                 -Theme.horizontalPageMargin);
                }
            } else {
                console.log("Validation failed, navigating back to RegPage");
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
            Notices.show(qsTr("Fill in all fields"),
                         Notice.Short,
                         Notice.Bottom,
                         0,
                         -Theme.horizontalPageMargin);
        }
    }

    onOpened: {
        operationTimer.start();
    }
}
