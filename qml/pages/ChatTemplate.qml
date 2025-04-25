import QtQuick 2.0
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import Sailfish.Pickers 1.0

Page {
    id: chatPage

    property string chatId
    property int chatType: 1
    property string chatTitle
    property string avatar
    property bool isLocalChat: chatType === 3
    property int lastMessageId: 0

    Dao {
        id: dao
    }

    // НЕВИДИМЫЙ КОНТЕЙНЕР ДЛЯ ОБРЕЗКИ
    Item {
        id: cropContainer
        width: 200
        height: 200
        visible: false

        Image {
            id: sourceImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            clip: true
        }
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
        id: flickable
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
                height: Math.max(Theme.itemSizeMedium, messageColumn.height + 2*Theme.paddingMedium)

                Row {
                    spacing: Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*Theme.horizontalPageMargin

                    // Аватар
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
                        id: messageColumn
                        width: parent.width - Theme.iconSizeMedium - Theme.paddingMedium
                        spacing: Theme.paddingSmall

                        Label {
                            visible: !isLocalChat && !model.isImage
                            text: model.senderAlias || qsTr("Неизвестный")
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.paddingSmall

                            Item {
                                width: model.isImage ? Theme.iconSizeLarge : 0
                                height: model.isImage ? Theme.iconSizeLarge : 0

                                Image {
                                    id: messageImage
                                    visible: model.isImage
                                    anchors.fill: parent
                                    source: model.content
                                    fillMode: Image.PreserveAspectFit
                                }
                            }

                            Label {
                                text: !model.isImage ? model.content : ""
                                color: model.isError ? Theme.errorColor : Theme.primaryColor
                                font.pixelSize: Theme.fontSizeMedium
                                width: parent.width - (isLocalChat && model.isPending ? Theme.iconSizeSmall : 0)
                                wrapMode: Text.Wrap
                            }

                            // Индикатор состояния (только для избранного)
                            Loader {
                                active: isLocalChat && (model.isPending !== undefined || model.isSaved !== undefined || model.isError)
                                visible: active
                                sourceComponent: Label {
                                    width: Theme.iconSizeSmall
                                    height: Theme.iconSizeSmall
                                    font.pixelSize: Theme.fontSizeSmall
                                    verticalAlignment: Text.AlignVCenter
                                    text: {
                                        if (model.isError) return "❌";
                                        if (model.isPending) return "⏳";
                                        return "✓"; // Галочка при успешном сохранении
                                    }
                                    color: {
                                        if (model.isError) return "red";
                                        if (model.isPending) return "orange";
                                        return "green"; // Зеленый цвет при успешном сохранении
                                    }
                                }
                            }
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

        Row {
            anchors.fill: parent
            anchors.margins: Theme.paddingSmall
            spacing: Theme.paddingSmall

            // 1. Иконка скрепки (пока без функционала)
            IconButton {
                id: attachButton
                icon.source: "image://theme/icon-m-attach"
                onClicked: {
                    pageStack.push(imagePickerPage); // Открываем пикер файлов
                }
            }

            // 2. Поле ввода (оставляем как было)
            TextField {
                id: messageInput
                width: parent.width - attachButton.width - sendButton.width - 2*Theme.paddingSmall
                placeholderText: isLocalChat ? qsTr("Новая заметка...") : qsTr("Сообщение...")
                EnterKey.onClicked: sendMessage()
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            }

            // 3. Кнопка отправки (оставляем как было)
            IconButton {
                id: sendButton
                icon.source: "image://theme/icon-m-send"
                onClicked: sendMessage()
            }
        }
    }

    function sendMessage() {
        if (messageInput.text.trim() === "" && sourceImage.source === "") return;

        var currentUser = dao.getActiveUser();
        var tempId = Date.now();
        var messageText = messageInput.text;
        messageInput.text = "";

        var messageContent = messageText.trim() !== "" ? messageText : sourceImage.source;
        var isImage = messageText.trim() === "";

        console.log("Sending message with content:", messageContent); // Отладочный вывод

        // 1. Сначала добавляем в UI
        messageList.model.append({
                                     content: messageContent,
                                     senderAlias: "Вы",
                                     created_at: new Date().toISOString(),
                                     isPending: true,
                                     tempId: tempId,
                                     isImage: isImage
                                 });

        sourceImage.source = ""; // Очищаем путь к изображению после отправки
        scrollTimer.restart();

        // 2. Затем сохраняем в БД (с задержкой 10мс)
        saveMessageTimer.tempId = tempId;
        saveMessageTimer.messageText = messageContent;
        saveMessageTimer.currentUser = currentUser;
        saveMessageTimer.start();
    }

    Timer {
        id: saveMessageTimer
        interval: 10
        property var tempId
        property string messageText
        property var currentUser

        onTriggered: {
            var success;
            try {
                if (isLocalChat) {
                    dao.saveToFavorites(currentUser.id, messageText);
                    success = true;
                } else {
                    dao.sendMessageOptimized(chatId, currentUser.id, messageText);
                    success = true;
                }
            } catch(e) {
                console.error("Ошибка сохранения:", e);
                success = false;
            }
            updateMessageStatus(tempId, success);
        }
    }

    Timer {
        id: scrollTimer
        interval: 0
        onTriggered: {
            flickable.contentY = flickable.contentHeight - flickable.height;
        }
    }

    function loadMessages() {
        messageList.model.clear();
        var currentUser = dao.getActiveUser();

        // Используем существующие методы DAO
        var messages = isLocalChat ?
                    dao.getFavoritesMessages(currentUser.id) :
                    dao.getChatMessages(chatId);

        messages.forEach(function(msg) {
            messageList.model.append({
                                         content: msg.content,
                                         senderAlias: msg.sender_alias || "",
                                         created_at: msg.created_at
                                     });
        });

        scrollTimer.restart();
    }

    function updateMessageStatus(tempId, success) {
        for (var i = 0; i < messageList.model.count; i++) {
            if (messageList.model.get(i).tempId === tempId) {
                messageList.model.set(i, {
                                          isPending: !success,
                                          tempId: undefined
                                      });
                break;
            }
        }
    }

    Component {
        id: imagePickerPage
        ImagePickerPage {
            onSelectedContentPropertiesChanged: {
                var filePath = selectedContentProperties.filePath;
                console.log("Selected file path:", filePath); // Отладочный вывод
                sourceImage.source = filePath; // Убедитесь, что путь корректен
            }
        }
    }

    Component.onCompleted: {
        loadMessages();
        if (isLocalChat) {
            var currentUser = dao.getActiveUser();
            dao.createFavoritesChat(currentUser.id);
        }
    }
}
