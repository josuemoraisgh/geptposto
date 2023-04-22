import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';

import 'assistido_models.dart';

class StreamAssistido extends Assistido {
  Function(StreamAssistido value)? saveJustLocalExt;
  Function(StreamAssistido value)? saveJustRemoteExt;
  Function(StreamAssistido value)? deleteExt;
  final StreamController<StreamAssistido> _chamadaController =
      StreamController<StreamAssistido>.broadcast();
  final StreamController<StreamAssistido> _photoController =
      StreamController<StreamAssistido>.broadcast();

  StreamAssistido(Assistido assistido) : super.assistido(assistido);
  StreamAssistido.vazio()
      : super(nomeM1: "Nome", logradouro: "Rua", endereco: "", numero: "0");
  Stream<StreamAssistido> get chamadaStream => _chamadaController.stream;
  Stream<StreamAssistido> get photoStream => _photoController.stream;
  Assistido get assistido => this;

  bool insertChamadaFunc(dateSelected) {
    if (!(chamada.toLowerCase().contains(dateSelected))) {
      changeItens("Chamada", "$chamada$dateSelected,");
      save();
      return true;
    }
    return false;
  }

  int chamadaToogleFunc(dateSelected) {
    if (chamada.toLowerCase().contains(dateSelected)) {
      changeItens("Chamada", chamada.replaceAll("$dateSelected,", ""));
      save();
      return -1;
    } else {
      changeItens("Chamada", "$chamada$dateSelected,");
      save();
      return 1;
    }
  }

  @override
  Future<void> save() async {
    await saveJustLocal();
    await saveJustRemote();
  }

  Future<void> saveJustLocal() async {
    if (saveJustLocalExt != null) {
      saveJustLocalExt!(this); //Save no modo remoto
    } else {
      debugPrint("save Local Func - NULL");
    }
  }

  Future<void> saveJustRemote() async {
    if (saveJustRemoteExt != null) {
      saveJustRemoteExt!(this); //Save no modo remoto
    } else {
      debugPrint("save Remote Func - NULL");
    }
  }

  @override
  Future<void> delete() async {
    if (deleteExt != null) deleteExt!(this);
    super.delete();
  }

  @override
  void changeItens(String? itens, dynamic datas) {
    if (itens != null && datas != null) {
      switch (itens) {
        case 'Foto':
          photo = datas;
          break;
        case 'Chamada':
          chamada = datas;
          break;
        default:
          super.changeItens(itens, datas);
          break;
      }
    }
  }

  Uint8List get photoUint8List => Uint8List.fromList(super.photoIntList);
  set photoUint8List(Uint8List data) {
    super.photoIntList = data;
  }

  List<dynamic> get photo =>
      [super.photoName, photoUint8List, super.fotoPoints];
  set photo(List<dynamic> datas) {
    super.photoName = datas[0];
    photoUint8List = datas[1];
    super.fotoPoints = datas[2];
    _chamadaController.sink.add(this);
  }

  @override
  set chamada(String data) {
    super.chamada = data;
    _chamadaController.sink.add(this);
  }
}
