import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:intl/intl.dart';
import 'package:rx_notifier/rx_notifier.dart';

import '../../faces/image_converter.dart';
import '../../styles/styles.dart';
import '../provider/assistido_provider_store.dart';
import 'package:image/image.dart' as imglib;
import 'assistido_models.dart';

class StreamAssistido extends Assistido {
  bool isAddPhotoName = false;
  String changedPhotoName = "";
  final AssistidosProviderStore assistidoStore;
  final StreamController<StreamAssistido> _chamadaController =
      StreamController<StreamAssistido>.broadcast();
  static final countPresenteController = RxNotifier<int>(0);
  StreamAssistido(super.assistido, this.assistidoStore) : super.assistido();
  StreamAssistido.vazio(this.assistidoStore, {int key = -1})
      : super(
            ident: key,
            nomeM1: "Nome",
            logradouro: "Rua",
            endereco: "",
            numero: "0");
  Stream<StreamAssistido> get chamadaStream => _chamadaController.stream;

  Assistido get assistido => this;

  static int get countPresente => countPresenteController.value;
  static set countPresente(int value) {
    Future.delayed(const Duration(seconds: 0),
        () => countPresenteController.value = value);
  }

  Future<void> saveAll() async {
    await saveJustLocal();
    await saveJustRemote();
  }

  Future<void> saveJustLocal() async =>
      await assistidoStore.localStore.setRow(this);
  Future<void> saveJustRemote() async {
    if (isAddPhotoName == true) {
      await assistidoStore.syncStore
          .addSync('setImage', [photoName, photoUint8List]);
      isAddPhotoName = false;
    }
    if (changedPhotoName.isNotEmpty) {
      await assistidoStore.syncStore.addSync('delImage', changedPhotoName);
      changedPhotoName = "";
    }
    await assistidoStore.syncStore.addSync('set', this);
  }

  @override
  Future<void> delete() async {
    if (photoName.isNotEmpty) {
      assistidoStore.syncStore.addSync('delImage', photoName);
    }
    delPhoto();
    assistidoStore.delete(this);
  }

  Future<void> delPhoto() async {
    await assistidoStore.localStore.delFile(photoName);
  }

  Future<Uint8List> get photoUint8List async {
    Uint8List uint8ListImage = Uint8List(0);
    if (photoName.isNotEmpty) {
      final file = await assistidoStore.localStore.getFile(photoName);
      if (await file.exists()) {
        uint8ListImage = await file.readAsBytes();
      } else {
        var stringRemoteImage = await assistidoStore.remoteStore
            .getFile('BDados_Images', photoName);
        if ((stringRemoteImage != null) && (stringRemoteImage.isNotEmpty)) {
          uint8ListImage = base64Decode(stringRemoteImage);
          assistidoStore.localStore.addSetFile(photoName, uint8ListImage);
        }
      }
      if (uint8ListImage.isNotEmpty) {
        final image = imglib.decodeJpg(uint8ListImage);
        if (image != null) {
          fotoPoints = (await assistidoStore.faceDetectionService
              .classificatorImage(image));
        }
      }
    }
    return uint8ListImage;
  }

  Future<bool> addSetPhoto(final Uint8List uint8ListImage) async {
    if (uint8ListImage.isNotEmpty) {
      //Nomeando o arquivo
      Uint8List uint8ListImageAux = uint8ListImage;
      final now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd_H-m-s');
      if (photoName.isNotEmpty) {
        assistidoStore.localStore.delFile(photoName);
      }
      photoName =
          '${nomeM1.replaceAll(RegExp(r"\s+"), "").toLowerCase().replaceAllMapped(RegExp(r'[\W\[\] ]'), (Match a) => caracterMap.containsKey(a[0]) ? caracterMap[a[0]]! : a[0]!)}_${formatter.format(now)}.jpg';
      //Criando o arquivo - Armazenamento Local
      final file =
          await assistidoStore.localStore.addSetFile("aux", uint8ListImage);
      final inputImage = InputImage.fromFile(file);
      final faceDetected = await assistidoStore
          .faceDetectionService.faceDetector
          .processImage(inputImage);
      if (faceDetected.isNotEmpty) {
        final image = imglib.decodeJpg(uint8ListImage);
        if (image != null) {
          fotoPoints = (await assistidoStore.faceDetectionService
              .classificatorImage(image));
          uint8ListImageAux = imglib
              .encodeJpg(cropFace(image, faceDetected[0], step: 80) ?? image);
          await assistidoStore.localStore
              .addSetFile(photoName, uint8ListImageAux);
        }
      }
      saveJustLocal();
      return true;
    }
    return false;
  }

  bool insertChamadaFunc(dateSelected) {
    if (!(chamada.toLowerCase().contains(dateSelected))) {
      chamada = '$chamada$dateSelected,';
      Future.delayed(
          const Duration(seconds: 0), () => countPresenteController.value--);
      return true;
    }
    return false;
  }

  int chamadaToogleFunc(dateSelected) {
    if (chamada.toLowerCase().contains(dateSelected)) {
      chamada = chamada.replaceAll("$dateSelected,", "");
      Future.delayed(
          const Duration(seconds: 0), () => countPresenteController.value--);
      return -1;
    } else {
      chamada = "$chamada$dateSelected,";
      Future.delayed(
          const Duration(seconds: 0), () => countPresenteController.value++);
      return 1;
    }
  }

  @override
  set chamada(String value) {
    super.chamada = value;
    _chamadaController.sink.add(this);
    saveAll();
  }

  @override
  set photoName(String value) {
    if (value.isNotEmpty) {
      isAddPhotoName = true;
    }
    if ((value.isEmpty) && (photoName.isNotEmpty)) {
      if (changedPhotoName.isEmpty) {
        changedPhotoName = photoName;
      }
      fotoPoints = [];
      delPhoto();
    }
    super.photoName = value;
  }

  void copy(StreamAssistido? assistido) {
    if (assistido != null) {
      //ident = assistido.ident;
      //updatedApps = assistido.updatedApps;
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
      super.chamada = assistido.chamada;
      parentescos = assistido.parentescos;
      nomesMoradores = assistido.nomesMoradores;
      datasNasc = assistido.datasNasc;
      fotoPoints = assistido.fotoPoints;
    }
  }

  StreamAssistido copyWith() {
    return StreamAssistido(
        Assistido(
          ident: 0,
          updatedApps: updatedApps,
          nomeM1: nomeM1,
          photoName: photoName,
          condicao: condicao,
          dataNascM1: dataNascM1,
          estadoCivil: estadoCivil,
          fone: fone,
          rg: rg,
          cpf: cpf,
          logradouro: logradouro,
          endereco: endereco,
          numero: numero,
          bairro: bairro,
          complemento: complemento,
          cep: cep,
          obs: obs,
          chamada: chamada,
          parentescos: parentescos,
          nomesMoradores: nomesMoradores,
          datasNasc: datasNasc,
          fotoPoints: fotoPoints,
        ),
        assistidoStore);
  }

  @override
  void changeItens(String? itens, dynamic datas) {
    if (itens != null && datas != null) {
      switch (itens) {
        case 'Chamada':
          chamada = datas;
          break;
        case 'Foto':
          photoName = datas;
          break;
        default:
          super.changeItens(itens, datas);
          break;
      }
    }
  }
}
