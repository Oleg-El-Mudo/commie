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
    property string contact_public_key
    property string contact_enc_public_key
    property string contact_ip
    property int contact_port
    property bool isLocalChat: false


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
        subHeaderText: qsTr("Личный чат")
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
                        color: Theme.primaryColor

                        Label {
                            anchors.centerIn: parent
                            text: "?"
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
                            text: chatTitle || qsTr("Неизвестный")
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.paddingSmall

                            // Если отправляется текст
                            Label {
                                text: model.content
                                color: model.isError ? Theme.errorColor : Theme.primaryColor
                                font.pixelSize: Theme.fontSizeMedium
                                width: parent.width - (model.isPending ? Theme.iconSizeSmall : 0)
                                wrapMode: Text.Wrap
                            }

                            // Индикатор состояния
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

            // 2. Поле ввода
            TextField {
                id: messageInput
                width: parent.width - sendButton.width - 2*Theme.paddingSmall
                placeholderText: qsTr("Сообщение...")
                EnterKey.onClicked: sendMessage()
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            }

            // 3. Кнопка отправки
            IconButton {
                id: sendButton
                icon.source: "image://theme/icon-m-send"
                onClicked: sendMessage()
            }
        }
    }

    //функция отправки сообщений
    function sendMessage() {

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

                success = true;

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

    function loadMessages() {
        messageList.model.clear();
        var currentUser = dao.getActiveUser();

        // Загружаем сообщения из базы данных
        var messages;

        messages.forEach(function(msg) {
            var content = msg.content || "";

            // Добавляем данные в модель
            messageList.model.append({

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


    Component.onCompleted: {
        loadMessages();
    }
}
