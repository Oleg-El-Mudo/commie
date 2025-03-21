import QtQuick 2.2
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import QtQuick.LocalStorage 2.0

Page{
    objectName: "mainPage"
    //доступны все ориентации экрана
    allowedOrientations: Orientation.All
    id:mainPage
    //объект для работы с БД SQLite
    Dao{
        id:dao
    }
    //верхнее меню приложения
    AppBar{
        //заголовок
        headerText: qsTr("Commie")
        /подзаголовок
        subHeaderText: qsTr("Safe messenger")
        id:header
        //разделитель
        divider: true
        //фон
        background: true
    }
    //вертикальный контейней для выравнивания кнопок по центру
    Column{
        id:buttonsLab
        //ширина по странице
        width: mainPage.width
        //высота по странице минус шапка страницы
        height: mainPage.height-header.height
        //привязка сверху по низу шапки
        anchors.top: header.bottom
        //контейнер, содержащий кнопки и лейбл
        Column{
            //большие отступы между элементами столбца
            spacing: Theme.paddingLarge
            //привязка сверху к низу шапки
            anchors.top: header.bottom
            //центрирование в родителе
            anchors.centerIn: parent
            //кнопка для перехода на страницу регистрации
            Button {
                id: regButton
                text: qsTr("Sign up")
                //горизонтальное выравнивание по центру
                anchors.horizontalCenter: parent.horizontalCenter
                //ширина системная большая
                width: Theme.buttonWidthLarge
                //при клике
                onClicked: {
                    //деактивация пользователей
                    dao.deActivate();
                    //переход на страницу регистрации
                    pageStack.push(Qt.resolvedUrl("RegPage.qml"))
                }
            }
            //кнопка для перхода на страницу входа в аккаунт
            Button{
                id: loginButton
                text: qsTr("Sign in")
                //большая ширина кнопки
                width: Theme.buttonWidthLarge
                //горизонтальное выраванивание по центру
                anchors.horizontalCenter: parent.horizontalCenter
                //при клике
                onClicked: {
                    //деактивация пользователей
                    dao.deActivate();
                    //переход на страницу входа
                    pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
                }
            }
        }
    }
    Component.onCompleted: {
        //при загрузке страницы запускаем сервер
        peers.startServer();
        //деактивируем пользователей
        dao.deActivate();
    }
}
