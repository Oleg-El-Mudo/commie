import QtQuick 2.0
import QtQuick.LocalStorage 2.0

QtObject {
    property var db;

    //РАБОТА С ТАБЛИЦЕЙ ПОЛЬЗОВАТЕЛЯ

    //создаём таблицу с пользователями, если её ещё не было
    function createUsersTable() {
        db.transaction(function (tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    login TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    public_key TEXT NOT NULL,
    private_key TEXT NOT NULL,
    ip TEXT NOT NULL,
    port INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL,
    alias TEXT,
    avatar TEXT)");
        });
    }
    //функция для добавления данных пользователя при регистрации
    function insertUser(login, password, publicKey, privateKey, ip, port, isActive){
        db.transaction(function(tx){
            tx.executeSql("INSERT INTO users(login, password, public_key, private_key, ip, port, is_active) VALUES(?, ?, ?, ?, ?, ?, ?)", [login, password, publicKey, privateKey, ip, port, isActive]);
        });
    }
    //выборка пользователя по никнейму
    function getUserByNickname(login) {
        var result;
        db.readTransaction(function(tx) {
            var query = tx.executeSql('SELECT * FROM users WHERE login = ?', [login]);
            if (query.rows.length > 0) {
                result = query.rows.item(0);
            }
        });
        return result;
    }
    //получаем активного пользователя (аккаунт, в который был произведен вход, но не было выхода)
    function getActiveUser() {
        var result;
        db.readTransaction(function(tx) {
            var query = tx.executeSql('SELECT * FROM users WHERE is_active = true');
            if (query.rows.length > 0) {
                result = query.rows.item(0);
            }
        });
        return result;
    }
    //функция для удаления всех записей из таблицы users
    function deleteAllUsers() {
        db.transaction(function(tx) {
            tx.executeSql("DELETE FROM users");
        });
    }
    //обновляем айпи и порт
    function updateIpAndPort(ip, port){
        db.transaction(function(tx){
            tx.executeSql("UPDATE users SET ip = ?, port = ? WHERE is_active = true", [ip, port]);
        });
    }

    //делаем пользователя "активным"
    function activate(login){
        db.transaction(function(tx){
            tx.executeSql("UPDATE users SET is_active = true where login=?", [login]);
        });
    }
    //делаем пользователя "не-активным"
    function deActivate(){
        db.transaction(function(tx){
            tx.executeSql("UPDATE users SET is_active = false where is_active=true");
        });
    }
    function setAlias(new_alias){
        db.transaction(function(tx){
            tx.executeSql("UPDATE users SET alias = ? where is_active=true", [new_alias]);
        });
    }
    function setPassword(new_password){
        db.transaction(function(tx){
            tx.executeSql("UPDATE users SET password = ? where is_active=true", [new_password]);
        });
    }
    function updateAvatar(userId, avatarBase64) {
        db.transaction(function(tx) {
            tx.executeSql("UPDATE users SET avatar = ? WHERE id = ?", [avatarBase64, userId]);
        });
    }
    function getAvatar(userId) {
        var result = "";
        db.transaction(function(tx) {
            var query = tx.executeSql("SELECT avatar FROM users WHERE id = ?", [userId]);
            if (query.rows.length > 0) {
                result = query.rows.item(0).avatar; // Возвращаем строку Base64
            }
        });
        return result;
    }

    function getAvatarBase64(userId) {
        var result = "";
        db.transaction(function(tx) {
            var query = tx.executeSql("SELECT avatar FROM users WHERE id = ?", [userId]);
            if (query.rows.length > 0) {
                var blob = query.rows.item(0).avatar;
                if (blob) {
                    // Преобразуем BLOB в Base64
                    result = "data:image/png;base64," + btoa(String.fromCharCode.apply(null, new Uint8Array(blob)));
                }
            }
        });
        console.log(result);
        return result;
    }

    //РАБОТА С ТАБЛИЦЕЙ КОНТАКТОВ

    //создаем таблицу для контактов если её ещё не было
    function createContactsTable() {
        db.transaction(function (tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS contacts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                login TEXT NOT NULL,
                public_key TEXT NOT NULL UNIQUE,
                ip TEXT NOT NULL,
                port INTEGER NOT NULL,
                alias TEXT,
                avatar TEXT,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )");
        });
    }
    function updateContact(login, ip, port, aliias, avatar, user_id, public_key) {
        db.transaction(function (tx) {
            tx.executeSql("UPDATE contacts SET login=?, ip=?, port=?, alias=?, avatar=? WHERE user_id=? AND public_key=?", [login, ip, port, aliias, avatar, user_id, public_key]);
        });
    }
    //получаем список контактов
    function getContacts() {
        var records = [];
        db.readTransaction(function(tx) {
            var result = tx.executeSql("SELECT * FROM contacts");
            for (var i = 0; i < result.rows.length; i++) {
                var record = result.rows.item(i);
                records.push({"id": record.id, "login": record.login, "public_key": record.public_key, "ip": record.ip, "port": record.port, "alias": record.alias, "avatar": record.avatar});
            }
        });
        return records;
    }
    //функция для добавления контакта в таблицу contacts
    function insertContact(user_id, login, publicKey, ip, port, aliias, avatar) {
        db.transaction(function(tx) {
            tx.executeSql("INSERT INTO contacts(user_id, login, public_key, ip, port, alias, avatar) VALUES(?, ?, ?, ?, ?, ?, ?)", [user_id, login, publicKey, ip, port, aliias, avatar]);
        });
    }
    //функция для получения контактов пользователя по его id
    function getContactByUserID(user_id) {
        var records = [];
        db.readTransaction(function(tx) {
            var query = tx.executeSql('SELECT * FROM contacts WHERE user_id = ?', [user_id]);
            for (var i = 0; i < query.rows.length; i++) {
                var record = query.rows.item(i);
                records.push({"id": record.id, "login": record.login, "public_key": record.public_key, "ip": record.ip, "port": record.port, "alias": record.alias, "avatar": record.avatar});
            }
        });
        return records;
    }

    function deleteAllContacts() {
        db.transaction(function(tx) {
            tx.executeSql("DELETE FROM contacts");
        });
    }

    // --- Таблица чатов ---
    // Типы чатов: 1=личный, 2=групповой, 3=избранное (локальный)
    function createChatsTable() {
        db.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS chats (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    type INTEGER NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    last_message_id INTEGER
                )");
        });
    }

    // --- Таблица участников чатов ---
    function createChatParticipantsTable() {
        db.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS chat_participants (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    chat_id INTEGER NOT NULL,
                    user_id INTEGER NOT NULL,
                    is_active BOOLEAN DEFAULT 1,
                    FOREIGN KEY (chat_id) REFERENCES chats(id),
                    FOREIGN KEY (user_id) REFERENCES users(id)
                )");
        });
    }

    // --- Таблица сообщений ---
    function createMessagesTable() {
        db.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS messages (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    chat_id INTEGER NOT NULL,
                    sender_id INTEGER NOT NULL,
                    content TEXT,
                    is_pinned BOOLEAN DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    status INTEGER DEFAULT 0,
                    is_local_only BOOLEAN DEFAULT 0,
                    FOREIGN KEY (chat_id) REFERENCES chats(id),
                    FOREIGN KEY (sender_id) REFERENCES users(id)
                )");//status - 0=отправлено, 1=доставлено, 2=прочитано; is_local_only - TRUE для избранного
        });
    }

    // --- Таблица вложений (Base64) ---
    function createAttachmentsTable() {
        db.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS attachments (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    message_id INTEGER NOT NULL,
                    type INTEGER NOT NULL,
                    name TEXT NOT NULL,
                    size INTEGER NOT NULL,
                    mime_type TEXT NOT NULL,
                    data TEXT NOT NULL,
                    thumbnail TEXT,
                    duration INTEGER,
                    width INTEGER,
                    height INTEGER,
                    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
                )");//type -- 1=image, 2=video, 3=audio, 4=document
        });
    }

    // --- Таблица статусов сообщений ---
    function createMessageStatusTable() {
        db.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS message_status (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    message_id INTEGER NOT NULL,
                    user_id INTEGER NOT NULL,
                    status INTEGER DEFAULT 0,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (message_id) REFERENCES messages(id),
                    FOREIGN KEY (user_id) REFERENCES users(id),
                    UNIQUE (message_id, user_id)
                )"); //status - 0=отправлено, 1=доставлено, 2=прочитано
        });
    }

    //подключение к БД и создание таблицы при загрузке компонента
    Component.onCompleted: {
        db = LocalStorage.openDatabaseSync("commie_db", "1.0");
        db.transaction(function(tx) {
            tx.executeSql("PRAGMA foreign_keys = ON");
        });
        createUsersTable();
        createContactsTable();
        createChatsTable();
        createChatParticipantsTable();
        createMessagesTable();
        createAttachmentsTable();
        createMessageStatusTable();
    }
}
