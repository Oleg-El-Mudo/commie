import QtQuick 2.6
import QtMultimedia 5.6
import Sailfish.Silica 1.0
import Amber.QrFilter 1.0
import Aurora.Controls 1.0
import QtQuick.LocalStorage 2.0

Page {
    objectName: "recognitionPage"

    onVisibleChanged: {
        if (visible) {
            blackout.requestPaint(); // reload canvas
        }
    }

    Dao{
        id:dao
    }

    function acceptQRLink(){
        var link = qrFilter.result;
        var login = friends.getLoginFromParsedLink(link);
        var publicKey = friends.getPublicKeyFromParsedLink(link);
        var ip = friends.getIpFromParsedLink(link);
        var port = friends.getPortFromParsedLink(link);
        var alias = friends.getAliasFromParsedLink(link);
        var avatar = friends.getAvatarFromParsedLink(link);
        var auser = dao.getActiveUser();

        var contacts = dao.getContacts();
        var contactExists = false;
        for (var i = 0; i < contacts.length; i++) {
            if (contacts[i].public_key === publicKey) {
                contactExists = true;
                break;
            }
        }

        if (contactExists) {
            dao.updateContact(login, ip, port, alias, avatar, auser.id, publicKey);
        } else {
            dao.insertContact(auser.id, login, publicKey, ip, port, alias, avatar);
        }

        Notices.show(qsTr("Contact added/updated"),
                     Notice.Short,
                     Notice.Bottom,
                     0,
                     -Theme.horizontalPageMargin)
    }


    //верхнее меню приложения
    AppBar{
        headerText: qsTr("Commie")
        subHeaderText: qsTr("QR Reader")
        id:header
        divider: true
        background: true
    }

    QrFilter {
        id: qrFilter

        objectName: "qrFilter"
        active: true
    }

    VideoOutput {
        id: viewer

        objectName: "viewer"
        anchors {
            top: pageHeader.bottom
            left: parent.left
            right: parent.right
            bottom: shootButton.top
            bottomMargin: Theme.horizontalPageMargin
        }
        fillMode: VideoOutput.PreserveAspectFit
        source: Camera {
            captureMode: Camera.CaptureVideo
            focus {
                focusMode: CameraFocus.FocusContinuous
                focusPointMode: CameraFocus.FocusPointAuto
            }
        }
        filters: [qrFilter]
    }

    Rectangle {
        id: captureRect
        objectName: "captureRect"

        anchors.centerIn: viewer
        width: Math.min(viewer.width, viewer.height) * 0.7
        height: width
        color: "transparent"

        Component.onCompleted: {
            frame.createObject(captureRect, {
                    "x": 0,
                    "y": 0
                });
            frame.createObject(captureRect, {
                    "x": captureRect.width,
                    "y": 0,
                    "rotation": 90
                });
            frame.createObject(captureRect, {
                    "x": captureRect.width,
                    "y": captureRect.height,
                    "rotation": 180
                });
            frame.createObject(captureRect, {
                    "x": 0,
                    "y": captureRect.height,
                    "rotation": -90
                });
        }
    }

    Canvas {
        id: blackout
        objectName: "blackout"

        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.fillStyle = Theme.rgba(Theme.overlayBackgroundColor, Theme.opacityHigh);
            ctx.beginPath();
            ctx.fillRect(viewer.x, viewer.y, viewer.width, viewer.height);
            ctx.closePath();
            ctx.fill();
            ctx.clearRect(captureRect.x, captureRect.y, captureRect.width, captureRect.height);
        }
    }

    Button {
        id: shootButton

        objectName: "shootButton"
        text: qsTr("Add contact")
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: Theme.horizontalPageMargin
        }
        enabled: qrFilter.result.length !== 0

        onClicked: {
            acceptQRLink();
            pageStack.pop();
            qrFilter.clearResult();
        }
    }

    Component {
        id: frame

        Item {
            Rectangle {
                id: verticalRect
                objectName: "verticalRect"

                anchors {
                    top: parent.top
                    left: parent.left
                }

                width: captureRect.width / 30
                height: captureRect.height / 6
                color: shootButton.enabled ? palette.primaryColor : Theme.rgba(Theme.secondaryColor, Theme.opacityLow)
            }

            Rectangle {
                objectName: "horizontalRect"

                anchors {
                    top: parent.top
                    left: verticalRect.right
                }

                width: captureRect.width / 6 - verticalRect.width
                height: captureRect.height / 30
                color: shootButton.enabled ? palette.primaryColor : Theme.rgba(Theme.secondaryColor, Theme.opacityLow)
            }
        }
    }
}
