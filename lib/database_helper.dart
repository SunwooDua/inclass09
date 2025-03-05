import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  Future<Database> get _database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'card_organizer.db');
    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  void _createTables(Database db, int version) async {
    await db.execute(
      '''CREATE TABLE folders(id INTEGER PRIMARY KEY, name TEXT, timestamp TEXT)''',
    );
    await db.execute(
      '''CREATE TABLE cards(id INTEGER PRIMARY KEY, name TEXT, suit TEXT, image_url TEXT, folder_id INTEGER, FOREIGN KEY(folder_id) REFERENCES folders(id))''',
    );
  }

  Future<List<Map<String, dynamic>>> getFolders() async {
    return await (await _database).query('folders');
  }

  Future<int> insertFolder(Map<String, dynamic> folder) async {
    return await (await _database).insert('folders', folder);
  }

  Future<int> insertCard(Map<String, dynamic> card) async {
    return await (await _database).insert('cards', card);
  }

  Future<List<Map<String, dynamic>>> getCardsByFolderId(int folderId) async {
    return await (await _database).query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
  }

  Future<void> deleteFolder(int folderId) async {
    final db = await _database;
    await db.delete('cards', where: 'folder_id = ?', whereArgs: [folderId]);
    await db.delete('folders', where: 'id = ?', whereArgs: [folderId]);
  }

  Future<void> deleteCard(int cardId) async {
    await (await _database).delete(
      'cards',
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }
}
