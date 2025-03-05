import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get _databaseInstance async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, 'card_organizer.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE folders(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      timestamp TEXT
    )''');
    await db.execute('''CREATE TABLE cards(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      suit TEXT,
      image_url TEXT,
      folder_id INTEGER,
      FOREIGN KEY(folder_id) REFERENCES folders(id)
    )''');
  }

  // Get folders
  Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await _databaseInstance;
    return await db.query('folders');
  }

  // Insert folder
  Future<int> insertFolder(Map<String, dynamic> folder) async {
    final db = await _databaseInstance;
    return await db.insert('folders', folder);
  }

  // Insert card
  Future<int> insertCard(Map<String, dynamic> card) async {
    final db = await _databaseInstance;
    return await db.insert('cards', card);
  }

  // Get cards by folder ID
  Future<List<Map<String, dynamic>>> getCardsByFolderId(int folderId) async {
    final db = await _databaseInstance;
    return await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
  }

  // Delete folder and its associated cards
  Future<void> deleteFolder(int folderId) async {
    final db = await _databaseInstance;
    await db.delete('cards', where: 'folder_id = ?', whereArgs: [folderId]);
    await db.delete('folders', where: 'id = ?', whereArgs: [folderId]);
  }

  // Delete card
  Future<void> deleteCard(int cardId) async {
    final db = await _databaseInstance;
    await db.delete('cards', where: 'id = ?', whereArgs: [cardId]);
  }
}
