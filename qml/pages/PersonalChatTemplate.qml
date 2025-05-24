import QtQuick 2.0
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import Sailfish.Pickers 1.0

Page {
    id: personalChatPage
    allowedOrientations: Orientation.All

    // Свойства, переданные при открытии страницы
    property string chatId
    property int user_id
    property int contact_id
    property string chatTitle
    property string user_public_key
    property string user_private_key
    property string user_enc_public_key
    property string contact_public_key
    property string contact_enc_public_key
    property string contact_ip
    property int contact_port
    property bool isLocalChat: false

    Dao { id: dao }

    // === UI ===
    AppBar {
        id: header
        width: parent.width
        divider: true
        background: true
        headerText: chatTitle
        subHeaderText: qsTr("Личный чат")
    }

    SilicaFlickable {
        id: flickable
        anchors.top: header.bottom
        anchors.bottom: inputArea.top
        anchors.left: parent.left
        anchors.right: parent.right

        SilicaListView {
            id: messageList
            width: parent.width
            height: childrenRect.height
            interactive: false

            model: ListModel {} // <-- будет наполняться динамически

            delegate: BackgroundItem {
                Row {
                    spacing: Theme.paddingMedium
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin

                    Rectangle {
                        width: Theme.iconSizeMedium
                        height: Theme.iconSizeMedium
                        radius: width / 2
                        color: model.isSent ? "#00AEEF" : "#3D6BE3"

                        Label {
                            anchors.centerIn: parent
                            text: model.isSent ? "Вы" : (contactTitle.text[0] || "?")
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    Column {
                        width: parent.width - Theme.iconSizeMedium - Theme.paddingMedium
                        spacing: Theme.paddingSmall

                        Label {
                            text: model.isSent ? "Вы" : chatTitle
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Label {
                            text: model.content
                            color: Theme.primaryColor
                            font.pixelSize: Theme.fontSizeMedium
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            VerticalScrollDecorator { flickable: parent.parent }
        }
    }

    // === Панель ввода ===
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
                width: parent.width - sendButton.width - 2 * Theme.paddingSmall
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

    Timer {
        id: scrollTimer
        interval: 0
        onTriggered: {
            console.log("Прокрутка активирована");
            flickable.contentY = flickable.contentHeight - flickable.height;
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

        console.log("Получено:", normalizedIp, port, message);
        console.log("Целевой контакт:", normalizedContactIp, contact_port);

        if (normalizedIp === normalizedContactIp) {
            messageList.model.append({
                                         content: message,
                                         isSent: false
                                     });
            scrollTimer.restart();
        }
    }

    function sendMessage() {
        var text = messageInput.text.trim();
        if (!text) return;

        messageList.model.append({
                                     content: text,
                                     isSent: true
                                 });

        messageInput.text = "";
        scrollTimer.restart();

        peers.sendMessage(contact_ip, contact_port, text);
    }

    Component.onCompleted: {
        console.log("contact_ip:", contact_ip);
        console.log("contact_port:", contact_port);
        console.log("Тип модели:", typeof messageList.model);
        console.log("Количество элементов:", messageList.model.count);

        connectToMessageSignal();
        messageList.model.countChanged.connect(function() {
            flickable.contentY = flickable.contentHeight - flickable.height;
        });
    }

    Component.onDestruction: {
        disconnectFromMessageSignal();
    }
}
