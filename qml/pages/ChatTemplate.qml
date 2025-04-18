import QtQuick 2.0
import Sailfish.Silica 1.0
import Aurora.Controls 1.0

Page {
    id: chatPage

    property string chatId
    property int chatType: 1
    property string chatTitle
    property string avatar
    property bool isLocalChat: chatType === 3

    Dao {
        id: dao
    }

    // Фиксированная шапка (не прокручивается)
    AppBar {
        id: header
        width: parent.width
        divider: true
        background: true
        headerText: chatTitle
        subHeaderText: isLocalChat ? qsTr("Локальные заметки") :
                     (chatType === 1 ? qsTr("Личный чат") : qsTr("Групповой чат"))
    }

    // Основное содержимое (прокручивается)
    SilicaFlickable {
        anchors {
            top: header.bottom
            bottom: inputArea.top
            left: parent.left
            right: parent.right
        }
        contentHeight: messageList.height

        SilicaListView {
            id: messageList
            width: parent.width
            height: childrenRect.height
            interactive: false // Отключаем вложенную прокрутку

            model: ListModel {}

            delegate: BackgroundItem {
                width: parent.width
                height: Theme.itemSizeMedium

                Row {
                    spacing: Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin

                    Rectangle {
                        width: Theme.iconSizeMedium
                        height: Theme.iconSizeMedium
                        radius: width/2
                        color: isLocalChat ? Theme.highlightColor : Theme.primaryColor

                        Label {
                            anchors.centerIn: parent
                            text: isLocalChat ? "★" : (model.senderAlias ? model.senderAlias.charAt(0) : "?")
                            color: isLocalChat ? Theme.primaryColor : Theme.highlightColor
                            font.pixelSize: Theme.fontSizeLarge
                        }
                    }

                    Column {
                        width: parent.width - Theme.iconSizeMedium - Theme.horizontalPageMargin * 2
                        spacing: Theme.paddingSmall

                        Label {
                            text: isLocalChat ? "" : (model.senderAlias || qsTr("Неизвестный"))
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Label {
                            text: model.content || ""
                            color: Theme.primaryColor
                            font.pixelSize: Theme.fontSizeMedium
                            width: parent.width
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            VerticalScrollDecorator { flickable: parent.parent } // Декоратор для Flickable
        }
    }

    // Фиксированная панель ввода внизу
    Rectangle {
        id: inputArea
        width: parent.width
        height: Theme.itemSizeMedium
        anchors.bottom: parent.bottom
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)

        TextField {
            id: messageInput
            anchors.fill: parent
            anchors.margins: Theme.paddingSmall
            placeholderText: isLocalChat ? qsTr("Новая заметка...") : qsTr("Сообщение...")

            EnterKey.onClicked: sendMessage()
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
        }

        IconButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Theme.paddingMedium
            icon.source: "image://theme/icon-m-send"
            onClicked: sendMessage()
        }
    }

    function sendMessage() {
        if (messageInput.text.trim() === "") return;

        var currentUser = dao.getActiveUser();
        if (isLocalChat) {
            dao.saveToFavorites(currentUser.id, messageInput.text);
        } else {
            dao.sendMessage(chatId, currentUser.id, messageInput.text);
        }

        messageInput.text = "";
        loadMessages();
    }

    function loadMessages() {
        messageList.model.clear();
        var currentUser = dao.getActiveUser();
        var messages = isLocalChat ? dao.getFavoritesMessages(currentUser.id) : dao.getChatMessages(chatId);

        messages.forEach(function(msg) {
            messageList.model.append({
                content: msg.content,
                senderAlias: msg.sender_alias || "",
                created_at: msg.created_at
            });
        });

        // Прокручиваем вниз после загрузки сообщений
        Qt.callLater(function() {
            flickable.contentY = flickable.contentHeight - flickable.height;
        });
    }

    Component.onCompleted: {
        loadMessages();
        if (isLocalChat) {
            var currentUser = dao.getActiveUser();
            dao.createFavoritesChat(currentUser.id);
        }
    }
}
