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
        var normalizedContactIp = normalizeIp(contact_ip);

        if (normalizedIp === normalizedContactIp) {
            try {
                // Проверяем, что строка не пустая
                if (!message || typeof message !== 'string' || message.trim() === "") {
                    console.error("Получена пустая строка");
                    return;
                }

                // Попробуем распарсить JSON
                var msgObj = JSON.parse(message.trim());

                var encryptedMessage = msgObj.encrypted_message;
                var signature = msgObj.signature;

                if (!encryptedMessage || !signature) {
                    console.error("Неверные данные в JSON:", msgObj);
                    return;
                }

                // Расшифровываем
                var decryptedMessage = crypto.decryptMessage(encryptedMessage, user_enc_private_key);

                // Проверяем подпись
                var isValid = crypto.verifyMessage(decryptedMessage, signature, contact_public_key);

                messageList.model.append({
                    content: isValid ? decryptedMessage : "[Неверная подпись]",
                    isSent: false,
                    senderAlias: "Контакт",
                    isError: !isValid
                });

                scrollTimer.restart();

                // Сохраняем в БД как входящее
                saveIncomingMessage(encryptedMessage, signature);

            } catch (e) {
                console.error("Ошибка получения сообщения:", e);
                console.error("Неудачный JSON:", message);
            }
        }
    }

    function saveIncomingMessage(encryptedMessage, signature) {
        dao.saveEncryptedMessage(chatId, encryptedMessage, signature, false);
    }

    function sendMessage() {
        if (messageInput.text.trim() === "") return;
        var messageText = messageInput.text;
        messageInput.text = "";

        var tempId = Date.now();
        messageList.model.append({
            content: messageText,
            isSent: true,
            senderAlias: "Вы",
            tempId: tempId,
            isPending: true
        });
        scrollTimer.restart();

        // Подписываем
        var signature = crypto.signMessage(messageText, user_private_key);
        var encryptedForContact = crypto.encryptMessage(messageText, contact_enc_public_key);
        var encryptedForSelf = crypto.encryptMessage(messageText, user_enc_public_key);

        var payload = {
            encrypted_message: encryptedForContact, // Base64-строка без кавычек!
            signature: signature
        };
        peers.sendMessage(contact_ip, contact_port, JSON.stringify(payload));

        saveMessageTimer.chatId = chatId;
        saveMessageTimer.encryptedMessage = encryptedForSelf;
        saveMessageTimer.signature = signature;
        saveMessageTimer.start();
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
                var decrypted = crypto.decryptMessage(msg.content, user_enc_private_key);
                var isValid = msg.is_sent ?
                    crypto.verifyMessage(decrypted, msg.signature, user_public_key) :
                    crypto.verifyMessage(decrypted, msg.signature, contact_public_key);

                messageList.model.append({
                    content: isValid ? decrypted : "[Неверная подпись]",
                    isSent: msg.is_sent,
                    senderAlias: msg.is_sent ? "Вы" : "Контакт",
                    isError: !isValid
                });
            } catch (e) {
                console.error("Ошибка расшифровки:", e);
                messageList.model.append({
                    content: "[Ошибка расшифровки]",
                    isSent: msg.is_sent,
                    senderAlias: msg.is_sent ? "Вы" : "Контакт",
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
    }

    Component.onDestruction: {
        disconnectFromMessageSignal();
    }
}
