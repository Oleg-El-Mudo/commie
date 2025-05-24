import QtQuick 2.2
import Sailfish.Silica 1.0
import Aurora.Controls 1.0

//страница для работы со списком контактов
Page{
    objectName: "contactsPage"
    allowedOrientations: Orientation.All
    id:contactsPage
    //объект dao для работы с БД
    Dao{
        id:dao
    }
    //js функция для обновления списка по БД
    function updateList(){
        //получение активного пользователя
        var auser = dao.getActiveUser();
        //получения списка контактов, добавленных активным пользователем
        var contacts = dao.getContactByUserID(auser.id);
        //очистка модели списка контактов
        listView.model.clear();
        //проход по всем контактам активного пользователя
        for (var i = 0; i < contacts.length; i++) {
            //добавление в модель списка контактов: логин, псевдоним и аватар"
            listView.model.append({
                                      "login": contacts[i].login,
                                      "contactId": contacts[i].id,
                                      "alias": contacts[i].alias,
                                      "avatar": contacts[i].avatar,
                                      "public_key": contacts[i].public_key,
                                      "ip": contacts[i].ip,
                                      "port": contacts[i].port,
                                      "enc_public_key": contacts[i].enc_public_key
                                  });
        }
    }
    function openChat(contactId) {
        var activeUser = dao.getActiveUser();
        if (!activeUser) {
            console.error("Нет активного пользователя");
            return;
        }


        // Получаем или создаём личный чат
        var chat = dao.getOrCreatePersonalChat(activeUser.id, contactId);

        // Получаем данные пользователя и контакта
        var user = dao.getUserById(activeUser.id);
        var contact = dao.getContactById(contactId);

        // Формируем заголовок чата
        var chatTitle = contact.alias ? contact.alias : contact.login;

        // Переходим на страницу переписки
        pageStack.push(Qt.resolvedUrl("PersonalChatTemplate.qml"), {
            chatId: chat.id,
            user_id: user.id,
            contact_id: contact.id,
            chatTitle: chatTitle,

            // Ключи пользователя
            user_public_key: user.public_key,
            user_private_key: user.private_key,
            user_enc_public_key: user.enc_public_key,
            user_enc_private_key: user.enc_private_key,

            // IP и порт собеседника
            contact_ip: contact.ip,
            contact_port: contact.port,

            contact_public_key: contact.public_key,
            contact_enc_public_key: contact.enc_public_key,

            isLocalChat: false
        });
    }
    //прокручиваемый элемент страницы
    SilicaFlickable{
        id:chatsList
        //заполнение по родителю
        anchors.fill: parent
        //высота по родителю
        contentHeight: parent.height
        //шапка страницы
        AppBar{
            id:contsBar
            //разделитель
            divider: true
            //фон
            background: true
            //пустой подзаголовок
            subHeaderText: qsTr("")
            //пустое пространство
            AppBarSpacer{}
            //заголовок
            headerText: qsTr("Contacts")
            //пустое пространство
            AppBarSpacer{}
            //поисковое поле в шапке страницы
            AppBarSearchField{
                id: searchF
                //при нажатии на enter
                EnterKey.onClicked: {
                    //получаем активного пользователя
                    var auser = dao.getActiveUser();
                    //получаем список контактов активного пользователя
                    var contacts = dao.getContactByUserID(auser.id);
                    //сохраняем поисковой запрос
                    var searchText = searchF.text.toLowerCase();
                    //если введён пустой запрос
                    if(searchText===""){
                        //обновить список
                        updateList();
                        //иначе
                    }else{
                        //очищаем модель списка
                        listView.model.clear();
                        //проход по всем контактам активного пользователя
                        for (var i = 0; i < contacts.length; i++) {
                            //получаем логин контакта в нижнем регистре
                            var login = contacts[i].login.toLowerCase();
                            //получаем псевдоним контакта в нижнем регистре
                            var aliias = contacts[i].alias.toLowerCase();

                            //если логин совпадает с поисковым запросом
                            //или псевдоним совпадает с поисковым запросом
                            if (login===searchText || aliias===searchText) {
                                //к модели списка присоединяем логин, псевдоним и пароль
                                listView.model.append({
                                                          "login": contacts[i].login,
                                                          "contactId": contacts[i].id,
                                                          "alias": contacts[i].alias,
                                                          "avatar": contacts[i].avatar,
                                                          "public_key": contacts[i].public_key,
                                                          "ip": contacts[i].ip,
                                                          "port": contacts[i].port,
                                                          "enc_public_key": contacts[i].enc_public_key
                                                      });
                            }
                        }
                    }
                }
            }
            //кнопка в шапке страницы
            AppBarButton{
                context: qsTr("Update")
                //иконка "обновить"
                icon.source: "image://theme/icon-m-refresh"
                //при клике
                onClicked: {
                    //обновить список
                    updateList();
                }
            }
        }
        //меню, вытягиваемое сверху вниз
        PullDownMenu{
            //оступ сверху на высоту шапки страницы
            topMargin: contsBar.height
            //элемент меню "Персональные чаты"
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
            //элемент меню "Приглашения"
            MenuItem {
                text: qsTr("Invites")
                //при клике
                onClicked: {
                    //замена верхнего элемента стека страниц на приглашения
                    pageStack.replace(Qt.resolvedUrl("InvitePage.qml"))
                }
            }
            //элемент меню "Настройки
            MenuItem {
                text: qsTr("Settings")
                //при клике
                onClicked: {
                    //замена верхнего элемента стека страниц на настройки
                    pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
                }
            }
            //Элемент меню "Выход"
            MenuItem {
                text: qsTr("Exit")
                //при клике
                onClicked: {
                    //деактивация пользователя
                    dao.deActivate();
                    //удалить из стека все страницы до главной
                    pageStack.replaceAbove(null, Qt.resolvedUrl("MainPage.qml"))
                }
            }
            //подпись вытягиваемого меню
            MenuLabel{
                text: qsTr("Commie")
            }
        }
        //столбец со списком контактов
        Column{
            id:contsCol
            //ширина по странице
            width: contactsPage.width
            //высота по странице минус высота шапки страницы
            height: contactsPage.height-contsBar.height
            //среднее системное расстояние между элементами
            spacing: Theme.paddingMedium
            //верхняя часть начинается под шапкой
            anchors.top: contsBar.bottom
            //Списочный элемент
            SilicaListView{
                id:listView
                //ширина по столбцу
                width: contsCol.width
                //высота по столбцу минус высота шапки
                height: contsCol.height-contsBar.height
                //модель списка состоящая из логина, пароля и аватара
                model: ListModel {
                    ListElement {
                        login: ""
                        alias: ""
                        avatar: ""
                        ip: ""
                        port: 0
                        public_key: ""
                        enc_public_key: ""
                        contactId: -1
                    }
                }
                //элемент списка
                delegate: BackgroundItem {
                    id: contactListElement
                    //высота 120
                    height: Theme.dp(120)
                    //ряд
                    Row {
                        //отступ слева 16
                        anchors.left: Theme.dp(16)
                        //вертикальное выраванивание по центру
                        anchors.verticalCenter: parent.verticalCenter
                        // Изображение с аватаром при наличии
                        Image {
                            id: avatarImage
                            //Источник картинки - или аватар, или пустая строка
                            source: avatar ? avatar : ""
                            //Размеры 100*100
                            width: 100
                            height: 100
                            //Видимость если аватар присутствует
                            visible: avatar !== null
                        }
                        //Точка вместо аватара
                        Rectangle {
                            id: avatarPlaceholder
                            //синий цвет
                            color: "#3D6BE3"
                            //Размеры 100*100
                            width: 100
                            height: 100
                            //Углы скошены до круга
                            radius: width * 0.5
                            //видим, если аватар отсутствует
                            visible: avatar === null
                        }
                        //столбец для текста
                        Column {
                            //ширина по родителю
                            width: parent.width

                            // Проверяем наличие псевдонима и отображаем логин
                            Label {
                                //смещение по иксу на 16
                                x: 16
                                //текст или псевдоним, если он есть, или логин
                                text: alias ? alias : login
                                //белый цвет
                                color: "#FFFFFF"
                                //размер шрифта 48
                                font.pixelSize: Theme.dp(48)
                                //жирный шрифт
                                font.bold: true
                            }
                        }
                    }


                    onPressed:  {

                        console.log(
                                    "Долгое нажатие на контакт:\n",
                                    "Логин:", login, "\n",
                                    "Алиас:", alias,"\n",
                                    "Аватар:", avatar,"\n",
                                    "IP:", ip,"\n",
                                    "Порт:", port,"\n",
                                    "Публичный ключ:", public_key,"\n",
                                    "enc_public_key:", enc_public_key,"\n"
                                    );
                        popup.open()

                    }

                    PopupMenu {
                        id: popup
                        PopupMenuItem {
                            text: "Личный чат"
                            onClicked: {
                                var contactIp = model.ip;
                                var contactPort = model.port;
                                var contactId = model.contactId;

                                // Проверяем, есть ли уже соединение
                                if (peers.hasActiveConnection(contactIp, contactPort)) {
                                    openChat(contactId);
                                    Notices.show(qsTr("Уже соединены"),
                                                 Notice.Short,
                                                 Notice.Bottom,
                                                 0,
                                                 -Theme.horizontalPageMargin);

                                    return;
                                }

                                function onSuccess() {
                                    openChat(contactId);
                                    Notices.show(qsTr("Соединение установлено"),
                                                 Notice.Short,
                                                 Notice.Bottom,
                                                 0,
                                                 -Theme.horizontalPageMargin);
                                    peers.peerConnected.disconnect(onSuccess);
                                    peers.connectionError.disconnect(onError);

                                }

                                function onError(socketError) {
                                    console.log("Ошибка соединения:", socketError);
                                    Notices.show(qsTr("Ошибка соединения"),
                                                 Notice.Short,
                                                 Notice.Bottom,
                                                 0,
                                                 -Theme.horizontalPageMargin);
                                    peers.peerConnected.disconnect(onSuccess);
                                    peers.connectionError.disconnect(onError);
                                }

                                peers.peerConnected.connect(onSuccess);
                                peers.connectionError.connect(onError);

                                peers.connectToPeer(contactIp, contactPort);
                            }
                        }
                    }

                }

                //вертикальная полоса прокрутки к этому безобразию
                VerticalScrollDecorator {flickable: ListView}
            }
        }
    }

    //при загрузке страницы
    Component.onCompleted: {
        //обновить список
        updateList();

        peers.peerConnected.connect(function() {
            Notices.show(qsTr("Соединение установлено"),
                         Notice.Short,
                         Notice.Bottom,
                         0,
                         -Theme.horizontalPageMargin);
        });

        peers.remotePeerConnected.connect(function() {
            Notices.show(qsTr("Соединение установлено"),
                         Notice.Short,
                         Notice.Bottom,
                         0,
                         -Theme.horizontalPageMargin);
        });

        peers.connectionError.connect(function() {
            Notices.show(qsTr("Ошибка соединения"),
                         Notice.Short,
                         Notice.Bottom,
                         0,
                         -Theme.horizontalPageMargin);
        });
    }

}
