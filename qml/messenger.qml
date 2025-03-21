import QtQuick 2.0
import Sailfish.Silica 1.0
//подключение самозарегистрированных типов
//рыбота в одноранговой сети
import Peers.Module 1.0
//работа с системой контактов
import Friends.Module 1.0
//работа с криптографией
import Crypto.Module 1.0

ApplicationWindow {
    objectName: "applicationWindow"
    applicationActive: {
        //приложение растягивается на весь экран в портретном режиме
        displayMode = ApplicationDisplayMode.FullPortrait;
        //статусбар видимый
        statusbarForceVisible = true;
    }
    //страница, открываемая при запуске приложения
    initialPage: Qt.resolvedUrl("pages/MainPage.qml")
    //обложка, отображаемая на главном экране ОС при свёртывании приложения
    cover: Qt.resolvedUrl("cover/DefaultCoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
    //объекты для работы с c++ функциями из qml, доступны из всех дочерних qml страниц
    Peers {
        id: peers
    }
    Friends{
        id:friends
    }
    Crypto{
        id: crypto
    }
}
