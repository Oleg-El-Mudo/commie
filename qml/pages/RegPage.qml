import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Dialog {
    objectName: "regPage"
    allowedOrientations: Orientation.All

    // Создаём экземпляр dao для работы с SQLite
    Dao {
        id: dao
    }

    // Действия при подтверждении диалога (свайпа влево)
    onAccepted: {
        // Проверка ввода данных
        if (nickName.text.length > 0 && password.text.length > 14) {
            // Переход на страницу с параметрами
            pageStack.push(Qt.resolvedUrl("RegLoadingPage.qml"),{ nick: nickName.text, password: password.text });
        } else {
            // Отображение уведомления об ошибке
            Notices.show(qsTr("Fill in all fields"),
                         Notice.Short,
                         Notice.Bottom,
                         0,
                         -Theme.horizontalPageMargin);
        }
    }
    // При отмене диалога переходим на страницу назад
    onRejected: {
        // Убираем флаг в положение "ложь" при переходе на главную страницу
        dao.deActivate();
        pageStack.navigateBack(PageStackAction.Animated);
    }

    acceptDestinationAction: PageStackAction.Push
    acceptDestination: Qt.resolvedUrl("RegLoadingPage.qml")

    // Шапка диалога
    DialogHeader {
        id: header
        title: qsTr("Create an account")
        // Кнопки - они же стороны для свайпа диалога
        acceptText: qsTr("Create")
        cancelText: qsTr("Cancel")
        background: true
    }

    // Контейнер с лейблом и текстовыми полями для регистрации
    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        anchors.centerIn: parent

        // Сообщение о невозможности восстановления аккаунта
        Label {
            objectName: "descriptionText"
            anchors {
                left: parent.left;
                right: parent.right;
                margins: Theme.horizontalPageMargin
            }
            color: palette.highlightColor
            font.pixelSize: Theme.fontSizeExtraMedium
            textFormat: Text.RichText
            wrapMode: Text.WordWrap
            text: qsTr("!If you delete the messenger or forget your password, it will be impossible to restore your account!")
            horizontalAlignment: Text.AlignHCenter
            visible: !(nickName.focus || password.focus)
        }
        // Поле для ввода ника
        TextField {
            id: nickName
            description: qsTr("Come up with a suitable nickname for yourself")
            label: qsTr("Required field!")
            placeholderText: qsTr("Enter a nickname")
            leftItem: Icon {
                source: "image://theme/icon-m-add-account"
            }
            anchors.horizontalCenter: parent.horizontalCenter
            rightItem: Icon {
                source: "image://theme/icon-splus-contact"
            }
            acceptableInput: text.length > 0

            // Разрешать нажатие кнопки «Enter» только при наличии текста
            EnterKey.enabled: text.length > 0

            // Отображать значок «Next», чтобы указать на то, что нажатие кнопки «Enter»
            // переместит фокус клавиатуры на следующее текстовое поле
            EnterKey.iconSource: "image://theme/icon-m-enter-next"

            // При нажатии кнопки «Enter» фокус клавиатуры переносится
            // на следующее текстовое поле
            EnterKey.onClicked: password.focus = true
        }

        // Поле для ввода пароля
        PasswordField {
            id: password
            description: qsTr("Use letters, numbers and special characters")
            label: qsTr("From 15 characters")
            placeholderText: qsTr("Enter a password")
            leftItem: Icon {
                source: "image://theme/icon-m-asterisk"
            }
            rightItem: Icon {
                source: "image://theme/icon-splus-asterisk"
            }
            anchors.horizontalCenter: parent.horizontalCenter
            acceptableInput: text.length > 14 && /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+])[A-Za-z\d!@#$%^&*()_+]+$/.test(text)
            EnterKey.enabled: text.length > 14 && /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+])[A-Za-z\d!@#$%^&*()_+]+$/.test(text)

            EnterKey.iconSource: "image://theme/icon-m-enter-accept"

            EnterKey.onClicked:{
                focus = false
                accept()
            }
        }
    }
    Component.onCompleted: {
        dao.deActivate();
    }
}
