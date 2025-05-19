import QtQuick 2.6
import Sailfish.Silica 1.0
import Aurora.Controls 1.0

//страница для отображения qr кода
Page {
    id: qrCodePage
    allowedOrientations: Orientation.All

    //параметр с изображением, сгенеренным на странице приглашений
    property string qrimage

    //шапка страницы
    AppBar {
        //заголовок
        headerText: qsTr("QR Code")
        //фон
        background: true
    }

    //картинка
    Image {
        id: qrImage
        //центрируется по родителю
        anchors.centerIn: parent

        //источник от страницы приглашений
        source: qrCodePage.qrimage
    }
}
