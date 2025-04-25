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

                    // Аватар (без изменений)
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
                            visible: !isLocalChat
                            text: model.senderAlias || qsTr("Неизвестный")
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.paddingSmall

                            // Компонент для отображения изображений
                            Component {
                                id: imageMessageComponent
                                Image {
                                    width: Math.min(parent.width - Theme.iconSizeMedium - Theme.paddingMedium, 300)
                                    height: width * 0.75
                                    fillMode: Image.PreserveAspectFit
                                    source: JSON.parse(model.content).data
                                    cache: false
                                }
                            }

                            Component {
                                id: textLabelComponent
                                Label {
                                    text: model.content || ""
                                    color: model.isError ? Theme.errorColor : Theme.primaryColor
                                    font.pixelSize: Theme.fontSizeMedium
                                    wrapMode: Text.Wrap
                                    width: parent.width
                                }
                            }


                            // Отображение контента
                            Loader {
                                id: contentLoader
                                width: parent.width - (isLocalChat && model.isPending ? Theme.iconSizeSmall : 0)
                                sourceComponent: {
                                    try {
                                        if (typeof model.content === "string" && model.content.indexOf("{") === 0) {
                                            var content = JSON.parse(model.content);
                                            if (content.type === "image") {
                                                return imageMessageComponent;
                                            }
                                        }
                                        // Для текстовых сообщений
                                        return textLabelComponent;
                                    } catch(e) {
                                        console.error("Error parsing message content:", e);
                                        return textLabelComponent;
                                    }
                                }
                            }

                            // Индикатор состояния (точно как вы указали)
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
                                        return "✓";
                                    }
                                    color: {
                                        if (model.isError) return "red";
                                        if (model.isPending) return "orange";
                                        return "green";
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
                    pageStack.push(contentPickerPage); // Открываем пикер файлов
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
        if (messageInput.text.trim() === "") return;

        var currentUser = dao.getActiveUser();
        var tempId = Date.now();
        var messageText = messageInput.text;
        messageInput.text = "";

        // 1. Сначала добавляем в UI
        messageList.model.append({
                                     content: messageText,
                                     senderAlias: "Вы",
                                     created_at: new Date().toISOString(),
                                     isPending: true,
                                     tempId: tempId,
                                     isFile: (typeof content === "string" && content.indexOf("{") === 0) // Проверяем JSON
                                 });

        scrollTimer.restart();

        // 2. Затем сохраняем в БД (с задержкой 10мс)
        saveMessageTimer.tempId = tempId;
        saveMessageTimer.messageText = messageText;
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

    function handleFileSelection(fileProperties) {
        var filePath = fileProperties.filePath;
        var mimeType = fileProperties.mimeType;

        // Проверяем, что это изображение
        if (mimeType.indexOf("image/") !== 0) {
            console.log("Поддерживаются только изображения");
            return;
        }

        // Читаем файл
        var file = new XMLHttpRequest();
        file.open("GET", filePath, false);
        try {
            // Альтернатива overrideMimeType для Aurora OS
            file.setRequestHeader("Content-Type", "text/plain; charset=x-user-defined");
            file.send(null);

            if (file.status === 200) {
                var binary = "";
                for (var i = 0; i < file.responseText.length; i++) {
                    binary += String.fromCharCode(file.responseText.charCodeAt(i) & 0xff);
                }
                var base64Content = Qt.btoa(binary);
                var messageContent = JSON.stringify({
                                                        type: "image",
                                                        data: "data:" + mimeType + ";base64," + base64Content,
                                                        mimeType: mimeType
                                                    });
                sendMessage(messageContent);
            }
        } catch(e) {
            console.error("Ошибка при чтении файла:", e);
        }
    }


    Component {
        id: contentPickerPage
        ContentPickerPage {
            title: qsTr("Выберите файл")
            onSelectedContentPropertiesChanged: {
                if (selectedContentProperties) {
                    handleFileSelection(selectedContentProperties);
                }
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

