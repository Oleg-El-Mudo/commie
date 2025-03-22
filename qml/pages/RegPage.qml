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
        // с анимацией переходим на прошлую страницу
        pageStack.navigateBack(PageStackAction.Animated);
    }

    //при подтверждении добавляем новую страницу на вершину стека
    acceptDestinationAction: PageStackAction.Push
    //при подтверждении переходим на страницу загрузки после регистрации
    acceptDestination: Qt.resolvedUrl("RegLoadingPage.qml")

    // Шапка диалога
    DialogHeader {
        id: header
        title: qsTr("Create an account")
        // Кнопки - они же стороны для свайпа диалога
        acceptText: qsTr("Create")
        cancelText: qsTr("Cancel")
        //фон
        background: true
    }

    // Контейнер с лейблом и текстовыми полями для регистрации
    Column {
        width: parent.width
        //большие отступы между элементами столбца
        spacing: Theme.paddingLarge
        //центрируем в родительском объекте
        anchors.centerIn: parent

        // Сообщение о невозможности восстановления аккаунта
        Label {
            objectName: "descriptionText"
            //привязки
            anchors {
                left: parent.left;
                right: parent.right;
                //системные горизонтальные отступы
                margins: Theme.horizontalPageMargin
            }
            //светлые цвета
            color: palette.highlightColor
            //средний+ размер текста
            font.pixelSize: Theme.fontSizeExtraMedium
            textFormat: Text.RichText
            //перенос текста по словами
            wrapMode: Text.WordWrap
            text: qsTr("!If you delete the messenger or forget your password, it will be impossible to restore your account!")
            //горизонтальное выравнивание по центру
            horizontalAlignment: Text.AlignHCenter
            //невидим, если одно из полей в фокусе
            visible: !(nickName.focus || password.focus)
        }
        // Поле для ввода ника
        TextField {
            id: nickName
            description: qsTr("Come up with a suitable nickname for yourself")
            label: qsTr("Required field!")
            //подсказка в поле
            placeholderText: qsTr("Enter a nickname")
            //иконка слева поля
            leftItem: Icon {
                source: "image://theme/icon-m-add-account"
            }
            //выравнивание по центру по горизонтали
            anchors.horizontalCenter: parent.horizontalCenter
            //иконка справа поля
            rightItem: Icon {
                source: "image://theme/icon-splus-contact"
            }
            //допустимость ввода от 1 символа
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
            //текст подсказки в поле
            placeholderText: qsTr("Enter a password")
            //левая иконка
            leftItem: Icon {
                source: "image://theme/icon-m-asterisk"
            }
            //правая иконка
            rightItem: Icon {
                source: "image://theme/icon-splus-asterisk"
            }
            //горизонтальное выравнивание по центру
            anchors.horizontalCenter: parent.horizontalCenter
            //проверка пароля и кнопки enter на валидной пароля
            acceptableInput: text.length > 14 && /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+])[A-Za-z\d!@#$%^&*()_+]+$/.test(text)
            EnterKey.enabled: text.length > 14 && /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+])[A-Za-z\d!@#$%^&*()_+]+$/.test(text)

            //иконка кнопки enter
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"

            //при клике по кнопке enter
            EnterKey.onClicked:{
                //снимаем фокус
                focus = false
                //подтвердаем ввод
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
