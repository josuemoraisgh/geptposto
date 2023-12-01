import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:intl/intl.dart';

import '../../faces/image_converter.dart';
import '../provider/assistido_provider_store.dart';
import 'package:image/image.dart' as imglib;
import 'assistido_models.dart';

class StreamAssistido extends Assistido {
  final AssistidosProviderStore assistidoStore;
  final StreamController<StreamAssistido> _chamadaController =
      StreamController<StreamAssistido>.broadcast();

  StreamAssistido(super.assistido, this.assistidoStore) : super.assistido();
  StreamAssistido.vazio(this.assistidoStore)
      : super(nomeM1: "Nome", logradouro: "Rua", endereco: "", numero: "0");
  Stream<StreamAssistido> get chamadaStream => _chamadaController.stream;

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
    assistidoStore.save(this);
  }

  void saveJustLocal() => assistidoStore.saveJustLocal(this);
  void saveJustRemote() => assistidoStore.addSaveJustRemote(this);

  @override
  Future<void> delete() async {
    delPhoto();
    assistidoStore.delete(this);
  }

  Future<void> delPhoto() async {
    //Atualiza os arquivos
    assistidoStore.syncStore.addSync('delImage', photoName);
    await assistidoStore.localStore.delFile(photoName);
    //Atualiza o cadastro
    photo = ["", Uint8List(0), []];
    save();
  }

  Future<Uint8List> addSetPhoto(final Uint8List uint8ListImage,
      {bool isUpload = true}) async {
    String photoFileName;
    //List<double> fotoPoints = [];
    Uint8List resp = Uint8List(0);
    if (uint8ListImage.isNotEmpty) {
      //Nomeando o arquivo
      final now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd_H-m-s');
      photoFileName = (photoName == "")
          ? '${nomeM1.replaceAll(RegExp(r"\s+"), "").toLowerCase()}_${formatter.format(now)}.jpg'
          : photoName;
      //Criando o arquivo - Armazenamento Local
      final file =
          await assistidoStore.localStore.addSetFile('aux.jpg', uint8ListImage);
      //Processando a imagem para o reconhecimento futuro
      imglib.Image? image = imglib.decodeJpg(uint8ListImage);
      if (image != null) {
        final inputImage = InputImage.fromFile(file);
        final faceDetected = await assistidoStore
            .faceDetectionService.faceDetector
            .processImage(inputImage);
        if (faceDetected.isNotEmpty) {
          image = isUpload
              ? cropFace(image, faceDetected[0], step: 80) ?? image
              : image;
          fotoPoints = (await assistidoStore.faceDetectionService
              .classificatorImage(image));
        }
        resp = imglib.encodeJpg(image);
        photo = [
          photoFileName,
          resp,
          //fotoPoints,
        ];
        saveJustLocal();
        if (isUpload) {
          assistidoStore.syncStore.addSync(
            'setImage',
            [photoFileName, resp],
          ).then((_) => saveJustRemote());
        }
        return resp;
      }
    }
    return resp;
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
      //fotoPoints = assistido.fotoPoints;
    }
    _chamadaController.sink.add(this);
  }

  Future<Uint8List> get photoUint8List async {
    if (this.photoName.isNotEmpty) {
      if (this.photoIntList.isNotEmpty) {
        return Uint8List.fromList(super.photoIntList);
      }
      var remoteImage = await assistidoStore.remoteStore
          .getFile('BDados_Images', this.photoName);
      if ((remoteImage != null) && (remoteImage.isNotEmpty)) {
          return this.addSetPhoto(base64Decode(remoteImage), isUpload: false);
      }
    }
    return Uint8List(0);
  }

  List<dynamic> get photo =>
      [super.photoName, photoUint8List, super.fotoPoints];
  set photo(List<dynamic> datas) {
    super.photoName = datas[0];
    photoIntList = datas[1];
    //super.fotoPoints = datas[2].cast<double>();
  }

  @override
  set chamada(String data) {
    super.chamada = data;
    _chamadaController.sink.add(this);
  }
}
