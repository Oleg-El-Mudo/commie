import QtQuick 2.6
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import Amber.QrFilter 1.0
import QtQuick.LocalStorage 2.0

//страница для работы с пригласительными ссылками
Page{
    objectName: "invitePage"
    //доступны все ориентации экрана (на всякий случай осуждаю)
    allowedOrientations: Orientation.All
    id:invitePage

    //объект для работы с БД
    Dao{
        id:dao
    }

    function genLink(){
        //получаем айпи и порт
        var ip = peers.getCurrentIpAddress();
        var port = peers.getCurrentPort();
        //обновляем айпи и порт в БД
        dao.updateIpAndPort(ip, port);
        console.log("Порт при генерации ссылки:");
        console.log(port);
        //получаем активного пользователя
        var auser = dao.getActiveUser();

        //генерируем ссылку-приглашение
        var link = friends.generateInviteLink(auser.login, auser.public_key, auser.ip, auser.port, auser.alias, auser.avatar, auser.enc_public_key);
        console.log("Ключ для шифрования:");
        console.log(auser.enc_public_key);
        //вставляем ссылку в поле на странице
        linkTextArea.text = link;

        //возвращаем ссылку
        return link;
    }

    //функция для подтверждения ссылки
    function acceptLink() {
        //получаем текст ссылки из поля
        var link = inviteLinkTextArea.text;
        //получаем логин из ссылки
        var login = friends.getLoginFromParsedLink(link);
        //получаем публичный ключ из ссылки
        var publicKey = friends.getPublicKeyFromParsedLink(link);
        //получаем айпи из ссылки
        var ip = friends.getIpFromParsedLink(link);
        //получаем порт из ссылки
        var port = friends.getPortFromParsedLink(link);
        //получаем псевдоним из ссылки
        var alias = friends.getAliasFromParsedLink(link);
        //получаем аватар из ссылки
        var avatar = friends.getAvatarFromParsedLink(link);
        var encPublicKey = friends.getEncPublicKeyFromParsedLink(link);
        //получаем активного пользователя из ссылки
        var auser = dao.getActiveUser();

        console.log("ПОРТ ИЗ ССЫЛКИ: ");
        console.log(port);
        console.log("Ключ: ");
        console.log(encPublicKey);

        //получаем список контактов активного пользователя
        var contacts = dao.getContacts();
        //узнаем, был ли уже у пользователя такой контакт
        //по умолчанию - не был
        var contactExists = false;
        //проход по всем контактам активного пользователя
        for (var i = 0; i < contacts.length; i++) {
            //если совпадает публичный ключ
            if (contacts[i].public_key === publicKey) {
                //контакт найден
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

        //очищаем поле с введённой ссылкой
        inviteLinkTextArea.text = "";
        //выводим уведомление, что контакт был добавлен
        Notices.show(qsTr("Contact added"),
                     //короткое
                     Notice.Short,
                     //снизу
                     Notice.Bottom,
                     0,
                     //горизонтальные системные отступы
                     -Theme.horizontalPageMargin)
    }

    //функция для генерации QR кода по пригласительной ссылке
    function createQRCode() {
        //размеры 500*500
        qrCode.width = 500;
        qrCode.height = 500;
        //оступы по 15
        qrCode.margin = 15;
        //генерируем ссылку
        genLink();
        //передаем ссылку из поля в код
        qrCode.text = linkTextArea.text
        //обновляем qr код
        qrCode.update();
    }

    //объект qr кода
    QrCode {
        id: qrCode

        //когда код сгенерировался
        onGenerationFinished: {
            //помещаем на вершину стека страницу с этим qr кодом
            pageStack.push(Qt.resolvedUrl("QRCodePage.qml"),{ qrimage: qrCode.image});
        }
    }

    //прокручиваемый элемент страницы
    SilicaFlickable{
        id:inviteFlick
        //заполнение по родителю
        anchors.fill: parent
        //высота по родителю
        contentHeight: parent.height
        //верхнее меню приложения
        AppBar{
            //заголовок шапки
            headerText: qsTr("Commie")
            //подзаголовок шапки
            subHeaderText: qsTr("Safe messenger")
            id:header
            //разделитель
            divider: true
            //фон
            background: true
        }
        //меню, вытягиваемое сверху вниз
        PullDownMenu{
            //отступ сверху на высоту шапки
            topMargin: header.height
            //элемент меню "Персональные чаты"
            MenuItem {
                text: qsTr("Personal Chats")
                //при клике
                onClicked: {
                    //меняем вершину стека на страницу персональных чатов
                    pageStack.replace(Qt.resolvedUrl("PersonalChatsPage.qml"))
                }
            }
            //элемент меню "Контакты"
            MenuItem {
                text: qsTr("Contacts")
                //при клике
                onClicked: {
                    //меняем вершину стека на страницу контактов
                    pageStack.replace(Qt.resolvedUrl("Contacts.qml"))
                }
            }
            //элемент меню "Настройки"
            MenuItem {
                text: qsTr("Settings")
                //при клике
                onClicked: {
                    //помещаем на вершину стека страницу настроек
                    pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
                }
            }
            //элемент меню "Выход"
            MenuItem {
                text: qsTr("Exit")
                //при клике
                onClicked: {
                    //деактивация пользователя
                    dao.deActivate();
                    //удаляем все страницы из стека до главной
                    pageStack.replaceAbove(null, Qt.resolvedUrl("MainPage.qml"))
                }
            }
            //подпись меню
            MenuLabel{
                text: qsTr("Commie")
            }
        }
        //вертикальный контейней для выравнивания кнопок по центру
        Column{
            id:buttonsLab
            //ширина по странице
            width: invitePage.width
            //высота по странице минус шапка
            height: invitePage.height-header.height
            //привязка сверху по низу шапки
            anchors.top: header.bottom
            //контейнер, содержащий кнопки и лейбл
            Column{
                //большие системные остступы между элементами в столбце
                spacing: Theme.paddingLarge
                //привязка сверху по низу шапки
                anchors.top: header.bottom
                //центрируем в родителе
                anchors.centerIn: parent
                //текстовая метка-заголовок
                Label{
                    text:qsTr("Generate invite-link")
                    //горизонтальное выравнивание по центру
                    horizontalAlignment: "AlignHCenter"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                //кнопка для генерации пригласительной ссылки
                Button {
                    id: genButton
                    text: qsTr("Generate")
                    //горизонтальное выравнивание по центру
                    anchors.horizontalCenter: parent.horizontalCenter
                    //большая системная ширина кнопки
                    width: Theme.buttonWidthLarge
                    //при клике
                    onClicked: {
                        //сгенерировать ссылку
                        genLink();
                    }
                }
                //текстовое поле для ссылки, по умолчанию пустое
                TextArea {
                    id: linkTextArea
                    text: ""
                    //только для чтения
                    readOnly: true
                    //текст не переносится
                    wrapMode: Text.NoWrap
                    //выравнивание по горизонтали по центру
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    //ширина по родителю
                    width: parent.width
                }
                //кнопка для копированя ссылки
                Button{
                    id: copyButton
                    text: qsTr("Copy")
                    //системная большая ширина кнопки
                    width: Theme.buttonWidthLarge
                    //выраванивание по центру по горизонтали
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        //при нажатии на кнопку значение текстового поля передаётся в буфер обмена
                        Clipboard.text=linkTextArea.text;
                    }
                }
                //кнопка для генерации кода
                Button {
                    id: genQRButton
                    text: qsTr("Generate QR")
                    //выравнивание по горизонтали по центру
                    anchors.horizontalCenter: parent.horizontalCenter
                    //системная большая ширина кнопки
                    width: Theme.buttonWidthLarge
                    //при клике
                    onClicked: {
                        //создать qr код
                        createQRCode();
                    }
                }

                //текстовое поле для ввода чужой ссылки-приглашения
                TextArea {
                    id: inviteLinkTextArea
                    //текст подсказки для поля
                    placeholderText: qsTr("Enter invite link here")
                    //выравнивание по центру
                    anchors.horizontalCenter: parent.horizontalCenter
                    //текст не переносится
                    wrapMode: Text.NoWrap
                }
                //кнопка для принятия и парсинга ссылки
                Button {
                    id: acceptButton
                    text: qsTr("Accept")
                    //горизонтальное выравнивание по центру
                    anchors.horizontalCenter: parent.horizontalCenter
                    //системная большая ширина кнопки
                    width: Theme.buttonWidthLarge
                    //при клике
                    onClicked: {
                        //подтверждение ссылки
                        acceptLink();
                    }
                }
                //кнопка для перехода на сканирование qr
                Button {
                    id: scanQRButton
                    text: qsTr("Scan QR")
                    //горизонтальное выравнивание по центру
                    anchors.horizontalCenter: parent.horizontalCenter
                    //ширина системная большая
                    width: Theme.buttonWidthLarge
                    //при клике
                    onClicked: {
                        //помещаем на вершину стека страницу с сканером qr
                        pageStack.push(Qt.resolvedUrl("QRReaderPage.qml"));
                    }
                }
            }
        }
        //вертикальная линия прокрутки
        VerticalScrollDecorator {flickable: inviteFlick}
    }
}
