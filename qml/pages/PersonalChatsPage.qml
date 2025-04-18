import QtQuick 2.0
import Sailfish.Silica 1.0
import Aurora.Controls 1.0

Page {
    objectName: "PersonalChatsPage"
    allowedOrientations: Orientation.All
    id: chatsPage

    Dao {
        id: dao
    }

    // Функция для обновления списка чатов
    // В функции updateChatsList():
    function updateChatsList() {
        listView.model.clear();

        // Добавляем избранное
        listView.model.append({
                                  "isFavorite": true,
                                  "title": qsTr("Избранное"),
                                  "lastMessage": qsTr("Локальные заметки"),
                                  "chatId": "favorites", // Специальный идентификатор
                                  "chatType": 3
                              });

        // Добавляем личные чаты
        var currentUser = dao.getActiveUser();
        var chats = dao.getPersonalChats(currentUser.id);
        chats.forEach(function(chat) {
            listView.model.append({
                                      "isFavorite": false,
                                      "title": chat.alias || chat.login,
                                      "lastMessage": chat.last_message || qsTr("Нет сообщений"),
                                      "chatId": chat.id,
                                      "chatType": chat.chat_type,
                                      "avatar": chat.avatar
                                  });
        });
    }

    SilicaFlickable {
        id: chatsList
        anchors.fill: parent
        contentHeight: parent.height

        AppBar {
            id: chatsBar
            divider: true
            background: true
            subHeaderText: qsTr("Personal")

            AppBarSpacer{}
            headerText: qsTr("Chats")
            AppBarSpacer{}
        }

        PullDownMenu {
            topMargin: chatsBar.height

            MenuItem {
                text: qsTr("Groups")
                onClicked: pageStack.replace(Qt.resolvedUrl("GroupChatsPage.qml"))
            }

            MenuItem {
                text: qsTr("Contact")
                onClicked: pageStack.replace(Qt.resolvedUrl("Contacts.qml"))
            }

            MenuItem {
                text: qsTr("Invites")
                onClicked: pageStack.replace(Qt.resolvedUrl("InvitePage.qml"))
            }

            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }

            MenuItem {
                text: qsTr("Exit")
                onClicked: {
                    dao.deActivate();
                    pageStack.replaceAbove(null, Qt.resolvedUrl("MainPage.qml"))
                }
            }

            MenuLabel {
                text: qsTr("Commie")
            }
        }

        Column {
            id: chatsCol
            width: chatsPage.width
            height: chatsPage.height - chatsBar.height
            spacing: Theme.paddingMedium
            anchors.top: chatsBar.bottom

            SilicaListView {
                id: listView
                width: chatsCol.width
                height: chatsCol.height

                model: ListModel {
                    ListElement {
                        isFavorite: false
                        title: ""
                        lastMessage: ""
                        avatar: ""
                    }
                }

                delegate: BackgroundItem {
                    height: Theme.dp(120)

                    Row {
                        x: Theme.dp(16)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.paddingMedium

                        // Иконка чата
                        Rectangle {
                            width: Theme.dp(80)
                            height: Theme.dp(80)
                            radius: width * 0.5
                            color: model.isFavorite ? "#FFD700" : "#3D6BE3"

                            Label {
                                anchors.centerIn: parent
                                text: model.isFavorite ? "★" : (model.title ? model.title.charAt(0) : "")
                                color: model.isFavorite ? "#000000" : "#FFFFFF"
                                font.pixelSize: Theme.dp(40)
                            }
                        }

                        // Текстовая информация
                        Column {
                            width: parent.width - Theme.dp(100)
                            spacing: Theme.paddingSmall
                            x: 16

                            Label {
                                text: model.title || qsTr("Без названия")
                                color: "#FFFFFF"
                                font.pixelSize: Theme.dp(32)
                                font.bold: true
                                width: parent.width

                            }

                            Label {
                                text: model.lastMessage || qsTr("Нет сообщений")
                                color: "#AAAAAA"
                                font.pixelSize: Theme.dp(24)
                                width: parent.width

                            }
                        }
                    }

                    // В обработчике клика:
                    onClicked: {
                        if (model.isFavorite) {
                            var currentUser = dao.getActiveUser();
                            pageStack.push(Qt.resolvedUrl("ChatTemplate.qml"), {
                                               "chatId": "favorites_" + currentUser.id,
                                               "chatType": 3,
                                               "chatTitle": qsTr("Избранное"),
                                               "isLocalChat": true
                                           });
                        } else {
                            pageStack.push(Qt.resolvedUrl("ChatTemplate.qml"), {
                                               "chatId": model.chatId,
                                               "chatType": model.chatType,
                                               "chatTitle": model.title,
                                               "avatar": model.avatar,
                                               "isLocalChat": false
                                           });
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        updateChatsList();
    }
}
