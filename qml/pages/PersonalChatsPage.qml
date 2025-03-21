import QtQuick 2.0
import Sailfish.Silica 1.0
import Aurora.Controls 1.0

//страница личных чатов
Page{
    objectName: "PersonalChatsPage"
    //доступны все ориентации экрана
    allowedOrientations: Orientation.All
    id: chatsPage

    //объект dao для работы с бд
    Dao{
        id:dao
    }

    //прокручиваемый элемент страницы
    SilicaFlickable{
        id:chatsList
        //заполнение по родителю
        anchors.fill: parent
        //высота содержимого по родителю
        contentHeight: parent.height

        //шапка страницы
        AppBar{
            id:chatsBar
            //разделитель
            divider: true
            //фон
            background: true
            //подзаголовок
            subHeaderText: qsTr("Personal")

            //пустое пространство
            AppBarSpacer{}

            //заголовок
            headerText: qsTr("Chats")
        }

        //меню, вытягиваемое сверху вниз
        PullDownMenu{
            //отступ сверху по высоте шапки
            topMargin: chatsBar.height

            //элемент меню
            MenuItem {
                text: qsTr("Groups")
                //при клике
                onClicked: {
                    //меняем вершину стека страниц на группы
                    pageStack.replace(Qt.resolvedUrl("GroupChatsPage.qml"))
                }
            }

            //элемент меню
            MenuItem {
                text: qsTr("Contact")
                //при клике
                onClicked: {
                    //меняем вершину стека страниц на контакты
                    pageStack.replace(Qt.resolvedUrl("Contacts.qml"))
                }
            }

            //элемент меню
            MenuItem {
                text: qsTr("Invites")
                //при клике
                onClicked: {
                    //меняем вершину стека страниц на приглашения
                    pageStack.replace(Qt.resolvedUrl("InvitePage.qml"))
                }
            }

            //элемент меню
            MenuItem {
                text: qsTr("Settings")
                //при клике
                onClicked: {
                    //меняем вершину стека страниц на настройки
                    pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
                }
            }

            //элемент меню
            MenuItem {
                text: qsTr("Exit")
                //при клике
                onClicked: {
                    //деактивируем пользователя
                    dao.deActivate();
                    //убираем из стека все страницы до главной
                    pageStack.replaceAbove(null, Qt.resolvedUrl("MainPage.qml"))
                }
            }

            //подпись меню
            MenuLabel{
                text: qsTr("Commie")
            }
        }

        //столбец-заглушка с чатами
        Column{
            id:chatsCol
            //ширина по странице
            width: chatsPage.width
            //высота по странице минус шапка
            height: chatsPage.height-chatsBar.height
            //средние отступы между элементами столбца
            spacing: Theme.paddingMedium
            //привязка сверху по низу шапки
            anchors.top: chatsBar.bottom

            //не видна, пока страница чатов загружается
            visible: !(chatsPage.loading)

            //прокручиваемый элемент страницы
            SilicaListView{
                //ширина по столбцу
                width: chatsCol.width
                //высота по столбцу минус шапка
                height: chatsCol.height-chatsBar.height

                //модель списка
                model: ListModel{

                    ListElement{
                        author: "Мама"
                        message: "Привет"
                    }

                    ListElement{
                        author: "Папа"
                        message: "Чё матери не отвечаешь"
                    }

                    ListElement{
                        author: "900"
                        message: "Очередная хрень"
                    }

                    ListElement{
                        author: "Мама"
                        message: "Привет"
                    }

                    ListElement{
                        author: "Папа"
                        message: "Чё матери не отвечаешь"
                    }

                    ListElement{
                        author: "900"
                        message: "Очередная хрень"
                    }

                    ListElement{
                        author: "Мама"
                        message: "Привет"
                    }

                    ListElement{
                        author: "Папа"
                        message: "Чё матери не отвечаешь"
                    }

                    ListElement{
                        author: "900"
                        message: "Очередная хрень"
                    }

                    ListElement{
                        author: "Мама"
                        message: "Привет"
                    }

                    ListElement{
                        author: "Папа"
                        message: "Чё матери не отвечаешь"
                    }

                    ListElement{
                        author: "900"
                        message: "Очередная хрень"
                    }

                    ListElement{
                        author: "Мама"
                        message: "Привет"
                    }

                    ListElement{
                        author: "Папа"
                        message: "Чё матери не отвечаешь"
                    }

                    ListElement{
                        author: "901"
                        message: "Очередная хрень"
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
                //вертикальная полоса прокрутки
                VerticalScrollDecorator {flickable: ListView}
            }
        }
    }
}
