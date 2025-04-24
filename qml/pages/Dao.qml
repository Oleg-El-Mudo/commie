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

    // --- ТАБЛИЦЫ ДЛЯ ЧАТОВ ---
    function createChatsTable() {
        db.transaction(function (tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS chats (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                type INTEGER NOT NULL,  -- 1=личный, 2=групповой, 3=избранное
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_message_id INTEGER
            )");
        });
    }

    function createChatParticipantsTable() {
        db.transaction(function (tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS chat_participants (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                chat_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )");
        });
    }

    function createMessagesTable() {
        db.transaction(function (tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                chat_id INTEGER NOT NULL,
                sender_id INTEGER NOT NULL,
                content TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                is_local BOOLEAN DEFAULT 0,
                FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
                FOREIGN KEY (sender_id) REFERENCES users(id)
            )");
        });
    }

    // ===== ФУНКЦИИ ДЛЯ РАБОТЫ С ИЗБРАННЫМ =====
    function createFavoritesChat(userId) {
        db.transaction(function(tx) {
            var res = tx.executeSql("SELECT c.id FROM chats c JOIN chat_participants cp ON c.id=cp.chat_id WHERE c.type=3 AND cp.user_id=?", [userId]);
            if (res.rows.length === 0) {
                tx.executeSql("INSERT INTO chats(type) VALUES(3)");
                var chatId = tx.executeSql("SELECT last_insert_rowid()").rows.item(0)["last_insert_rowid()"];
                tx.executeSql("INSERT INTO chat_participants(chat_id, user_id) VALUES(?, ?)", [chatId, userId]);
            }
        });
    }

    function getFavoritesMessages(userId) {
        var messages = [];
        db.readTransaction(function(tx) {
            var chat = tx.executeSql("SELECT c.id FROM chats c JOIN chat_participants cp ON c.id=cp.chat_id WHERE c.type=3 AND cp.user_id=?", [userId]);
            if (chat.rows.length > 0) {
                var chatId = chat.rows.item(0).id;
                var res = tx.executeSql("SELECT m.*, u.alias as sender_alias FROM messages m LEFT JOIN users u ON m.sender_id=u.id WHERE m.chat_id=?", [chatId]);
                for (var i = 0; i < res.rows.length; i++) {
                    messages.push(res.rows.item(i));
                }
            }
        });
        return messages;
    }

    // ===== ФУНКЦИИ ДЛЯ РАБОТЫ С ЧАТАМИ =====

    function getPersonalChats(userId) {
        var chats = [];

        db.transaction(function(tx) {
            // Используем обратные кавычки для многострочного SQL-запроса
            var query = tx.executeSql("
                SELECT
                    c.id AS chat_id,
                    c.type AS chat_type,
                    cp.user_id AS partner_id,
                    u.login AS user_login,
                    u.alias AS user_alias,
                    u.avatar AS user_avatar,
                    m.content AS last_message
                FROM chats c
                JOIN chat_participants cp ON c.id = cp.chat_id
                JOIN users u ON cp.user_id = u.id
                LEFT JOIN messages m ON c.last_message_id = m.id
                WHERE c.type = 1 AND c.id IN (
                    SELECT chat_id FROM chat_participants WHERE user_id = ?
                )
            ", [userId]);

            for (var i = 0; i < query.rows.length; i++) {
                var row = query.rows.item(i);
                chats.push({
                    id: row.chat_id,
                    type: row.chat_type,
                    login: row.user_login || "",
                    alias: row.user_alias || "",
                    avatar: row.user_avatar || "",
                    last_message: row.last_message || ""
                });
            }
        });

        return chats;
    }

    function getChatMessages(chatId) {
        var messages = [];
        db.readTransaction(function(tx) {
            var res = tx.executeSql("SELECT m.*, u.alias as sender_alias FROM messages m LEFT JOIN users u ON m.sender_id=u.id WHERE m.chat_id=? ORDER BY m.created_at", [chatId]);
            for (var i = 0; i < res.rows.length; i++) {
                messages.push(res.rows.item(i));
            }
        });
        return messages;
    }

    function sendMessage(chatId, senderId, messageText, isLocal) {
        // Добавляем сообщение в интерфейс
        messageList.model.append({
            content: messageText,
            senderAlias: "Вы",
            created_at: new Date().toISOString()
        });

        // Прокручиваем вниз
        Qt.callLater(function() {
            flickable.contentY = flickable.contentHeight - flickable.height;
        });

        // Сохраняем сообщение в базу данных асинхронно
        setTimeout(function() {
            db.transaction(function(tx) {
                tx.executeSql("INSERT INTO messages(chat_id, sender_id, content, is_local) VALUES(?, ?, ?, ?)",
                              [chatId, senderId, messageText, isLocal || 0]);
                var msgId = tx.executeSql("SELECT last_insert_rowid()").rows.item(0)["last_insert_rowid()"];
                tx.executeSql("UPDATE chats SET last_message_id=? WHERE id=?", [msgId, chatId]);
            });
        }, 0);
    }

    //создание индексов
    function createIndexes() {
        db.transaction(function(tx) {
            tx.executeSql("CREATE INDEX IF NOT EXISTS idx_chats_type ON chats(type)");
            tx.executeSql("CREATE INDEX IF NOT EXISTS idx_chat_participants_user_id ON chat_participants(user_id)");
            tx.executeSql("CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id)");
        });
    }

    function sendMessageOptimized(chatId, senderId, messageText) {
        db.transaction(function(tx) {
            // Все в одной транзакции
            tx.executeSql("INSERT INTO messages(chat_id, sender_id, content) VALUES(?, ?, ?)",
                         [chatId, senderId, messageText]);
            tx.executeSql("UPDATE chats SET last_message_id=last_insert_rowid() WHERE id=?", [chatId]);
        });
    }


    function saveToFavorites(userId, messageText, callback) {
        db.transaction(function(tx) {
            try {
                var chat = tx.executeSql(
                    "SELECT c.id FROM chats c JOIN chat_participants cp ON c.id=cp.chat_id WHERE c.type=3 AND cp.user_id=?",
                    [userId]
                );

                if (chat.rows.length > 0) {
                    var chatId = chat.rows.item(0).id;
                    tx.executeSql(
                        "INSERT INTO messages(chat_id, sender_id, content, is_local) VALUES(?, ?, ?, 1)",
                        [chatId, userId, messageText]
                    );
                    if (callback) callback(true);
                } else {
                    if (callback) callback(false);
                }
            } catch (e) {
                console.error("DB error:", e);
                if (callback) callback(false);
            }
        });
    }

    // ИНИЦИАЛИЗАЦИЯ БАЗЫ ДАННЫХ
    Component.onCompleted: {
        db = LocalStorage.openDatabaseSync("commie_db", "1.0");
        db.transaction(function(tx) {
            tx.executeSql("PRAGMA foreign_keys = ON");
        });

        // Создаем таблицы в правильном порядке
        createUsersTable();
        createContactsTable();
        createChatsTable();
        createChatParticipantsTable();
        createMessagesTable();

        createIndexes();

        // Создаем чат "Избранное" для активного пользователя
        var activeUser = getActiveUser();
        if (activeUser) {
            createFavoritesChat(activeUser.id);
        }
    }
}
