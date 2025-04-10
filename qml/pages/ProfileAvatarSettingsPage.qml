import QtQuick 2.2
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import Sailfish.Pickers 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: page
    allowedOrientations: Orientation.All

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

    // Canvas будет рендерить УЖЕ ОБРЕЗАННОЕ изображение
    Canvas {
        id: converterCanvas
        visible: false
        width: cropContainer.width
        height: cropContainer.height

        property var callback: null

        onPaint: {
            var ctx = getContext("2d")
            ctx.drawImage(sourceImage, 0, 0, width, height)
            if (callback) {
                callback(converterCanvas.toDataURL("image/png"))
            }
        }

        function toBase64(cb) {
            callback = cb
            requestPaint()
        }
    }

    AppBar {
        id: header
        headerText: qsTr("Commie")
        subHeaderText: qsTr("Avatar Settings")
        divider: true
        background: true
    }

    Column {
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Column {
            width: parent.width
            spacing: Theme.paddingLarge
            anchors.centerIn: parent

            Label {
                text: qsTr("Set or change your avatar")
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Button {
                text: qsTr("Select image")
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.buttonWidthLarge
                onClicked: pageStack.push(imagePickerPage)
            }

            // ПРЕДПРОСМОТР (теперь просто отображает cropContainer)
            Rectangle {
                width: 200
                height: 200
                color: "transparent"
                clip: true

                Image {
                    anchors.fill: parent
                    source: sourceImage.source
                    fillMode: Image.PreserveAspectCrop
                }
            }

            Button {
                id: acceptButton
                text: qsTr("Accept")
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.buttonWidthLarge
                enabled: sourceImage.source.toString() !== ""

                onClicked: {
                    converterCanvas.toBase64(function(base64) {
                        var auser = dao.getActiveUser()
                        dao.updateAvatar(auser.id, base64)
                        Notices.show(qsTr("Avatar updated"), Notice.Short, Notice.Bottom)
                    })
                }
            }
        }
    }

    Component {
        id: imagePickerPage
        ImagePickerPage {
            onSelectedContentPropertiesChanged: {
                var filePath = selectedContentProperties.filePath
                sourceImage.source = filePath.indexOf("file://") === 0 ? filePath : "file://" + filePath
            }
        }
    }
}
