import 'dart:async';
import 'dart:typed_data';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:intl/intl.dart';

import '../../faces/image_converter.dart';
import '../stores/assistidos_store.dart';
import 'package:image/image.dart' as imglib;
import 'assistido_models.dart';

class StreamAssistido extends Assistido {
  final AssistidosStore assistidoStore;
  final StreamController<StreamAssistido> _chamadaController =
      StreamController<StreamAssistido>.broadcast();
  final StreamController<Uint8List> _photoController =
      StreamController<Uint8List>.broadcast();

  StreamAssistido(super.assistido, this.assistidoStore) : super.assistido();
  StreamAssistido.vazio(this.assistidoStore)
      : super(nomeM1: "Nome", logradouro: "Rua", endereco: "", numero: "0");
  Stream<StreamAssistido> get chamadaStream => _chamadaController.stream;
  Stream<Uint8List> get photoStream => _photoController.stream;
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
    await assistidoStore.addSaveJustLocal(this);
    await assistidoStore.addSaveJustRemote(this);
  }

  Future<void> saveJustLocal() async {
    assistidoStore.addSaveJustLocal(this);
  }

  Future<void> saveJustRemote() async {
    assistidoStore.addSaveJustRemote(this);
  }

  @override
  Future<void> delete() async {
    assistidoStore.delete(this);
    super.delete();
  }

  Future<bool> addSetPhoto(final Uint8List uint8ListImage,
      {bool isUpload = true}) async {
    String photoFileName;
    List<double> fotoPoints = [];
    if(uint8ListImage.isNotEmpty) {
      //Nomeando o arquivo
      final now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd_H-m-s');
      photoFileName = (photoName == "")
          ? '${nomeM1.replaceAll(RegExp(r"\s+"), "").toLowerCase()}_${formatter.format(now)}.jpg'
          : photoName;
      //Criando o arquivo - Armazenamento Local
      final file = await assistidoStore.localStore
          .addSetFile('aux.jpg', uint8ListImage);
      //Processando a imagem para o reconhecimento futuro
      imglib.Image? image = imglib.decodeJpg(uint8ListImage);
      if (image != null) {
        final inputImage = InputImage.fromFile(file);
        final faceDetected =
            await assistidoStore.assistidoMmlService.faceDetector.processImage(inputImage);
        if (faceDetected.isNotEmpty) {
          image = isUpload
              ? cropFace(image, faceDetected[0], step: 80) ?? image
              : image;
          fotoPoints = (await assistidoStore.assistidoMmlService.classificatorImage(image));
        }
        photo = [
          photoFileName,
          imglib.encodeJpg(image),
          fotoPoints,
        ];
        saveJustLocal();
        if (isUpload) {
          assistidoStore.syncStore.addSync(
            'setImage',
            [photoFileName, imglib.encodeJpg(image)],
          ).then((_) => saveJustRemote());
        }
        return true;
      }
    }
    return false;
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

  void copy(StreamAssistido? assistido) {
    if (assistido != null) {
      ident = assistido.ident;
      updatedApps = assistido.updatedApps;
      nomeM1 = assistido.nomeM1;
      photoName = assistido.photoName;
      condicao = assistido.condicao;
      dataNascM1 = assistido.dataNascM1;
      estadoCivil = assistido.estadoCivil;
      fone = assistido.fone;
      rg = assistido.rg;
      cpf = assistido.cpf;
      logradouro = assistido.logradouro;
      endereco = assistido.endereco;
      numero = assistido.numero;
      bairro = assistido.bairro;
      complemento = assistido.complemento;
      cep = assistido.cep;
      obs = assistido.obs;
      chamada = assistido.chamada;
      parentescos = assistido.parentescos;
      nomesMoradores = assistido.nomesMoradores;
      datasNasc = assistido.datasNasc;
      photoIntList = assistido.photoIntList;
      fotoPoints = assistido.fotoPoints;
    }
    _chamadaController.sink.add(this);
    _photoController.sink.add(photoUint8List);
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
    super.fotoPoints = datas[2].cast<double>();
    _photoController.sink.add(datas[1]);
  }

  @override
  set chamada(String data) {
    super.chamada = data;
    _chamadaController.sink.add(this);
  }
}
