import QtQuick 2.6
import QtMultimedia 5.6
import Sailfish.Silica 1.0
import Amber.QrFilter 1.0
import Aurora.Controls 1.0
import QtQuick.LocalStorage 2.0

Page {
    objectName: "recognitionPage"

    //при изменении видимости (страница открылась/закрылась)
    onVisibleChanged: {
        //если страница стала видима
        if (visible) {
            //перезагружаем ПОЛОТНО
            blackout.requestPaint();
        }
    }

    //объект dao для работы с БД
    Dao{
        id:dao
    }

    //функция для подтверждения ссылки qr кода
    function acceptQRLink(){
        //получаем ссылку из кода
        var link = qrFilter.result;
        //из ссылки вытягиваем логин, ключ, айпи, порт, псевдоним, аватар соответственно
        var login = friends.getLoginFromParsedLink(link);
        var publicKey = friends.getPublicKeyFromParsedLink(link);
        var ip = friends.getIpFromParsedLink(link);
        var port = friends.getPortFromParsedLink(link);
        var alias = friends.getAliasFromParsedLink(link);
        var avatar = friends.getAvatarFromParsedLink(link);
        var encPublicKey = friends.getEncPublicKeyFromParsedLink(link);
        //получаем активного пользователя
        var auser = dao.getActiveUser();

        //получаем контакты активного пользователя
        var contacts = dao.getContacts();
        //изначально принимаем, что такого аккаунта ещё не было
        var contactExists = false;
        //проход по всем контактам пользователя
        for (var i = 0; i < contacts.length; i++) {
            //если есть контакт с таким публичным ключом
            if (contacts[i].public_key === publicKey) {
                //отмечаем, что такой контак уже есть и выходим из цикла
                contactExists = true;
                break;
            }
        }

        //если такой контакт уже существует
        if (contactExists) {
            //обновляем его данные
            dao.updateContact(login, ip, port, alias, avatar, auser.id, publicKey, encPublicKey);
        //иначе
        } else {
            //добавляем новый контакт текующему пользователю

            //МОНУМЕНТ КОСТЫЛЮ
            //аватарка добавляется при обновлении контакта, но не при добавлении контакта

            //поэтому я делаю пустой аватар
            var empty_avatar = ""
            //добавляю пользователя без аватарки
            dao.insertContact(auser.id, login, publicKey, ip, port, alias, empty_avatar, encPublicKey);
            //потом обновляю этого пользователя с аватаркой
            dao.updateContact(login, ip, port, alias, avatar, auser.id, publicKey, encPublicKey);
        }

        //выводим уведомление о том, что контакт добавлен или обновлён
        Notices.show(qsTr("Contact added/updated"),
                     //короткое
                     Notice.Short,
                     //снизу
                     Notice.Bottom,
                     0,
                     //отступы системные горизонтальные
                     -Theme.horizontalPageMargin)
    }


    //верхнее меню приложения
    AppBar{
        //заголовок
        headerText: qsTr("Commie")
        //подзаголовок
        subHeaderText: qsTr("QR Reader")
        id:header
        //разделитель
        divider: true
        //фон
        background: true
    }

    //объект считывателя кода
    QrFilter {
        id: qrFilter

        objectName: "qrFilter"
        //активный (работает, в отличие от некоторых)
        active: true
    }

    //окно, в котором происходит сканирование
    VideoOutput {
        id: viewer

        objectName: "viewer"
        //привязка по родителю, отсекается шапка и нижняя кнопка для снимка
        anchors {
            top: pageHeader.bottom
            left: parent.left
            right: parent.right
            bottom: shootButton.top
            bottomMargin: Theme.horizontalPageMargin
        }
        //заполняется с сохранением пропорций
        fillMode: VideoOutput.PreserveAspectFit
        //источник - камера в режиме видео
        source: Camera {
            captureMode: Camera.CaptureVideo
            focus {
                //настройки фокуса камеры
                focusMode: CameraFocus.FocusContinuous
                focusPointMode: CameraFocus.FocusPointAuto
            }
        }
        //камера обрабатывает поток через qr фильтр
        filters: [qrFilter]
    }

    //прямоугольник для отделения границ фильтра (ни черта не работает - переделать)
    Rectangle {
        id: captureRect
        objectName: "captureRect"

        //привязка по центру видео входа
        anchors.centerIn: viewer
        //ширина и высота как 70% от минимальной стороны видео
        width: Math.min(viewer.width, viewer.height) * 0.7
        height: width
        //прозрачный цвет
        color: "transparent"

        //при загрузке страницы должны отрисовываться кресты (на карьере)
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

    //ПОЛОТНО
    Canvas {
        id: blackout
        objectName: "blackout"

        //заполняется по центру
        anchors.fill: parent

        //должно затемняться пространство за пределами фильтра
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

    //кнопка для съемки
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

    //кадр
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
