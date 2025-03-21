import QtQuick 2.2
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import QtQuick.LocalStorage 2.0

//страница для настройки псевдонима
Page{
    objectName: "aliasSettingsPage"
    allowedOrientations: Orientation.All
    id:aliaSsettingsPage
    // Создаём экземпляр dao для работы с SQLite
    Dao {
        id: dao
    }
    //верхнее меню приложения
    AppBar{
        //заголовок в шапке
        headerText: qsTr("Commie")
        //Подзаголовок в шапке
        subHeaderText: qsTr("Alias Settings")
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
        width: aliaSsettingsPage.width
        //высота по странице минус высота шапки
        height: aliaSsettingsPage.height-header.height
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
                text:qsTr("Set or change your alias")
                //горизонтальное выравнивание по центру
                horizontalAlignment: "AlignHCenter"
                //горизоватлное выравание текста по центру
                anchors.horizontalCenter: parent.horizontalCenter
            }
            //текстовое поле для ввода псевдонима
            TextArea {
                id: aliasTextArea
                //текст с подсказкой, что вводить в поле
                placeholderText: qsTr("Enter alias here")
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
                //при клике по кнопке
                onClicked: {
                    //устанавливаем псевдоним пользователю в БД
                    dao.setAlias(aliasTextArea.text);
                    //получаем активного пользователя
                    var auser = dao.getActiveUser();
                    //показываем уведомление, что псевдоним установлен
                    Notices.show(qsTr("Alias set"),
                                 //уведомление короткое
                                 Notice.Short,
                                 //снизу
                                 Notice.Bottom,
                                 0,
                                 //системные горизонтальные отступы
                                 -Theme.horizontalPageMargin)
                }
            }
        }
    }
}
