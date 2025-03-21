import QtQuick 2.2
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import QtQuick.LocalStorage 2.0

Page{
    objectName: "settingsPage"
    allowedOrientations: Orientation.All
    id:settingsPage

    // Создаём экземпляр dao для работы с SQLite
    Dao {
        id: dao
    }

    SilicaFlickable{
        id:chatsList
        anchors.fill: parent
        contentHeight: parent.height
        //верхнее меню приложения
        AppBar{
            headerText: qsTr("Commie")
            subHeaderText: qsTr("Settings")
            id:header
            divider: true
            background: true
        }

        //меню, вытягиваемое сверху вниз
        PullDownMenu{
            topMargin: chatsList.height

            MenuItem {
                text: qsTr("Personal Chats")
                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("PersonalChatsPage.qml"))
                }
            }

            MenuItem {
                text: qsTr("Groups")
                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("GroupChatsPage.qml"))
                }
            }

            MenuItem {
                text: qsTr("Contacts")
                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("Contacts.qml"))
                }
            }

            MenuItem {
                text: qsTr("Invites")
                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("InvitePage.qml"))
                }
            }

            MenuItem {
                text: qsTr("Exit")
                onClicked: {
                    dao.deActivate();
                    pageStack.replaceAbove(null, Qt.resolvedUrl("MainPage.qml"))
                }
            }

            MenuLabel{
                text: qsTr("Commie")
            }
        }
        SilicaListView{
            width:settingsPage.width
            height: settingsPage.height-header.height
            id:slv
            spacing: Theme.paddingMedium
            anchors.top: header.bottom

            model: ListModel{
                ListElement{
                    settingsPunkt: qsTr("Profile")
                }
                ListElement{
                    settingsPunkt: qsTr("About Project")
                }
                ListElement{
                    settingsPunkt: qsTr("Delete account")
                }
            }
            delegate: BackgroundItem{
                height: Theme.dp(120)

                Label{
                    x:Theme.dp(16)
                    text: settingsPunkt
                    anchors.verticalCenter: parent.verticalCenter
                }

                onClicked: {
                    handleClick(index);
                }

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
                        Notices.show("Данные аккаунтов удалены",
                                     Notice.Short,
                                     Notice.Bottom,
                                     0,
                                     -Theme.horizontalPageMargin)
                        pageStack.replaceAbove(null, Qt.resolvedUrl("MainPage.qml"));
                        break;
                    }
                }
            }
        }
    }
}
