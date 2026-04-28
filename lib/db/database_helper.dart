import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        income_category TEXT,
        note TEXT NOT NULL,
        additional_note TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS wallet_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER NOT NULL DEFAULT 4280391411
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS income_sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
    CREATE TABLE monthly_budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      month TEXT NOT NULL,
      source_wallet TEXT NOT NULL,
      description TEXT NOT NULL,
      amount REAL NOT NULL,
      target_wallet TEXT NOT NULL,
      is_paid INTEGER NOT NULL DEFAULT 0,
      is_recurring INTEGER NOT NULL DEFAULT 1
    )
    ''');

    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS monthly_budgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          month TEXT NOT NULL,
          source_wallet TEXT NOT NULL,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          target_wallet TEXT NOT NULL,
          is_paid INTEGER NOT NULL DEFAULT 0,
          is_recurring INTEGER NOT NULL DEFAULT 1
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS wallet_methods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          color INTEGER NOT NULL DEFAULT 4280391411
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS income_sources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
    }

    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE wallet_methods ADD COLUMN color INTEGER NOT NULL DEFAULT 4280391411',
        );
      } catch (_) {}
    }
  }
  Future<void> _insertDefaultData(Database db) async {
    final walletMethods = [
      {'name': 'Cash', 'color': 0xFFD81B60}, // pink
      {'name': 'E-Wallet', 'color': 0xFF00ACC1}, // cyan
      {'name': 'QRIS', 'color': 0xFF5E35B1}, // purple
      {'name': 'Transfer', 'color': 0xFFFB8C00}, // orange
      {'name': 'Tabungan', 'color': 0xFF43A047}, // green
    ];

    final incomeSources = ['Gaji', 'Bonus', 'Uang Jajan', 'Utang'];

    for (final method in walletMethods) {
      await db.insert(
        'wallet_methods',
        method,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    for (final source in incomeSources) {
      await db.insert(
        'income_sources',
        {'name': source},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<int> updateTransaction(Map<String, dynamic> data, int id) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getWalletMethods() async {
    final db = await database;
    return db.query('wallet_methods', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getIncomeSources() async {
    final db = await database;
    return db.query('income_sources', orderBy: 'name ASC');
  }

  Future<void> insertWalletMethod(String name, int color) async {
    final db = await database;
    await db.insert(
      'wallet_methods',
      {
        'name': name,
        'color': color,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> insertIncomeSource(String name) async {
    final db = await database;
    await db.insert(
      'income_sources',
      {'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> updateWalletMethod(int id, String name, int color) async {
    final db = await database;
    await db.update(
      'wallet_methods',
      {
        'name': name,
        'color': color,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateIncomeSource(int id, String name) async {
    final db = await database;
    await db.update(
      'income_sources',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteWalletMethod(int id) async {
    final db = await database;
    await db.delete(
      'wallet_methods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteIncomeSource(int id) async {
    final db = await database;
    await db.delete(
      'income_sources',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertMonthlyBudget(Map<String, dynamic> data) async {
  final db = await database;
  return await db.insert('monthly_budgets', data);
}

Future<List<Map<String, dynamic>>> getMonthlyBudgetsByMonth(String month) async {
  final db = await database;
  return await db.query(
    'monthly_budgets',
    where: 'month = ?',
    whereArgs: [month],
    orderBy: 'id DESC',
  );
}

Future<List<Map<String, dynamic>>> getMonthlyBudgets() async {
  final db = await database;
  return await db.query(
    'monthly_budgets',
    orderBy: 'id DESC',
  );
}

Future<int> updateMonthlyBudget(Map<String, dynamic> data) async {
  final db = await database;
  return await db.update(
    'monthly_budgets',
    data,
    where: 'id = ?',
    whereArgs: [data['id']],
  );
}

Future<int> deleteMonthlyBudget(int id) async {
  final db = await database;
  return await db.delete(
    'monthly_budgets',
    where: 'id = ?',
    whereArgs: [id],
  );
}
}