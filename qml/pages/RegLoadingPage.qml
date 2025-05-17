import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

//страница для загрузки после регистрации
Dialog {
    id: loadingPage
    //доступны все ориентации
    allowedOrientations: Orientation.All

    // Параметры, переданные с страницы регистрации
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
        //фон
        background: true
    }

    // Индикатор загрузки
    BusyIndicator {
        anchors.centerIn: parent
        //крутится
        running: true
        //большой размер индикатора
        size: BusyIndicatorSize.Large
    }

    //таймер для операций
    Timer {
        id: operationTimer
        interval: 100 // Задержка перед началом выполнения операций
        //изначально не запускается
        running: false
        //не повторяеся
        repeat: false
        //когда триггернуть
        onTriggered: {
            // Проверка валидности пароля
            var passwordRegex = /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+])[A-Za-z\d!@#$%^&*()_+]{15,}$/;
            var isValid = (loadingPage.nick.length > 0) && (passwordRegex.test(loadingPage.password));

            if (isValid) {
                console.log("Password is valid, performing registration...");

                try {
                    // 1. Хеширование пароля
                    var hashedPassword = crypto.hashPassword(loadingPage.password);

                    // 2. Генерация ключей Ed25519 (для подписи)
                    var privateKey = crypto.generatePrivateKey();
                    var publicKey = crypto.generatePublicKey(privateKey);

                    // 3. Генерация ключей X25519 (для ECDH-шифрования)
                    var x25519Keys = JSON.parse(crypto.generateX25519KeyPair());
                    var encPrivateKey = x25519Keys.private_key;
                    var encPublicKey = x25519Keys.public_key;

                    // 4. Получение сетевых данных
                    var ip = peers.getCurrentIpAddress();
                    var port = peers.getCurrentPort();
                    var isActive = true;

                    // 5. Сохранение пользователя в БД
                    dao.insertUser(
                        loadingPage.nick,
                        hashedPassword,
                        publicKey,      // Ed25519 публичный
                        privateKey,     // Ed25519 приватный
                        ip,
                        port,
                        isActive,            // isActive
                        encPublicKey,   // X25519 публичный
                        encPrivateKey  // X25519 приватный
                    );

                    // 6. Запуск P2P-сервера
                    peers.startServer();

                    // 7. Обновление IP/port в БД (на случай динамического изменения)
                    dao.updateIpAndPort(ip, port);

                    // 8. Переход на страницу чатов
                    navigationTimer.start();

                } catch (error) {
                    console.error("Registration error:", error);
                    errorTimer.start();
                    Notices.show(
                        error.message.includes("UNIQUE") ?
                        qsTr("A user with this login already exists.") :
                        qsTr("Registration failed. Please try again."),
                        Notice.Short,
                        Notice.Bottom,
                        0,
                        -Theme.horizontalPageMargin
                    );
                }
            } else {
                errorTimer.start();
                Notices.show(
                    qsTr("Password must be 15+ chars with letters, numbers and special symbols."),
                    Notice.Short,
                    Notice.Bottom,
                    0,
                    -Theme.horizontalPageMargin
                );
            }
        }
    }

    //таймер для навигации
    Timer {
        id: navigationTimer
        interval: 500 // Задержка перед выполнением навигации
        //сам не стартует
        running: false
        //не повторяется
        repeat: false
        //при запуске заменяет текущую страницу на список личных чатов
        onTriggered: {
            pageStack.replace(Qt.resolvedUrl("PersonalChatsPage.qml"));
        }
    }

    //таймер для ошибок
    Timer {
        id: errorTimer
        interval: 500 // Задержка перед выполнением возврата
        //сам не стартует
        running: false
        //не повторяется
        repeat: false
        //при запуске удаляет страницу из стека
        onTriggered: {
            pageStack.pop();
            //показывает уведомление, что нужно заполнить все поля
            Notices.show(qsTr("Fill in all fields"),
                         Notice.Short,
                         Notice.Bottom,
                         0,
                         -Theme.horizontalPageMargin);
        }
    }

    //при открытии страницы запускает таймер для операций
    onOpened: {
        operationTimer.start();
    }
}
