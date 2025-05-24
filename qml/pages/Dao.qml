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
        enc_private_key TEXT NOT NULL DEFAULT '',
        enc_public_key TEXT NOT NULL DEFAULT '',
        ip TEXT NOT NULL,
        port INTEGER NOT NULL,
        is_active BOOLEAN NOT NULL,
        alias TEXT,
        avatar TEXT)");
        });
    }
    //функция для добавления данных пользователя при регистрации
    function insertUser(login, password, publicKey, privateKey, ip, port, isActive, enc_private_key, enc_public_key){
        db.transaction(function(tx){
            tx.executeSql("INSERT INTO users(login, password, public_key, private_key, ip, port, is_active, enc_private_key, enc_public_key) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)", [login, password, publicKey, privateKey, ip, port, isActive, enc_private_key, enc_public_key]);
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
                    enc_public_key TEXT NOT NULL DEFAULT '',
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                )");
        });
    }
    function updateContact(login, ip, port, aliias, avatar, user_id, public_key, enc_public_key) {
        db.transaction(function (tx) {
            tx.executeSql("UPDATE contacts SET login=?, ip=?, port=?, alias=?, avatar=?, enc_public_key=? WHERE user_id=? AND public_key=?", [login, ip, port, aliias, avatar, enc_public_key, user_id, public_key]);
        });
    }
    //получаем список контактов
    function getContacts() {
        var records = [];
        db.readTransaction(function(tx) {
            var result = tx.executeSql("SELECT * FROM contacts");
            for (var i = 0; i < result.rows.length; i++) {
                var record = result.rows.item(i);
                records.push({"id": record.id, "login": record.login, "public_key": record.public_key, "ip": record.ip, "port": record.port, "alias": record.alias, "avatar": record.avatar, "enc_public_key":record.enc_public_key});
            }
        });
        return records;
    }
    //функция для добавления контакта в таблицу contacts
    function insertContact(user_id, login, publicKey, ip, port, aliias, avatar, enc_public_key) {
        db.transaction(function(tx) {
            tx.executeSql("INSERT INTO contacts(user_id, login, public_key, ip, port, alias, avatar, enc_public_key) VALUES(?, ?, ?, ?, ?, ?, ?, ?)", [user_id, login, publicKey, ip, port, aliias, avatar, enc_public_key]);
        });
    }
    //функция для получения контактов пользователя по его id
    function getContactByUserID(user_id) {
        var records = [];
        db.readTransaction(function(tx) {
            var query = tx.executeSql('SELECT * FROM contacts WHERE user_id = ?', [user_id]);
            for (var i = 0; i < query.rows.length; i++) {
                var record = query.rows.item(i);
                records.push({"id": record.id, "login": record.login, "public_key": record.public_key, "ip": record.ip, "port": record.port, "alias": record.alias, "avatar": record.avatar, "enc_public_key":record.enc_public_key});
            }
        });
        return records;
    }

    // Получить пользователя по ID
    function getUserById(userId) {
        var result;
        db.readTransaction(function(tx) {
            var query = tx.executeSql('SELECT * FROM users WHERE id = ?', [userId]);
            if (query.rows.length > 0) {
                result = query.rows.item(0);
            }
        });
        return result;
    }

    // Получить контакт по ID
    function getContactById(contactId) {
        var result;
        db.readTransaction(function(tx) {
            var query = tx.executeSql('SELECT * FROM contacts WHERE id = ?', [contactId]);
            if (query.rows.length > 0) {
                result = query.rows.item(0);
            }
        });
        return result;
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
            tx.executeSql("
                CREATE TABLE IF NOT EXISTS chat_participants (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    chat_id INTEGER NOT NULL,
                    user_id INTEGER NOT NULL,           -- обязательное поле
                    contact_id INTEGER,                 -- опциональное
                    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
                    FOREIGN KEY (user_id) REFERENCES users(id),
                    FOREIGN KEY (contact_id) REFERENCES contacts(id)
                )
            ");
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
                is_encrypted BOOLEAN NOT NULL DEFAULT 0,
                encrypted_content TEXT,
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
            var query = tx.executeSql("
                SELECT
                    c.id AS chat_id,
                    c.type AS chat_type,

                    cnt.id AS contact_id,
                    cnt.login AS contact_login,
                    cnt.alias AS contact_alias,
                    cnt.avatar AS contact_avatar,
                    cnt.public_key AS contact_public_key,
                    cnt.ip AS contact_ip,
                    cnt.port AS contact_port,

                    m.content AS last_message
                FROM chats c
                JOIN chat_participants cp ON c.id = cp.chat_id
                LEFT JOIN contacts cnt ON cp.contact_id = cnt.id
                LEFT JOIN messages m ON c.last_message_id = m.id
                WHERE c.type = 1
                  AND cp.user_id = ?
                  AND cp.contact_id IS NOT NULL
            ", [userId]);

            for (var i = 0; i < query.rows.length; i++) {
                var row = query.rows.item(i);
                chats.push({
                    id: row.chat_id,
                    type: row.chat_type,

                    contact_id: row.contact_id,
                    contact_login: row.contact_login || "",
                    contact_alias: row.contact_alias || "",
                    contact_avatar: row.contact_avatar || "",
                    contact_public_key: row.contact_public_key || "",
                    contact_ip: row.contact_ip || "",
                    contact_port: row.contact_port || "",

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

    function createPersonalChatsTable() {
        db.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS personalchats (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "user_id INTEGER NOT NULL," +
                "contact_id INTEGER NOT NULL," +
                "FOREIGN KEY(user_id) REFERENCES users(id)," +
                "FOREIGN KEY(contact_id) REFERENCES contacts(id)" +
                ")");
        });
    }

    function createPersonalMessagesTable() {
        db.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS personalmessages (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "chat_id INTEGER NOT NULL," +
                "is_sent BOOLEAN NOT NULL," +
                "content TEXT NOT NULL,"+
                "timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP," +
                "FOREIGN KEY(chat_id) REFERENCES personalchats(id)" +
                ")");
        });
    }

    // Получить или создать чат между пользователем и контактом
    function getOrCreatePersonalChat(userId, contactId) {
        var result;
        db.readTransaction(function(tx) {
            var query = tx.executeSql(
                "SELECT * FROM personalchats WHERE user_id = ? AND contact_id = ?",
                [userId, contactId]
            );
            if (query.rows.length > 0) {
                result = query.rows.item(0);
            }
        });

        if (!result) {
            db.transaction(function(tx) {
                tx.executeSql(
                    "INSERT INTO personalchats(user_id, contact_id) VALUES (?, ?)",
                    [userId, contactId]
                );
                var chatId = tx.executeSql("SELECT last_insert_rowid()").rows.item(0)["last_insert_rowid()"];
                result = { id: chatId, user_id: userId, contact_id: contactId };
            });
        }

        return result;
    }

    // Добавить сообщение в личный чат
    function addPersonalMessage(chatId, isSent, encryptedContent) {
        db.transaction(function(tx) {
            tx.executeSql(
                "INSERT INTO personalmessages(chat_id, is_sent, content) VALUES (?, ?, ?)",
                [chatId, isSent, encryptedContent]
            );
        });
    }
    // Добавляет зашифрованное сообщение с подписью
    function addPersonalMessageWithoutSignature(chatId, isSent, encryptedContent) {
        db.transaction(function(tx) {
            tx.executeSql(
                "INSERT INTO personalmessages(chat_id, is_sent, content) VALUES (?, ?, ?)",
                [chatId, isSent, encryptedContent]
            );
        });
    }

    // Загружает все сообщения для личного чата
    function loadPersonalMessages(chatId) {
        var messages = [];
        db.readTransaction(function(tx) {
            var query = tx.executeSql(
                "SELECT id, chat_id, is_sent, content, timestamp FROM personalmessages WHERE chat_id = ? ORDER BY timestamp ASC",
                [chatId]
            );

            for (var i = 0; i < query.rows.length; i++) {
                messages.push(query.rows.item(i));
            }
        });

        return messages;
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
        createPersonalChatsTable();
        createPersonalMessagesTable();

        createIndexes();

        // Создаем чат "Избранное" для активного пользователя
        var activeUser = getActiveUser();
        if (activeUser) {
            createFavoritesChat(activeUser.id);
        }
    }
}
