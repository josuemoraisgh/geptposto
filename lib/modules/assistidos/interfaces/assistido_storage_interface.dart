import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/assistido_models.dart';

abstract class AssistidoStorageInterface {
  Future<void> init();
  Future<ValueListenable<Box<Assistido>>> listenable({List<dynamic>? keys});
  Future<List<dynamic>> getKeys();
  Future<File> addSetFile(String fileName, final Uint8List uint8ListImage);

  Future<String?> setRow(Assistido? data); //Reescreve as linhas

  Future<Assistido?> getRow(int rowId); //Retorna o valor das linhas
  Future<List<Assistido>> getAll(); //Retorno toda a base de dados
  Future<File> getFile(String fileName); //Lê arquivo

  Future<bool> delRow(String row); //Deleta um Linha
  Future<bool> delAll(); //Limpa o Banco de Dados
  Future<bool> delFile(String fileName); //Deleta arquivo
  Stream<BoxEvent> watch(String key);
}
