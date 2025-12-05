import 'dart:async';
import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  StorageService._internal();

  late Database db;
  final store = StoreRef<int, Map<String, dynamic>>("records");

  // Initialize database
  Future<void> init() async {
    db = await databaseFactoryWeb.openDatabase("ssat_local_db.db");
  }

  // Save a complete record (inputs + outputs + images)
  Future<void> saveRecord(Map<String, dynamic> record) async {
    await store.add(db, record);
  }

  // Fetch all saved assessments
  Future<List<Map<String, dynamic>>> getAllRecords() async {
    final snapshots = await store.find(db);
    return snapshots.map((e) => e.value).toList();
  }

  // Delete a specific saved assessment
  Future<void> deleteRecord(Map<String, dynamic> record) async {
    final finder = Finder(
      filter: Filter.equals("timestamp", record["timestamp"]),
    );
    await store.delete(db, finder: finder);
  }
}
