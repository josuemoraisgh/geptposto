import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

abstract class ConfigStorageInterface {
  Future<void> init();
  Future<ValueListenable<Box<List<String>>>> listenable({List<dynamic>? keys});
  Future<bool> addConfig(
      String ident, List<String>? values); //Adiciona varias linhas
  Future<List<String>?> getConfig(String ident); //Retorna o valor das linhas
  Future<void> delConfig(String ident); //Deleta um Linha
  Stream watch(String key);
}
