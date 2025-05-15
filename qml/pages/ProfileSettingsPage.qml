import QtQuick 2.2
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import QtQuick.LocalStorage 2.0

//страница настроек приложения
Page{
    objectName: "profileSettingsPage"
    //доступны все ориентации экрана
    allowedOrientations: Orientation.All
    id:settingsPage

    //параметры псевдонима и аватара
    property string your_alias
    property string your_avatar

    //объект dao для работы с бд
    Dao{
        id:dao
    }

    //верхнее меню приложения
    AppBar{
        //заголовок
        headerText: qsTr("Commie")
        //подзаголовок
        subHeaderText: qsTr("Profile Settings")
        id:header
        //разделитель
        divider: true
        //фон
        background: true

        //пустое пространство
        AppBarSpacer{}

        //кнопка в шапке
        AppBarButton {
            context: qsTr("Update")
            icon.source: "image://theme/icon-m-refresh"

            onClicked: {
                var auser = dao.getActiveUser();
                // Загружаем псевдоним независимо от аватара
                your_alias = auser.alias || qsTr("No alias set");

                // Всегда пытаемся загрузить аватар, даже если псевдонима нет
                your_avatar = dao.getAvatar(auser.id);
                console.log("Avatar after update:", your_avatar);
            }
        }
    }

    //столбец с информацией профиля
    Column{
        id: info_col
        //привязка сверху по низу шапке
        anchors.top: header.bottom
        //ширина по странице
        width: settingsPage.width
        //высота по картинке плюс псевдоним
        height: avatarImage.height+aliasLabel.height


        // Проверяем наличие аватара
        // Проверяем наличие аватара
        // Изображение с аватаром при наличии
        Image {
            id: avatarImage
            // Источник картинки - или аватар, или пустая строка
            source: your_avatar
            // Размеры 100x100
            width: 200
            height: 200
            // Видимость, если аватар присутствует
            visible: true
            fillMode: Image.PreserveAspectCrop
        }

        // Точка вместо аватара
        Rectangle {
            id: avatarPlaceholder
            // Синий цвет
            color: "#3D6BE3"
            // Размеры 100x100
            width: 200
            height: 200
            // Углы скошены до круга
            radius: width * 0.5
            // Видим, если аватар отсутствует
            visible: !your_avatar
        }

        // Проверяем наличие псевдонима
        Label {
            id: aliasLabel
            //если есть псевдоним, то выводим его
            //если нет, текст о том, что псевдонима нет
            text: your_alias ? your_alias : qsTr("No alias set")
            //привязка слева
            //если картинка есть, то слева от неё
            //если картинки нет, то слева от родителя
            anchors.left: avatarImage.visible ? avatarImage.right : avatarPlaceholder.right
            //вертикальное выравнивание по центру
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    //разделитель
    Separator {
        //ширина по странице
        width: parent.width
        //цвет системный светлый
        color: Theme.highlightColor
        //горизонтальное выравнивание по центру
        horizontalAlignment: Qt.AlignHCenter
    }


    //прокручиваемый элемент
    SilicaListView{
        //ширина по странице
        width:settingsPage.width
        //высота по странице минус высоту шапки и информации
        height: settingsPage.height-header.height-info_col.height
        id:slv
        //расстояние между элементами системное среднее
        spacing: Theme.paddingMedium
        //привязка сверху по низу информации
        anchors.top: info_col.bottom

        //модель списка
        model: ListModel{
            //элементы спика/пункты настроек

//ЗАМОРОЖЕНО

//            ListElement{
//                //Поменять установить аватар
//                settingsPunkt: qsTr("Set/change avatar")
//            }
            ListElement{
                //Поменять/установить псевдоним
                settingsPunkt: qsTr("Set/change alias")
            }
            ListElement{
                //Поменять пароль
                settingsPunkt: qsTr("Change password")
            }
        }
        //настройки пункта меню
        delegate: BackgroundItem{
            //высота 120
            height: Theme.dp(120)

            //текст
            Label{
                //отступ по иксу 16
                x:Theme.dp(16)
                //подставляются 3 элемента из модели
                text: settingsPunkt
                //вертикальное выравнивание по центру
                anchors.verticalCenter: parent.verticalCenter
            }

            //при нажатии вызова функции отслеживания нажатия по номеру пункта меню
            onClicked: {
                handleClick(index);
            }

            //функция отслеживания нажатия
            function handleClick(index) {
                switch (index) {
//                case 0:
//                    // код для нажатия на установки аватара
//                    pageStack.push(Qt.resolvedUrl("ProfileAvatarSettingsPage.qml"))
//                    break;
                case 0:
                    // код для нажатия на установки псевдонима
                    pageStack.push(Qt.resolvedUrl("AliasSettingsPage.qml"))
                    break;
                case 1:
                    // код для нажатия на смены пароля
                    pageStack.push(Qt.resolvedUrl("PasswordSettingsPage.qml"))
                    break;
                }
            }
        }
    }
    //при загрузке страницы
    Component.onCompleted: {
        var auser = dao.getActiveUser();
        your_alias = auser.alias || qsTr("No alias set");
        your_avatar = dao.getAvatar(auser.id);
    }
}
