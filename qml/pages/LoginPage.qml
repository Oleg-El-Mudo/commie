import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Dialog {
    objectName: "loginPage"
    allowedOrientations: Orientation.All

    // Создаём экземпляр dao для работы с SQLite
    Dao {
        id: dao
    }

    // Действия при подтверждении диалога (свайпа влево)
    onAccepted: {
        // Проверка ввода данных
        if (nickName.text.length > 0 && password.text.length > 0) {
            // Переход на страницу с параметрами
            pageStack.push(Qt.resolvedUrl("LoginLoadingPage.qml"), { nick: nickName.text, password: password.text });
        } else {
            // Отображение уведомления об ошибке
            Notices.show(qsTr("Please fill in all fields"),
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

    //при подтверждении диалога делаем пуш по пейдж стаку
    acceptDestinationAction: PageStackAction.Push
    //при подтверждении диалога пуш будет происходить на страницу загрузки после логина
    acceptDestination: Qt.resolvedUrl("LoginLoadingPage.qml")

    // Шапка диалога
    DialogHeader {
        id: header
        title: qsTr("Signing in")
        // Кнопки - они же стороны для свайпа диалога
        acceptText: qsTr("Login")
        cancelText: qsTr("Cancel")
        //у шапки есть фон
        background: true
    }

    // Контейнер с лейблом и текстовыми полями для регистрации
    Column {
        //ширина по родителю
        width: parent.width
        //расстояние внутри столбца системное большое
        spacing: Theme.paddingLarge
        //центрирование внутри родителя
        anchors.centerIn: parent

        //абзац текста
        Label {
            objectName: "descriptionText"
            //привязка к родителю, отступы системные горизонтальные
            anchors {
                left: parent.left;
                right: parent.right;
                margins: Theme.horizontalPageMargin
            }
            //цвет системный светлый
            color: palette.highlightColor
            //размер шрифта средний+
            font.pixelSize: Theme.fontSizeExtraMedium
            textFormat: Text.RichText
            //перенос текста по словам
            wrapMode: Text.WordWrap
            text:qsTr("!You must already have an account<br>created on this device!")
            //выравнивание по горизонтали по центру
            horizontalAlignment: Text.AlignHCenter
            //невидим, если в фокусе поле для ника или пароля
            visible: !(nickName.focus || password.focus)
        }

        // Поле для ввода ника
        TextField {
            id: nickName
            description: qsTr("Enter your nickname")
            label: qsTr("Required field!")
            //подсказка по полю
            placeholderText: qsTr("Enter a nickname")
            //иконка слева "добавить контакт"
            leftItem: Icon {
                source: "image://theme/icon-m-add-account"
            }
            //выраванивание по центру
            anchors.horizontalCenter: parent.horizontalCenter
            //иконка справа
            rightItem: Icon {
                source: "image://theme/icon-splus-contact"
            }
            //допустимый ввод - длина больше 0
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
            description: qsTr("Enter your password")
            label: qsTr("Required field!")
            //подсказка по полю пароля
            placeholderText: qsTr("Enter a password")
            //иконка слева
            leftItem: Icon {
                source: "image://theme/icon-m-asterisk"
            }
            //иконка справа
            rightItem: Icon {
                source: "image://theme/icon-splus-asterisk"
            }
            //выравнивание по центру
            anchors.horizontalCenter: parent.horizontalCenter
            //регулярное выражение для допустимости ввода и доступа к enter
            acceptableInput: text.length > 14 && /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+])[A-Za-z\d!@#$%^&*()_+]+$/.test(text)

            EnterKey.enabled: text.length > 14 && /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+])[A-Za-z\d!@#$%^&*()_+]+$/.test(text)

            //иконка внутри кнопки enter
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            //при нажатии на enter
            EnterKey.onClicked:{
                //снимаем все фокусы
                focus = false
                //подтверждаем переход
                accept()
            }
        }
    }
    //при загрузке страницы
    Component.onCompleted: {
        //деактивируем пользователей
        dao.deActivate();
    }
}
