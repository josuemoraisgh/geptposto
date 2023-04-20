import 'dart:async';
import 'dart:typed_data';
import 'assistido_models.dart';

class StreamAssistido extends Assistido {
  Function(StreamAssistido value)? saveRemoteFunc;
  Function(StreamAssistido value)? delRemoteFunc;
  final StreamController<String> _chamadaController =
      StreamController<String>.broadcast();
  final StreamController<String> _photoController =
      StreamController<String>.broadcast();

  StreamAssistido(Assistido assistido) : super.assistido(assistido);
  StreamAssistido.vazio()
      : super(nomeM1: "Nome", logradouro: "Rua", endereco: "", numero: "0");
  Stream<String> get chamadaStream => _chamadaController.stream;
  Stream<String> get photoStream => _photoController.stream;
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
    super.save(); //Save no modo local
    if (saveRemoteFunc != null) saveRemoteFunc!(this); //Save no modo remoto
  }

  Future<void> saveJustLocal() async {
    super.save(); //Save no modo local
  }

  Future<void> saveJustRemote() async {
    if (saveRemoteFunc != null) saveRemoteFunc!(this); //Save no modo remoto
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
          save();
          break;
      }
    }
  }

  List<dynamic> get photo =>
      [super.photoName, photoUint8List, super.fotoPoints];
  set photo(List<dynamic> datas) {
    super.fotoPoints = datas[2];
    super.photoName = datas[0];
    _chamadaController.sink.add(datas[0]);
    photoUint8List = datas[1];
  }

  Uint8List get photoUint8List => Uint8List.fromList(super.photoIntList);
  set photoUint8List(Uint8List data) {
    super.photoIntList = data;
    save();
  }

  @override
  set photoName(String data) {
    super.photoName = data;
    _chamadaController.sink.add(data);
    save();
  }

  @override
  set chamada(String data) {
    super.chamada = data;
    _chamadaController.sink.add(data);
    save();
  }
}
