import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

//страница диалога-промежутка при загрузке страницы после входа
Dialog {
    id: loadingPage
    //доступны все ориентации экрана
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
        //отсутсвуют слова слева и справа в диалоге
        acceptText: qsTr("")
        cancelText: qsTr("")
        //есть фон
        background: true
    }

    // Индикатор загрузки
    BusyIndicator {
        //располагается по центру страницы
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
        //не идёт
        running: false
        //не повторяется
        repeat: false
        //когда триггернуть
        onTriggered: {
            // Выполняем фоновые операции
            //Получаем пользователя по нику, переданному из LoginPage
            var user = dao.getUserByNickname(loadingPage.nick);
            //хэшируем пароль
            var hashedPassword = crypto.hashPassword(loadingPage.password);
            //проверяем логин пароль на наличие такого пользователя в БД
            var isValid = (user !== null) && (hashedPassword === user.password);
            //получаем итог - успех или провал
            var result = isValid ? "success" : "failure";

            //если пароль правильный
            if (isValid) {
                //активируем пользователя
                dao.activate(loadingPage.nick);
                navigationTimer.start(); // Запуск таймера для выполнения навигации
            //если пароль неправильный
            } else {
                errorTimer.start(); // Запуск таймера для выполнения возврата
            }
        }
    }

    //таймер для навигации
    Timer {
        id: navigationTimer
        interval: 500 // Задержка перед выполнением навигации
        //изначально не стартует
        running: false
        //не повторяется
        repeat: false
        //когда триггернуть
        onTriggered: {
            //меняет верхнюю страницу в стеке на персональные чаты
            pageStack.replace(Qt.resolvedUrl("PersonalChatsPage.qml"));
        }
    }

    //таймер при ошибке
    Timer {
        id: errorTimer
        interval: 500 // Задержка перед выполнением возврата
        //изначально не стартует
        running: false
        //не повторяется
        repeat: false
        //когда триггернуть
        onTriggered: {
            //выталкивает страницу из стека
            pageStack.pop();
            //показывает уведомление о провале
            Notices.show(qsTr("Authentication failed"),
                         //короткое
                         Notice.Short,
                         //снизу
                         Notice.Bottom,
                         0,
                         //системные горизонтальные отступы
                         -Theme.horizontalPageMargin);
        }
    }

    //при открытии страницы
    onOpened: {
        //принимаем параметры из текущей страницы в стеке
        var params = pageStack.currentPage.itemParams;
        //если параметры есть
        if (params) {
            //передаем параметры на loadingPage
            loadingPage.nick = params.nick;
            loadingPage.password = params.password;
            //запуск таймера для операций
            operationTimer.start();
        //если параметров нет
        } else {
            //запуск таймера для операций
            operationTimer.start();
        }
    }
}
