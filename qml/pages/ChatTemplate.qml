import QtQuick 2.0
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import Sailfish.Pickers 1.0

Page {
    id: chatPage
    allowedOrientations: Orientation.All

    property string chatId
    property int chatType: 1
    property string chatTitle
    property string avatar
    property bool isLocalChat: chatType === 3
    property int lastMessageId: 0

    Dao {
        id: dao
    }

    // НЕВИДИМЫЙ КОНТЕЙНЕР для того, чтобы сурс отсюда передать в модель
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

          //Заморожено

                            // Если отправляется картинка
//                            Image {
//                                source: model.src
//                                width: 200
//                                height: 200
//                                visible: model.isImage // Управляйте видимостью через флаг
//                                onSourceChanged: {
//                                    console.log("Image source updated to:", source);
//                                }
//                                Component.onCompleted: {
//                                    console.log("Initial model.src value:", model.src); // Логирование начального значения model.src
//                                }
//                            }

                            // Если отправляется текст
                            Label {
                                text: model.content
                                color: model.isError ? Theme.errorColor : Theme.primaryColor
                                font.pixelSize: Theme.fontSizeMedium
                                width: parent.width - (isLocalChat && model.isPending ? Theme.iconSizeSmall : 0)
                                wrapMode: Text.Wrap
                                visible: !model.isImage // Текст скрывается, если есть изображение
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

            //ЗАМОРОЖЕНО

            // 1. Иконка скрепки (пока без функционала)
//            IconButton {
//                id: attachButton
//                icon.source: "image://theme/icon-m-attach"
//                onClicked: {
//                    pageStack.push(imagePickerPage); // Открываем пикер файлов
//                }
//            }

            // 2. Поле ввода (оставляем как было)
            TextField {
                id: messageInput
                width: parent.width - sendButton.width - 2*Theme.paddingSmall
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

    //функция отправки сообщений
    function sendMessage() {
        if (messageInput.text.trim() === "" && sourceImage.source === "") return;

        var currentUser = dao.getActiveUser();
        var tempId = Date.now();
        var messageText = messageInput.text;
        var imgSrc = sourceImage.source.toString();

        // Очищаем поле ввода
        messageInput.text = "";
        sourceImage.source = "";

        // Добавляем данные в модель
        messageList.model.append({
                                     content: messageText,
                                     senderAlias: "Вы",
                                     created_at: new Date().toISOString(),
                                     isPending: true,
                                     tempId: tempId,
                                     src: imgSrc? imgSrc : undefined
                                 });

        scrollTimer.restart();

        // Сохраняем в базу данных
        saveMessageTimer.tempId = tempId;
        saveMessageTimer.messageText = imgSrc? imgSrc : messageText; // Сохраняем путь к файлу или текст
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
            loadMessages()
        }
    }

    Timer {
        id: scrollTimer
        interval: 0
        onTriggered: {
            flickable.contentY = flickable.contentHeight - flickable.height;
        }
    }

    function isImage(content) {
        var extensions = [".jpg", ".jpeg", ".png", ".gif"]; // Список поддерживаемых расширений
        for (var i = 0; i < extensions.length; i++) {
            var ext = extensions[i];
            var index = content.toLowerCase().indexOf(ext);
            if (index !== -1 && index === content.length - ext.length) {
                return true; // Строка оканчивается на расширение
            }
        }
        return false; // Расширение не найдено
    }

    function loadMessages() {
        messageList.model.clear();
        var currentUser = dao.getActiveUser();

        // Загружаем сообщения из базы данных
        var messages = isLocalChat ?
                    dao.getFavoritesMessages(currentUser.id) :
                    dao.getChatMessages(chatId);

        messages.forEach(function(msg) {
            var content = msg.content || "";
            var src = "";
            var isImageFlag = false;

            // Проверяем, является ли содержимое изображением
            if (isImage(content)) {
                src = content; // Это путь к изображению
                content = "";  // Очищаем текстовое содержимое
                isImageFlag = true;
            }

            // Добавляем данные в модель
            messageList.model.append({
                                         content: content,
                                         senderAlias: msg.sender_alias || "",
                                         created_at: msg.created_at,
                                         src: src,         // Путь к изображению
                                         isImage: isImageFlag  // Флаг для изображения
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
                sendMessage();
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
