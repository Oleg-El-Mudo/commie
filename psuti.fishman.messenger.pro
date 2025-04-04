TARGET = psuti.fishman.messenger

CONFIG += \
    auroraapp

PKGCONFIG += \

SOURCES += \
    src/cryptomanager.cpp \
    src/f2fmanager.cpp \
    src/main.cpp \
    src/peer2peermanager.cpp

HEADERS += \
    src/cryptomanager.h \
    src/f2fmanager.h \
    src/peer2peermanager.h

DISTFILES += \
    qml/pages/AboutProjectPage.qml \
    qml/pages/AliasSettingsPage.qml \
    qml/pages/Contacts.qml \
    qml/pages/Dao.qml \
    qml/pages/GroupChatsPage.qml \
    qml/pages/InvitePage.qml \
    qml/pages/LoginLoadingPage.qml \
    qml/pages/LoginPage.qml \
    qml/pages/PasswordSettingsPage.qml \
    qml/pages/PersonalChatsPage.qml \
    qml/pages/ProfileSettingsPage.qml \
    qml/pages/QRCodePage.qml \
    qml/pages/QRReaderPage.qml \
    qml/pages/RegLoadingPage.qml \
    qml/pages/SettingsPage \
    qml/pages/SettingsPage.qml \
    rpm/psuti.fishman.messenger.spec \

AURORAAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += auroraapp_i18n

TRANSLATIONS += \
    translations/psuti.fishman.messenger.ts \
    translations/psuti.fishman.messenger-ru.ts \

include(libsodium/libsodium.pri)

INCLUDEPATH += $$PWD/libsodium/include
LIBS += -L$$PWD\libsodium\x64\Release\v143\dynamic\ -lsodium

QT += network
