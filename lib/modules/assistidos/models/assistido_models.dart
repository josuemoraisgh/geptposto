import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
part 'assistido_models.g.dart';

@HiveType(typeId: 0, adapterName: 'AssistidoAdapter')
class Assistido extends HiveObject {
  final StreamController<String> _chamadaController =
      StreamController<String>.broadcast();
  @HiveField(0)
  int ident;
  @HiveField(1)
  String updatedApps;
  @HiveField(2)
  String photoName;
  @HiveField(3)
  String nomeM1;
  @HiveField(4)
  String horario;
  @HiveField(5)
  String condicao;
  @HiveField(6)
  String dataNascM1;
  @HiveField(7)
  String estadoCivil;
  @HiveField(8)
  dynamic fone;
  @HiveField(9)
  dynamic rg;
  @HiveField(10)
  dynamic cpf;
  @HiveField(11)
  String logradouro;
  @HiveField(12)
  String endereco;
  @HiveField(13)
  dynamic numero;
  @HiveField(14)
  String bairro;
  @HiveField(15)
  String complemento;
  @HiveField(16)
  dynamic cep;
  @HiveField(17)
  String obs;
  @HiveField(18)
  String chamada;
  @HiveField(19)
  String parentescos;
  @HiveField(20)
  String nomesMoradores;
  @HiveField(21)
  String datasNasc;
  @HiveField(22)
  List<num>? fotoPoints;

  Assistido({
    this.ident = -1,
    this.updatedApps = "",
    required this.nomeM1,
    this.photoName = "",
    this.horario = "08:30",
    this.condicao = "ATIVO",
    this.dataNascM1 = "",
    this.estadoCivil = "Não declarado(a)",
    this.fone = "",
    this.rg = "",
    this.cpf = "",
    required this.logradouro,
    required this.endereco,
    required this.numero,
    this.bairro = "Morada Nova",
    this.complemento = "",
    this.cep = "",
    this.obs = "",
    this.chamada = "",
    this.parentescos = "",
    this.nomesMoradores = "",
    this.datasNasc = "",
  });

  Stream<String> get chamadaStream => _chamadaController.stream;
  void chamadaAdd(String chamada) {
    this.chamada = chamada;
    _chamadaController.sink.add(chamada);
  }

  Assistido changeItens(String? itens, dynamic datas) {
    if (itens != null && datas != null) {
      switch (itens) {
        case 'key':
          ident = datas;
          break;
        case 'Updated Apps':
          updatedApps = datas;
          break;
        case 'Morador01':
          nomeM1 = datas;
          break;
        case 'Foto':
          photoName = datas;
          break;
        case 'Horário':
          horario = datas;
          break;
        case 'Condição':
          condicao = datas;
          break;
        case 'Data de Nasc':
          dataNascM1 = datas;
          break;
        case 'Estado Civil':
          estadoCivil = datas;
          break;
        case 'Telefone':
          fone = datas;
          break;
        case 'RG':
          rg = datas;
          break;
        case 'CPF':
          cpf = datas;
          break;
        case 'Logradouro':
          logradouro = datas;
          break;
        case 'Endereço':
          endereco = datas;
          break;
        case 'Nº':
          numero = datas;
          break;
        case 'Bairro':
          bairro = datas;
          break;
        case 'Complemento':
          complemento = datas;
          break;
        case 'CEP':
          cep = datas;
          break;
        case 'Obs.:':
          obs = datas;
          break;
        case 'Chamada':
          chamada = datas;
          break;
        case 'Parentescos':
          parentescos = datas;
          break;
        case 'Nomes do Moradores':
          nomesMoradores = datas;
          break;
        case 'Datas Nasc':
          datasNasc = datas;
          break;
      }
    }
    return this;
  }

  factory Assistido.fromList(List<dynamic> value) {
    return Assistido(
      ident: value[0] as int,
      updatedApps: value[1],
      photoName: value[2].toString(),
      nomeM1: value[3].toString(),
      horario: value[4].toString(),
      condicao: value[5].toString(),
      dataNascM1: value[6].toString(),
      estadoCivil: value[7].toString(),
      fone: value[8].toString(),
      rg: value[9].toString(),
      cpf: value[10].toString(),
      logradouro: value[11],
      endereco: value[12].toString(),
      numero: value[13].toString(),
      bairro: value[14].toString(),
      complemento: value[15],
      cep: value[16].toString(),
      obs: value[17].toString(),
      chamada: value[18].toString(),
      parentescos: value[19].toString(),
      nomesMoradores: value[20].toString(),
      datasNasc: value[21].toString(),
    );
  }

  List<dynamic> toList() {
    return [
      photoName,
      nomeM1,
      horario,
      condicao,
      dataNascM1,
      estadoCivil,
      fone,
      rg,
      cpf,
      logradouro,
      endereco,
      numero,
      bairro,
      complemento,
      cep,
      obs,
      chamada,
      parentescos,
      nomesMoradores,
      datasNasc
    ];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Assistido &&
        other.ident == ident &&
        other.updatedApps == updatedApps &&
        other.photoName == photoName &&
        other.nomeM1 == nomeM1 &&
        other.horario == horario &&
        other.dataNascM1 == dataNascM1 &&
        other.estadoCivil == estadoCivil &&
        other.fone == fone &&
        other.rg == rg &&
        other.cpf == cpf &&
        other.logradouro == logradouro &&
        other.endereco == endereco &&
        other.numero == numero &&
        other.bairro == bairro &&
        other.complemento == complemento &&
        other.cep == cep &&
        other.obs == obs &&
        other.chamada == chamada &&
        other.parentescos == parentescos &&
        other.nomesMoradores == nomesMoradores &&
        other.datasNasc == datasNasc;
  }

  @override
  int get hashCode {
    return ident.hashCode ^
        updatedApps.hashCode ^
        photoName.hashCode ^
        nomeM1.hashCode ^
        horario.hashCode ^
        dataNascM1.hashCode ^
        nomeM1.hashCode ^
        horario.hashCode ^
        dataNascM1.hashCode ^
        estadoCivil.hashCode ^
        fone.hashCode ^
        rg.hashCode ^
        cpf.hashCode ^
        logradouro.hashCode ^
        endereco.hashCode ^
        numero.hashCode ^
        bairro.hashCode ^
        complemento.hashCode ^
        cep.hashCode ^
        obs.hashCode ^
        chamada.hashCode ^
        parentescos.hashCode ^
        nomesMoradores.hashCode ^
        datasNasc.hashCode;
  }
}
