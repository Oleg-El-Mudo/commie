import QtQuick 2.2
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import QtQuick.LocalStorage 2.0

Page{
    objectName: "profileSettingsPage"
    allowedOrientations: Orientation.All
    id:settingsPage

    property string your_alias
    property string your_avatar

    Dao{
        id:dao
    }

    //верхнее меню приложения
    AppBar{
        headerText: qsTr("Commie")
        subHeaderText: qsTr("Profile Settings")
        id:header
        divider: true
        background: true

        AppBarSpacer{}

        AppBarButton{
            context: qsTr("Update")
            icon.source: "image://theme/icon-m-refresh"

            onClicked: {
                var auser = dao.getActiveUser();
                your_alias = auser.alias;
                your_avatar = auser.avatar;
            }
        }
    }

    Column{
        id: info_col
        anchors.top: header.bottom
        width: settingsPage.width
        height: avatarImage.height+aliasLabel.height


        // Проверяем наличие аватара
        Image {
            id: avatarImage
            source: your_avatar ? your_avatar : ""
            width: 100
            height: 100
            visible: your_avatar !== null
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        // Проверяем наличие псевдонима
        Label {
            id: aliasLabel
            text: your_alias ? your_alias : qsTr("No alias set")
            anchors.left: avatarImage.visible ? avatarImage.right : parent.left
            anchors.verticalCenter: parent.verticalCenter

        }
    }

    Separator {
        width: parent.width
        color: Theme.highlightColor
        horizontalAlignment: Qt.AlignHCenter
    }


    SilicaListView{
        width:settingsPage.width
        height: settingsPage.height-header.height-info_col.height
        id:slv
        spacing: Theme.paddingMedium
        anchors.top: info_col.bottom

        model: ListModel{
            ListElement{
                settingsPunkt: qsTr("Set/change avatar")
            }
            ListElement{
                settingsPunkt: qsTr("Set/change alias")
            }
            ListElement{
                settingsPunkt: qsTr("Change password")
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
                    //pageStack.push(Qt.resolvedUrl("ProfileSettingsPage.qml"))
                    break;
                case 1:
                    // код для нажатия на "About Project"
                    pageStack.push(Qt.resolvedUrl("AliasSettingsPage.qml"))
                    break;
                case 2:
                    // код для нажатия на "Delete account"

                    break;
                }
            }
        }
    }
    Component.onCompleted: {
        var auser = dao.getActiveUser();
        your_alias = auser.alias;
        your_avatar = auser.avatar;
    }
}
