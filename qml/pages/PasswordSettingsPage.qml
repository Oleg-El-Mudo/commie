import QtQuick 2.2
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import QtQuick.LocalStorage 2.0

//страница для настройки псевдонима
Page{
    objectName: "passwordSettingsPage"
    allowedOrientations: Orientation.All
    id:passwordSettingsPage
    // Создаём экземпляр dao для работы с SQLite
    Dao {
        id: dao
    }
    //верхнее меню приложения
    AppBar{
        //заголовок в шапке
        headerText: qsTr("Commie")
        //Подзаголовок в шапке
        subHeaderText: qsTr("Password Settings")
        id:header
        //есть разделитель
        divider: true
        //непрозрачная шапка
        background: true
    }
    //вертикальный контейней для выравнивания кнопок по центру
    Column{
        id:buttonsLab
        //ширина по странице
        width: passwordSettingsPage.width
        //высота по странице минус высота шапки
        height: passwordSettingsPage.height-header.height
        //сверху приклеивается к низу шапки
        anchors.top: header.bottom
        //контейнер, содержащий кнопки и лейбл
        Column{
            spacing: Theme.paddingLarge
            //начинается после шапки
            anchors.top: header.bottom
            //центруется в родителе
            anchors.centerIn: parent
            //текстовая метка-заголовок
            Label{
                text:qsTr("Set or change your password")
                //горизонтальное выравнивание по центру
                horizontalAlignment: "AlignHCenter"
                //горизоватлное выравание текста по центру
                anchors.horizontalCenter: parent.horizontalCenter
            }
            //текстовое поле для ввода псевдонима
            TextArea {
                id: passwordTextArea
                //текст с подсказкой, что вводить в поле
                placeholderText: qsTr("Enter password here")
                //горизонтальное выравнивание по центру
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
                enabled: passwordTextArea.text.length > 0
                //при клике по кнопке
                onClicked: {
                    //устанавливаем пароль пользователю в БД
                    var passwordRegex = /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+])[A-Za-z\d!@#$%^&*()_+]{15,}$/;
                    //проверка введённого пароля по выражению
                    var isValid = (passwordRegex.test(passwordTextArea.text));
                    //формирование сообщения о результатах проверки
                    var result = isValid ? "success" : "failure";
                    var auser = dao.getActiveUser();
                    if(isValid){
                        dao.setPassword(crypto.hashPassword(passwordTextArea.text));
                        //получаем активного пользователя
                        //показываем уведомление, что пароль установлен
                        Notices.show(qsTr("Password set"),
                                     //уведомление короткое
                                     Notice.Short,
                                     //снизу
                                     Notice.Bottom,
                                     0,
                                     //системные горизонтальные отступы
                                     -Theme.horizontalPageMargin)
                    }else{
                        //показываем уведомление, что пароль установлен
                        Notices.show(qsTr("Error"),
                                     //уведомление короткое
                                     Notice.Short,
                                     //снизу
                                     Notice.Bottom,
                                     0,
                                     //системные горизонтальные отступы
                                     -Theme.horizontalPageMargin)
                    }
                    passwordTextArea.text = "";
                }
            }
        }
    }
}
