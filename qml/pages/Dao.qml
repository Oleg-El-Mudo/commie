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
    avatar BLOB)");
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
    avatar BLOB)");
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

    //РАБОТА С ТАБЛИЦЕЙ ЛИЧНЫХ ЧАТОВ

    //РАБОТА С ТАБЛИЦЕЙ ГРУППОВЫХ ЧАТОВ

    //подключение к БД и создание таблицы при загрузке компонента
    Component.onCompleted: {
        db = LocalStorage.openDatabaseSync("commie_db", "1.0");
        createUsersTable();
        createContactsTable();
    }
}
