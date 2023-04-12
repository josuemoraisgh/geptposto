import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';

import '../models/assistido_models.dart';
import 'package:image/image.dart' as imglib;

abstract class AssistidoLocalStorageInterface {
  Future<void> init();

  Future<List<int>?> add(List<Assistido>? values); //Adiciona varias linhas
  Future<File> addSetFile(Assistido assistido, final imglib.Image imageLib,
      final InputImage inputImage);

  Future<String?> setRow(Assistido? data); //Reescreve as linhas

  Future<Assistido?> getRow(int rowId); //Retorna o valor das linhas
  Future<List<Assistido>> getAll(); //Retorno toda a base de dados
  Future<File> getFile(String fileName); //Lê arquivo

  Future<bool> delRow(String row); //Deleta um Linha
  Future<bool> delAll(); //Limpa o Banco de Dados
  Future<bool> delFile(String fileName); //Deleta arquivo
}
