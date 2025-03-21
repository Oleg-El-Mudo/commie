import QtQuick 2.0
import Sailfish.Silica 1.0
import Aurora.Controls 1.0

Page {
    //имя объекта (страницы)
    objectName: "aboutPage"
    //доступны все ориентации экрана
    allowedOrientations: Orientation.All

    //прокручиваемый элемент страницы
    SilicaFlickable {
        objectName: "flickable"
        //заполняется по родительскому элементу
        anchors.fill: parent
        //ширина содержимого - сумма высоты внутреннего столба и системных отступов
        contentHeight: layout.height + Theme.paddingLarge
        Column {
            id: layout
            objectName: "layout"
            //ширина по родителю
            width: parent.width
            //расстояние между элементами столбца - 20
            spacing: 20
            PageHeader {
                //отступ сверху 15
                anchors.topMargin: Theme.dp(15)
                objectName: "pageHeader"
                //заголовок приложения в шапке страницы
                title: qsTr("About Project")
            }
            Label {
                objectName: "descriptionText"
                anchors {
                    left: parent.left;
                    right: parent.right;
                    //системные горизонтальные отступы
                    margins: Theme.horizontalPageMargin
                }
                //системные светлые цвета (зависят от атмосферы)
                color: palette.highlightColor
                //ЖЖЖирный шрифт
                font.pixelSize: Theme.fontSizeExtraLargeBase
                textFormat: Text.RichText
                //текст переносится по словам, если не влезает в ширину эурана
                wrapMode: Text.WordWrap
                text: qsTr("Commie - safe messenger")
                //выравнивание по горизонтали по центру
                horizontalAlignment: Text.AlignHCenter
            }
            Image {
                //картинка размером 400*400
                source: "../icons/psuti.fishman.messenger.png"
                width: 400
                height: 400
                //выраваниение по горизонтали по центру
                anchors.horizontalCenter: parent.horizontalCenter
            }
            //линия-разделитель
            Separator {
                //ширина по родителю
                width: parent.width
                //светлые системные цвета
                color: Theme.highlightColor
                //выравнивание по горизонтали по центру
                horizontalAlignment: Qt.AlignHCenter
            }
            //Абзац текста
            Label {
                objectName: "descriptionText"
                //выраваниение по родителю, отступы системные горизонтальные
                anchors { left: parent.left; right: parent.right; margins: Theme.horizontalPageMargin }
                //системные основной цвет
                color: palette.primaryColor
                //средний размер шрифта
                font.pixelSize: Theme.fontSizeMedium
                textFormat: Text.RichText
                //перенос строк по словам
                wrapMode: Text.WordWrap
                text: qsTr("The messenger works on a p2p network<br><br>All messages sent through messenger are end-to-end encrypted<br><br>The project is the thesis work of a PSUTI student:<br><br>Faculty #1 Cybersecurity and Management Department<br><br>Group: RPIS-11<br>Full name: Oleg Mikhailovich Rybin")
            }
            //линия - разделитель
            Separator {
                //ширина по родителю
                width: parent.width
                //светлый системный цвет
                color: Theme.highlightColor
                //выравнивание по горизонтали по центру
                horizontalAlignment: Qt.AlignHCenter
            }
            //заголовок секции
            SectionHeader {
                objectName: "licenseHeader"
                text: qsTr("License")
            }
            //линия-разделитель
            Separator {
                //ширина по родителю
                width: parent.width
                //светлый системный цвет
                color: Theme.highlightColor
                //горизонтальное выравнивание по центру
                horizontalAlignment: Qt.AlignHCenter
            }
            //Абзац текста
            Label {
                objectName: "LicenseText"
                //Выравнивание по родителю, отступы системные горизонтальные
                anchors { left: parent.left; right: parent.right; margins: Theme.horizontalPageMargin }
                //основной цвет
                color: palette.primaryColor
                //средний размер шрифта
                font.pixelSize: Theme.fontSizeMedium
                textFormat: Text.RichText
                //перенос строк по словам
                wrapMode: Text.WordWrap
                text: qsTr("The project is licensed under GPLv3+. Consequently:<br><br>- The source codes are open and available for review and modification to everyone; <br><br>- All changes in the software product are open and distributed under the same license; <br><br>- All modifications (branches) of the project must also be distributed under this license")
            }
            //линия-разделитель
            Separator {
                //ширина по родителю
                width: parent.width
                //системный светлый цвет
                color: Theme.highlightColor
                //выравнивание по горизонтали по центру
                horizontalAlignment: Qt.AlignHCenter
            }
            //заголовок секции
            SectionHeader {
                objectName: "SourceHeader"
                text: qsTr("Source codes")
            }
            //линия-разделитель
            Separator {
                //ширина по родителю
                width: parent.width
                //системный светлый цвет
                color: Theme.highlightColor
                //горизонтальное выравнивание по центру
                horizontalAlignment: Qt.AlignHCenter
            }
            //Абзац текста
            Label {
                objectName: "SourceText"
                //выравнивание по родителю, отступы системные горизонтальные
                anchors { left: parent.left; right: parent.right; margins: Theme.horizontalPageMargin }
                //основной цвет текста
                color: palette.primaryColor
                //средний размер шрифта
                font.pixelSize: Theme.fontSizeMedium
                textFormat: Text.RichText
                //перенос текста по словам
                wrapMode: Text.WordWrap
                text: qsTr("In accordance with the project's licensing, its source code is open source and available at the following resources:")
            }
            //Абзац текста
            Label {
                objectName: "GitVerseText"
                //выравнивание по родителю, отступы системные горизонтальные
                anchors { left: parent.left; right: parent.right; margins: Theme.horizontalPageMargin }
                //системный светлый цвет
                color: palette.highlightColor
                //большой размер шрифта
                font.pixelSize: Theme.fontSizeLarge
                textFormat: Text.RichText
                //перенос текста по словам
                wrapMode: Text.WordWrap
                //ссылка на gitverse проека
                text: qsTr("<a href='https://gitverse.ru/Fishman/commie'>GitVerse</a>")
                //выраваниение ссылки по горизонтали по центру
                horizontalAlignment: Text.AlignHCenter
                //при клике по ссылке
                onLinkActivated: {
                    //открыть ссылку извне (в браузере)
                    Qt.openUrlExternally(link)
                }
            }
        }
        //вертикальная полоса прокрутки
        VerticalScrollDecorator {
            //указываем, какой элемент она прокручивает
            flickable: flickable
        }
    }
}
