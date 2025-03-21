import QtQuick 2.2
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import QtQuick.LocalStorage 2.0

Page{
    objectName: "mainPage"
    allowedOrientations: Orientation.All
    id:mainPage
    //объект для работы с БД SQLite
    Dao{
        id:dao
    }
    //верхнее меню приложения
    AppBar{
        headerText: qsTr("Commie")
        subHeaderText: qsTr("Safe messenger")
        id:header
        divider: true
        background: true
    }
    //вертикальный контейней для выравнивания кнопок по центру
    Column{
        id:buttonsLab
        width: mainPage.width
        height: mainPage.height-header.height
        anchors.top: header.bottom
        //контейнер, содержащий кнопки и лейбл
        Column{
            spacing: Theme.paddingLarge
            anchors.top: header.bottom
            anchors.centerIn: parent
            //кнопка для перехода на страницу регистрации
            Button {
                id: regButton
                text: qsTr("Sign up")
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.buttonWidthLarge
                onClicked: {
                    dao.deActivate();
                    pageStack.push(Qt.resolvedUrl("RegPage.qml"))
                }
            }
            //кнопка для перхода на страницу входа в аккаунт
            Button{
                id: loginButton
                text: qsTr("Sign in")
                width: Theme.buttonWidthLarge
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    dao.deActivate();
                    pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
                }
            }
        }
    }
    Component.onCompleted: {
        //при загрузке страницы запускаем сервер
        peers.startServer();
        console.log("Start server")
        dao.deActivate();
    }
}
