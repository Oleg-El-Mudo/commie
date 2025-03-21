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

            // Выполняем фоновые операции
            //регулярное выражение для проверки валидности пароля
            var passwordRegex = /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+])[A-Za-z\d!@#$%^&*()_+]{15,}$/;
            //проверка введённого пароля по выражению
            var isValid = (loadingPage.nick.length > 0) && (passwordRegex.test(loadingPage.password));
            //формирование сообщения о результатах проверки
            var result = isValid ? "success" : "failure";

            if (isValid) {
                console.log("Password is valid, performing hashing and database operations");

                // Хэшируем пароль
                var hashedPassword = crypto.hashPassword(loadingPage.password);
                //генерируем приватный ключ
                var privateKey = crypto.generatePrivateKey();
                //генерируем публичный ключ
                var publicKey = crypto.generatePublicKey(privateKey);
                //получаем актуальный айпишник
                var ip = peers.getCurrentIpAddress();
                //получаем актуальный порт
                var port = peers.getCurrentPort();
                //устанавливаем пользователя как активного
                var isActive = true;

                // Попытка добавить в БД пользователя данные из формы регистрации
                try {
                    //добавляем в БД нового пользователя
                    dao.insertUser(loadingPage.nick, hashedPassword, publicKey, privateKey, ip, port, isActive);
                    // Если успешно добавлено, навигация на страницу личных чатов
                    navigationTimer.start(); // Запуск таймера для выполнения навигации
                //если словили ошибку
                } catch (error) {
                    // Возврат на страницу регистрации с уведомлением о ошибке
                    errorTimer.start();
                    Notices.show(qsTr("A user with this login already exists."),
                                 Notice.Short,
                                 Notice.Bottom,
                                 0,
                                 -Theme.horizontalPageMargin);
                }
            //если пароль не прошел валидацию
            } else {
                errorTimer.start(); // Запуск таймера для выполнения возврата
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
