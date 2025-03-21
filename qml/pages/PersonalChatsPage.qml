import QtQuick 2.0
import Sailfish.Silica 1.0
import Aurora.Controls 1.0

Page{
    objectName: "PersonalChatsPage"
    allowedOrientations: Orientation.All
    id: chatsPage

    Dao{
        id:dao
    }

    SilicaFlickable{
        id:chatsList
        anchors.fill: parent
        contentHeight: parent.height

        AppBar{
            id:chatsBar
            divider: true
            background: true
            subHeaderText: qsTr("Personal")

            AppBarSpacer{}

            headerText: qsTr("Chats")
        }

        //меню, вытягиваемое сверху вниз
        PullDownMenu{
            topMargin: chatsBar.height

            MenuItem {
                text: qsTr("Groups")
                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("GroupChatsPage.qml"))
                }
            }

            MenuItem {
                text: qsTr("Contact")
                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("Contacts.qml"))
                }
            }

            MenuItem {
                text: qsTr("Invites")
                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("InvitePage.qml"))
                }
            }

            MenuItem {
                text: qsTr("Settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
                }
            }

            MenuItem {
                text: qsTr("Exit")
                onClicked: {
                    dao.deActivate();
                    pageStack.replaceAbove(null, Qt.resolvedUrl("MainPage.qml"))
                }
            }

            MenuLabel{
                text: qsTr("Commie")
            }
        }

        Column{
            id:chatsCol
            width: chatsPage.width
            height: chatsPage.height-chatsBar.height
            spacing: Theme.paddingMedium
            anchors.top: chatsBar.bottom

            visible: !(chatsPage.loading)

            SilicaListView{
                width: chatsCol.width
                height: chatsCol.height-chatsBar.height

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
                VerticalScrollDecorator {flickable: ListView}
            }
        }
    }
}
