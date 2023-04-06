import 'dart:io';
import 'dart:typed_data';

import '../models/assistido_models.dart';

abstract class AssistidoLocalStorageInterface {
  Future<void> init();

  Future<List<int>?> add(List<Assistido>? values); //Adiciona varias linhas
  Future<File> addSetFile(Assistido assistido, Uint8List imageInUnit8List);

  Future<String?> setRow(Assistido? data); //Reescreve as linhas

  Future<Assistido?> getRow(int rowId); //Retorna o valor das linhas
  Future<List<Assistido>> getAll(); //Retorno toda a base de dados
  Future<File> getFile(String fileName); //Lê arquivo

  Future<bool> delRow(String row); //Deleta um Linha
  Future<bool> delAll(); //Limpa o Banco de Dados
  Future<bool> delFile(String fileName); //Deleta arquivo
}
