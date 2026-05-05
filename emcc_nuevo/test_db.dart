import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
void main() async {
  final dbPath = join(await getDatabasesPath(), 'emcc.db');
  if (!File(dbPath).existsSync()) { print('BD NO EXISTE'); return; }
  final db = await openDatabase(dbPath);
  final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
  print('TABLAS: $tables');
  for (final t in tables) {
    final name = t['name'];
    final count = await db.rawQuery('SELECT COUNT(*) as c FROM $name');
    print('$name: ${count.first['c']} registros');
    if (name == 'estudiante' || name == 'profesor' || name == 'directiva') {
      final rows = await db.query(name, limit: 2);
      for (final r in rows) {
        print('  ${r['nombre']} ${r['apellidos']} - Password: ${r['password']}');
      }
    }
  }
  await db.close();
}
