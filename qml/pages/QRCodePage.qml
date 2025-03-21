import QtQuick 2.6
import Sailfish.Silica 1.0
import Aurora.Controls 1.0

Page {
    id: qrCodePage

    property string qrimage

    AppBar {
        headerText: qsTr("QR Code")
        background: true
    }

    Image {
        id: qrImage
        anchors.centerIn: parent

        source: qrCodePage.qrimage
    }
}
