import QtQuick 2.0
import Sailfish.Silica 1.0
import Aurora.Controls 1.0

//страница с персональными чатами
Page{
    objectName: "GroupChatsPage"
    allowedOrientations: Orientation.All
    id: chatsPage
    //прокручиваемы элемент страницы
    SilicaFlickable{
        id:chatsList
        //заполнение по родителю
        anchors.fill: parent
        //высота содержимого по родителю
        contentHeight: parent.height
        //шапка приложения
        AppBar{
            id:chatsBar
            //разделитель
            divider: true
            //фон
            background: true
            //подзаголовок
            subHeaderText: qsTr("Groups")
            //пустое пространство
            AppBarSpacer{}
            //заголовок
            headerText: qsTr("Chats")
        }
        //меню, вытягиваемое сверху вниз
        PullDownMenu{
            //отступ сверху
            topMargin: chatsBar.height
            //Элемент меню "Персональные чаты"
            MenuItem {
                text: qsTr("Personal Chats")
                //при клике
                onClicked: {
                    //меняем вершину стека страниц на персональные чаты
                    pageStack.replace(Qt.resolvedUrl("PersonalChatsPage.qml"))
                }
            }
            //Элемент меню "Контакты"
            MenuItem {
                text: qsTr("Contacts")
                //при клике
                onClicked: {
                    //меняем вершину стека страниц на контакты
                    pageStack.replace(Qt.resolvedUrl("Contacts.qml"))
                }
            }
            //Элемент меню "Приглашения"
            MenuItem {
                text: qsTr("Invites")
                //при клике
                onClicked: {
                    //меняем вершину стека страниц на приглашения
                    pageStack.replace(Qt.resolvedUrl("InvitePage.qml"))
                }
            }
            //элемент меню "Настройки"
            MenuItem {
                text: qsTr("Settings")
                //при клике
                onClicked: {
                    //меняем вершину стека страниц на настройки
                    pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
                }
            }
            //элемент меню "Выход"
            MenuItem {
                text: qsTr("Exit")
                //при клике
                onClicked: {
                    //деактивируем пользователя
                    dao.deActivate();
                    //выкидываем из стека все страницы до главной
                    pageStack.replaceAbove(null, Qt.resolvedUrl("MainPage.qml"))
                }
            }
            //подпись меню
            MenuLabel{
                text: qsTr("Commie")
            }
        }
        //столбец со списком чатов
        Column{
            id:chatsCol
            width: chatsPage.width
            height: chatsPage.height-chatsBar.height
            spacing: Theme.paddingMedium
            anchors.top: chatsBar.bottom
            //Списочный элемент - заглушка
            SilicaListView{
                width: chatsCol.width
                height: chatsCol.height-chatsBar.height
                model: ListModel{
                    ListElement{
                        author: "Cемья"
                        message: "Чё на ужин взять"
                    }
                    ListElement{
                        author: "Работа"
                        message: "завтра к 8"
                    }
                    ListElement{
                        author: "Учёба"
                        message: "дз отменяется. Препод принял ислам"
                    }
                }
                delegate: BackgroundItem{
                    height: Theme.dp(120)
                    Row{
                        x: Theme.dp(16)
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle{
                            x: 20
                            y: 20
                            color: "#3D6BE3"
                            width: 15
                            height: width
                            radius: width*0.5
                        }
                        Column{
                            width: parent.width
                            Label{
                                x: 16
                                text: author
                                color: "#FFFFFF"
                                font.pixelSize: Theme.dp(32)
                                font.bold: true
                            }
                            Label{
                                x: 16
                                text: message
                                color: "#FFFFFF"
                                topPadding: 8
                                font.pixelSize: Theme.dp(24)
                            }
                        }
                    }
                }
                //вертикальная полоса прокрутки списка
                VerticalScrollDecorator {flickable: ListView}
            }
        }
    }
}
