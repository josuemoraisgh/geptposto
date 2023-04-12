import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../interfaces/assistido_local_storage_interface.dart';
import '../models/assistido_models.dart';
import 'assistido_ml_service.dart';
import 'package:image/image.dart' as imglib;

//implements == interface
class AssistidoLocalStorageService implements AssistidoLocalStorageInterface {
  final _assistidoMLService = AssistidoMLService();
  Completer<Box<Assistido>> completerAssistidos = Completer<Box<Assistido>>();

  @override
  Future<void> init() async {
    if (!Hive.isBoxOpen('assistidosDados')) {
      Hive.registerAdapter(AssistidoAdapter());
    }
    if (!completerAssistidos.isCompleted) {
      completerAssistidos
          .complete(await Hive.openBox<Assistido>('assistidosDados'));
    }
  }

  @override
  Future<List<int>?> add(final List<Assistido>? values) async {
    final box = await completerAssistidos.future;
    List<int>? resp = [];
    if (values != null) {
      for (var value in values) {
        box.put(value.ident, value);
        resp.add(value.ident);
      }
      return resp;
    }
    return null;
  }

  @override
  Future<File> addSetFile(
      Assistido assistido, final Uint8List uint8ListImage) async {
    final fileName = assistido.photoName;
    final directory = await getApplicationDocumentsDirectory();

    var buffer = uint8ListImage.buffer;
    ByteData byteData = ByteData.view(buffer);
    final isExists = await File('${directory.path}/$fileName').exists();
    if (isExists == true) {
      await File('${directory.path}/$fileName').delete(recursive: true);
    }
    final ret = await File('${directory.path}/$fileName').writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return ret;
  }

  @override
  Future<String?> setRow(Assistido? data) async {
    final box = await completerAssistidos.future;
    if (data != null) {
      box.put(data.ident, data);
      return "SUCCESS";
    }
    return "ROW NOT FOUND";
  }

  @override
  Future<Assistido?> getRow(int rowId) async {
    final box = await completerAssistidos.future;
    return box.get(rowId);
  }

  @override
  Future<List<Assistido>> getAll() async {
    final box = await completerAssistidos.future;
    return box.values.toList();
  }

  @override
  Future<File> getFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  @override
  Future<bool> delRow(String row) async {
    try {
      final box = await completerAssistidos.future;
      box.delete(row);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> delAll() async {
    try {
      await Hive.deleteBoxFromDisk('assistidosDados');
      final box = await Hive.openBox<Assistido>('assistidosDados');
      completerAssistidos = Completer<Box<Assistido>>();
      if (!completerAssistidos.isCompleted) completerAssistidos.complete(box);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> delFile(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      if ((await File('${directory.path}/$fileName').exists()) == true) {
        await File('${directory.path}/$fileName').delete(recursive: true);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
