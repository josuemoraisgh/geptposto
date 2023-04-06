import 'dart:typed_data';

import '../models/assistido_models.dart';

abstract class AssistidoRemoteStorageInterface {
  Future<void> init();

  Future<int?> addData(
      Assistido? value); //Adiciona varias linhas no final da Base de Dados
  Future<String?> addFile(String targetDir, String fileName,
      Uint8List data); //Salva uma imagem na base de Dados

  Future<List<Assistido>?>
      getChanges(); //Lê todas as linhas apartir da primeira linha
  Future<Assistido?> getRow(int rowId); //Retorna o valor das linhas solicitadas
  Future<String?> getFile(String targetDir,
      String fileName); //Retorna as imagens da Base de Dados solicitadas

  Future<String?> setData(int rowsId,
      Assistido data); //Reescreve todas as linhas apartir da primeira linha
  Future<String?> setFile(String targetDir, String fileName,
      Uint8List data); //Retorna as imagens da Base de Dados solicitadas

  Future<dynamic> deleteData(String row); //Deleta um Linha
  Future<dynamic> deleteFile(
      String targetDir, String fileName); //Deleta um item
}
