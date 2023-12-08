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
  final AssistidosProviderStore assistidoStore;
  final StreamController<StreamAssistido> _chamadaController =
      StreamController<StreamAssistido>.broadcast();
  static final countPresenteController = RxNotifier<int>(0);
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
      countPresenteController.value--;
      return -1;
    } else {
      changeItens("Chamada", "$chamada$dateSelected,");
      save();
      countPresenteController.value++;
      return 1;
    }
  }

  static int get countPresente => countPresenteController.value;
  static set countPresente(int value) {
    Future.delayed(const Duration(seconds: 0),
        () => countPresenteController.value = value);
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
    final mome = photoName;
    photoName = "";
    fotoPoints = [];
    await save();
    await assistidoStore.syncStore.addSync('delImage', mome);
    await assistidoStore.localStore.delFile(mome);
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
      final image = imglib.decodeJpg(uint8ListImage);
      if (image != null) {
        fotoPoints = (await assistidoStore.faceDetectionService
            .classificatorImage(image));
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
      assistidoStore.localStore.delFile(photoName);
      photoName =
          '${nomeM1.replaceAll(RegExp(r"\s+"), "").toLowerCase().replaceAllMapped(RegExp(r'[\W\[\] ]'), (Match a) => caracterMap.containsKey(a[0]) ? caracterMap[a[0]]! : a[0]!)}_${formatter.format(now)}.jpg';
      save();
      //Criando o arquivo - Armazenamento Local
      final file =
          await assistidoStore.localStore.addSetFile(photoName, uint8ListImage);
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
          //assistidoStore.localStore.delFile(photoName);
          assistidoStore.localStore.addSetFile(
            photoName,
            uint8ListImageAux,
          );
        }
      }
      //Salva a Imagem para o futuro
      assistidoStore.syncStore
          .addSync('setImage', [photoName, uint8ListImageAux]);
      return true;
    }
    return false;
  }

  @override
  void changeItens(String? itens, dynamic datas) {
    if (itens != null && datas != null) {
      switch (itens) {
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
      fotoPoints = assistido.fotoPoints;
    }
    _chamadaController.sink.add(this);
  }

  @override
  set chamada(String data) {
    super.chamada = data;
    _chamadaController.sink.add(this);
  }
}
