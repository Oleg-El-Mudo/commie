import QtQuick 2.0
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import Sailfish.Pickers 1.0

Page {
    id: personalChatPage
    allowedOrientations: Orientation.All
    property string chatId
    property int user_id
    property int contact_id
    property string chatTitle
    property string user_public_key
    property string user_private_key
    property string user_enc_public_key
    property string user_enc_private_key
    property string contact_public_key
    property string contact_enc_public_key
    property string contact_ip
    property int contact_port
    property bool isLocalChat: false

    Dao { id: dao }
    // Фиксированная шапка
    AppBar {
        id: header
        width: parent.width
        divider: true
        background: true
        headerText: chatTitle
        subHeaderText: qsTr("Личный чат")
    }

    // Список сообщений
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
            interactive: false
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
                            text: (model.senderAlias ? model.senderAlias.charAt(0) : "?")
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeLarge
                        }
                    }
                    Column {
                        id: messageColumn
                        width: parent.width - Theme.iconSizeMedium - Theme.paddingMedium
                        spacing: Theme.paddingSmall
                        Label {
                            visible: true
                            text: model.senderAlias || qsTr("Неизвестный")
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }
                        Row {
                            width: parent.width
                            spacing: Theme.paddingSmall
                            Label {
                                text: model.content
                                color: Theme.primaryColor
                                font.pixelSize: Theme.fontSizeMedium
                                width: parent.width - (isLocalChat && model.isPending ? Theme.iconSizeSmall : 0)
                                wrapMode: Text.Wrap
                                visible: true
                            }
                            Loader {
                                active: (model.isPending !== undefined || model.isSaved !== undefined || model.isError)
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
            VerticalScrollDecorator { flickable: parent.parent }
        }
    }

    // Панель ввода
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
            TextField {
                id: messageInput
                width: parent.width - sendButton.width - 2*Theme.paddingSmall
                placeholderText: qsTr("Сообщение...")
                EnterKey.onClicked: sendMessage()
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            }
            IconButton {
                id: sendButton
                icon.source: "image://theme/icon-m-send"
                onClicked: sendMessage()
            }
        }
    }

    function normalizeIp(ip) {
        var ipStr = typeof ip === "string" ? ip : JSON.stringify(ip);
        var index = ipStr.indexOf("::ffff:");
        if (index !== -1) {
            return ipStr.substr(index + 7);
        }
        return ipStr;
    }

    function connectToMessageSignal() {
        peers.messageReceived.connect(handleMessageReceived);
    }

    function disconnectFromMessageSignal() {
        peers.messageReceived.disconnect(handleMessageReceived);
    }

    function handleMessageReceived(ip, port, message) {
        var normalizedIp = normalizeIp(ip);
        if (normalizedIp !== normalizeIp(contact_ip)) {
            return;
        }

        try {
            var msgObj = JSON.parse(message.trim());
            var encryptedMessage = msgObj.encrypted_message;
            var signature = msgObj.signature;

            // Генерируем общий секрет правильно
            var sharedSecret = crypto.generateSharedSecret(user_enc_private_key, contact_enc_public_key);

            // Расшифровываем
            var decryptedMessage = crypto.decryptWithSharedSecret(encryptedMessage, sharedSecret);

            // Проверяем подпись
            var isValid = crypto.verifyMessage(decryptedMessage, signature, contact_public_key);

            messageList.model.append({
                                         content: isValid ? decryptedMessage : "[Неверная подпись]",
                                         isSent: false,
                                         senderAlias: chatTitle,
                                         isError: !isValid
                                     });

            scrollTimer.restart();
            saveIncomingMessage(encryptedMessage, signature);

        } catch (e) {
            console.error("Ошибка получения сообщения:", e);
            console.error("Неудачный JSON:", message);
        }
    }

    function saveIncomingMessage(encryptedMessage, signature) {
        dao.addPersonalMessageWithSignature(chatId, false, encryptedMessage, signature);
    }

    function sendMessage() {
        if (messageInput.text.trim() === "") return;
        var messageText = messageInput.text;
        messageInput.text = "";

        var sharedSecret = crypto.generateSharedSecret(user_enc_private_key, contact_enc_public_key);
        var encryptedForContact = crypto.encryptWithSharedSecret(messageText, sharedSecret);
        var signature = crypto.signMessage(messageText, user_private_key);

        // Добавляем своё сообщение во временный список
        messageList.model.append({
            content: messageText,
            isSent: true,
            senderAlias: "Вы",
            isError: false,
            isPending: true
        });

        // Сохраняем в БД асинхронно
        saveMessageTimer.chatId = chatId;
        saveMessageTimer.encryptedMessage = encryptedForContact;
        saveMessageTimer.signature = signature;
        saveMessageTimer.start();

        var payload = {
            encrypted_message: String(encryptedForContact),
            signature: String(signature)
        };
        peers.sendMessage(contact_ip, contact_port, JSON.stringify(payload));
    }

    Timer {
        id: saveMessageTimer
        interval: 10
        property var chatId
        property var tempId
        property string encryptedMessage
        property string signature

        onTriggered: {
            var success;
            try {
                dao.addPersonalMessageWithSignature(chatId, true, encryptedMessage, signature);
                success = true;
            } catch(e) {
                console.error("Ошибка сохранения:", e);
                success = false;
            }
            updateMessageStatus(tempId, success);
            loadMessages();
        }
    }
    Timer {
        id: scrollTimer
        interval: 0
        onTriggered: {
            console.log("Прокрутка активирована");
            flickable.contentY = flickable.contentHeight - flickable.height;
        }
    }

    function loadMessages() {
        messageList.model.clear();
        var messages = dao.loadPersonalMessages(chatId);
        messages.forEach(function(msg) {
            try {
                // Генерируем общий секрет один раз
                var sharedSecret = crypto.generateSharedSecret(user_enc_private_key, contact_enc_public_key);

                // Расшифровываем через общий секрет
                var decrypted = crypto.decryptWithSharedSecret(msg.content, sharedSecret);
                if (!decrypted) {
                    console.error("Не удалось расшифровать");
                    return;
                }

                // Проверяем подпись
                var isValid = msg.is_sent ?
                            crypto.verifyMessage(decrypted, msg.signature, user_public_key) :
                            crypto.verifyMessage(decrypted, msg.signature, contact_public_key);

                messageList.model.append({
                                             content: isValid ? decrypted : "[Неверная подпись]",
                                             isSent: Boolean(msg.is_sent),
                                             senderAlias: msg.is_sent ? "Вы" : chatTitle,
                                             isError: !isValid
                                         });
            } catch (e) {
                console.error("Ошибка расшифровки:", e);
                messageList.model.append({
                                             content: "[Ошибка расшифровки]",
                                             isSent: msg.is_sent,
                                             senderAlias: msg.is_sent ? "Вы" : chatTitle,
                                             isError: true
                                         });
            }
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

    Component.onCompleted: {
        console.log("contact_ip:", contact_ip);
        console.log("contact_port:", contact_port);
        connectToMessageSignal();
        messageList.model.countChanged.connect(function() {
            flickable.contentY = flickable.contentHeight - flickable.height;
        });
        loadMessages();
        console.log("На странице чата")
        console.log("Публичный ключ подписи пользователя: " + user_public_key);
        console.log("Приватный ключ подписи пользователя: " + user_private_key);
        console.log("Публичный ключ шифрования пользователя: " + user_enc_public_key);
        console.log("Приватный ключ шифрования пользователя: " + user_enc_private_key);
        console.log("Публичный ключ подписи контакта: " + contact_public_key);
        console.log("Публичный ключ шифрования контака: " + contact_enc_public_key);
    }

    Component.onDestruction: {
        disconnectFromMessageSignal();
    }
}
