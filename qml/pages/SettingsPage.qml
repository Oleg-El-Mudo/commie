import QtQuick 2.2
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import QtQuick.LocalStorage 2.0

//страница настроек
Page{
    objectName: "settingsPage"
    //допустимы все ориентации экрана
    allowedOrientations: Orientation.All
    id:settingsPage

    // Создаём экземпляр dao для работы с SQLite
    Dao {
        id: dao
    }

    //прокручиваемый элемент
    SilicaFlickable{
        id:chatsList
        //заполнение внутри родителя
        anchors.fill: parent
        //высота содержимого по родителя
        contentHeight: parent.height
        //верхнее меню приложения
        AppBar{
            //заголовок
            headerText: qsTr("Commie")
            //подзаголовок
            subHeaderText: qsTr("Settings")
            id:header
            //разделитель
            divider: true
            //фон
            background: true
        }

        //меню, вытягиваемое сверху вниз
        PullDownMenu{
            topMargin: chatsList.height

            //элемент меню с избранным
            MenuItem {
                text: qsTr("Favorite")
                //при клике
                onClicked: {
                    var currentUser = dao.getActiveUser();
                    pageStack.push(Qt.resolvedUrl("ChatTemplate.qml"), {
                                       "chatId": "favorites_" + currentUser.id,
                                       "chatType": 3, //3 - тип чата - избранное
                                       "chatTitle": qsTr("Избранное"),
                                       "isLocalChat": true
                                   });
                }
            }

            //элемент меню с контактами
            MenuItem {
                text: qsTr("Contacts")
                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("Contacts.qml"))
                }
            }

            //элемент меню с приглашениями
            MenuItem {
                text: qsTr("Invites")
                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("InvitePage.qml"))
                }
            }

            //элемент меню с выходом
            MenuItem {
                text: qsTr("Exit")
                onClicked: {
                    //деактивируем пользователей
                    dao.deActivate();
                    //выкидываем из стека все страницы до главной
                    pageStack.replaceAbove(null, Qt.resolvedUrl("MainPage.qml"))
                }
            }

            //подпись меню
            MenuLabel{
                text: qsTr("Commie")
            }
        }
        //прокручиваемый элемент
        SilicaListView{
            //ширина по странице
            width:settingsPage.width
            //высота по странице минус высота шапки
            height: settingsPage.height-header.height
            id:slv
            //средние отступы между элементами списка
            spacing: Theme.paddingMedium
            //привязка сверху по низу шапки
            anchors.top: header.bottom

            //модель спика
            model: ListModel{
                //элементы списка
                ListElement{
                    //пункт меню с настройками профиля
                    settingsPunkt: qsTr("Profile")
                }
                ListElement{
                    //пункт меню о проекте
                    settingsPunkt: qsTr("About Project")
                }
                ListElement{
                    //пункт меню для удаления профиля
                    settingsPunkt: qsTr("Delete all accounts")
                }
            }
            //описание шаблона элемента
            delegate: BackgroundItem{
                //высота 120
                height: Theme.dp(120)

                //метка
                Label{
                    //смещение по иксу на 16
                    x:Theme.dp(16)
                    text: settingsPunkt
                    //выраванивание по вертикали по центру
                    anchors.verticalCenter: parent.verticalCenter
                }

                //при клике
                onClicked: {
                    //отслеживаем, на какой из пунктов меню было нажато
                    handleClick(index);
                }

                //функция для отслеживания нажатия на пункт меню
                function handleClick(index) {
                    switch (index) {
                    case 0:
                        // код для нажатия на "Profile"
                        pageStack.push(Qt.resolvedUrl("ProfileSettingsPage.qml"))
                        break;
                    case 1:
                        // код для нажатия на "About Project"
                        pageStack.push(Qt.resolvedUrl("AboutProjectPage.qml"))
                        break;
                    case 2:
                        // код для нажатия на "Delete account"
                        dao.deleteAllUsers();
                        dao.deleteAllContacts();
                        Notices.show("Данные аккаунтов удалены",
                                     Notice.Short,
                                     Notice.Bottom,
                                     0,
                                     -Theme.horizontalPageMargin)
                        //возвращаемя до главной страницы
                        pageStack.replaceAbove(null, Qt.resolvedUrl("MainPage.qml"));
                        break;
                    }
                }
            }
        }
    }
}
