import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';

import 'assistido_models.dart';

class StreamAssistido extends Assistido {
  Function(StreamAssistido value)? saveRemoteFunc;
  Function(StreamAssistido value)? saveLocalFunc;  
  Function(StreamAssistido value)? delRemoteFunc;
  final StreamController<int> _chamadaController =
      StreamController<int>.broadcast();
  final StreamController<int> _photoController =
      StreamController<int>.broadcast();

  StreamAssistido(Assistido assistido) : super.assistido(assistido);
  StreamAssistido.vazio()
      : super(nomeM1: "Nome", logradouro: "Rua", endereco: "", numero: "0");
  Stream<int> get chamadaStream => _chamadaController.stream;
  Stream<int> get photoStream => _photoController.stream;
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
    if (saveLocalFunc != null) {
      saveLocalFunc!(this); //Save no modo remoto
    } else {
      debugPrint("save Local Func - NULL");
    }    
  }

  Future<void> saveJustRemote() async {
    if (saveRemoteFunc != null) {
      saveRemoteFunc!(this); //Save no modo remoto
    } else {
      debugPrint("save Remote Func - NULL");
    }
  }

  @override
  Future<void> delete() async {
    if (delRemoteFunc != null) delRemoteFunc!(this);
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
    _chamadaController.sink.add(ident);    
  }

  @override
  set chamada(String data) {
    super.chamada = data;
    _chamadaController.sink.add(ident);
  }
}
