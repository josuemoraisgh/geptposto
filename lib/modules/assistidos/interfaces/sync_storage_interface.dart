import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/sync_models.dart';

abstract class SyncStorageInterface {
  Future<void> init();
  Future<ValueListenable<Box<SyncType>>> listenable({List<dynamic>? keys});  
  Future<int> length();
  Future<bool> addSync(String key, dynamic syncValue); //Adiciona varias linhas
  Future<SyncType?> getSync(int index); //Adiciona varias linhas
  Future<bool> delSync(int index);
}
