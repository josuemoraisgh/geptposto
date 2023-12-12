import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../interfaces/remote_storage_interface.dart';
import '../models/device_info_model.dart';

class AssistidoRemoteStorageService implements RemoteStorageInterface {
  late final Dio provider;
  final String baseUrl = 'https://script.google.com';
  final DeviceInfoModel deviceInfoModel = DeviceInfoModel()
    ..initPlatformState();
  //static int _countConnection = 0;

  AssistidoRemoteStorageService({Dio? provider}) {
    this.provider = provider ?? Modular.get<Dio>();
  }

  @override
  Future<void> init() async {
    await deviceInfoModel.initPlatformState();
  }

  Future<dynamic> sendGet(
      {String? planilha,
      String table = "BDados",
      required String func,
      required String type,
      dynamic p1,
      dynamic p2,
      dynamic p3}) async {
    //while (_countConnection >= 15) {
    //so faz 10 requisições por vez.
    // await Future.delayed(const Duration(milliseconds: 500));
    //}
    //_countConnection++;
    var response = await provider.get(
      '$baseUrl/macros/s/AKfycbwKiHbY2FQ295UrySD3m8pG_JDJO5c8SFxQG4VQ9eo9pzZQMmEfpAZYKdhVJcNtznGV/exec',
      queryParameters: {
        "planilha": switch (planilha ?? "") {
          'Bezerra de Menezes' => '0',
          'Mãe Zeferina' => '2',
          'Simão Pedro' => '3',
          _ => '1',
        },
        "table": table,
        "func": func,
        "type": type,
        "userName": deviceInfoModel.identify,
        "p1": p1,
        "p2": p2,
        "p3": p3,
      },
    );
    try {
      if (response.data is Map) {
        var map = response.data as Map;
        if ((map["status"] ?? "ERROR") == "SUCCESS") {
          return map["items"];
        } else {
          debugPrint(
              "AssistidoRemoteStorageRepository - sendGet - ${map["status"]}");
        }
      } else {
        debugPrint("AssistidoRemoteStorageRepository - sendGet - $response");
        return "";
      }
    } catch (e) {
      debugPrint("AssistidoRemoteStorageRepository - sendGet - $response");
    }
    //_countConnection--;
    return null;
  }

  Future<dynamic> sendPost(
      {String? planilha,
      String table = "BDados",
      required String func,
      required String type,
      dynamic p1,
      dynamic p2,
      dynamic p3}) async {
    //while (_countConnection >= 15) {
    //so faz 10 requisições por vez.
    // await Future.delayed(const Duration(milliseconds: 500));
    //}
    //_countConnection++;
    //try {
    dynamic resp;
    await provider
        .post(
      '$baseUrl/macros/s/AKfycbwKiHbY2FQ295UrySD3m8pG_JDJO5c8SFxQG4VQ9eo9pzZQMmEfpAZYKdhVJcNtznGV/exec',
      queryParameters: {
        "planilha": switch (planilha ?? "") {
          'Bezerra de Menezes' => '0',
          'Mãe Zeferina' => '2',
          'Simão Pedro' => '3',
          _ => '1',
        },
        "table": table,
        "func": func,
        "type": type,
        "userName": deviceInfoModel.identify,
        "p1": p1,
        "p2": p2,
      },
      options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          }),
      /*options: Options(
        headers: {
          HttpHeaders.contentTypeHeader: "application/json",
        },
      ),*/
      //data: FormData.fromMap({'p3': await MultipartFile.fromFile('./text.txt',filename: 'upload.txt')}),
      data: jsonEncode({'p3': base64.encode(p3).toString()}),
    )
        .then(
      (value) async {
        Response response;
        if (value.statusCode == 302) {
          var location = value.headers["location"];
          response = await provider.get(location![0]);
        } else {
          response = value;
        }
        if (response.statusCode == 200) {
          var map = response.data as Map;
          if ((map["status"] ?? "Error") == "SUCCESS") {
            resp = map["items"];
          } else {
            debugPrint("POST ERROR - ${map["status"]}");
          }
        } else {
          debugPrint("POST ERROR - $response");
        }
      },
    );
    //} catch (e) {
    //debugPrint("POST ERROR - $e");
    //}
    //_countConnection--;
    return resp;
  }

  @override
  Future<int?> addData(List<dynamic>? value,
      {String? planilha, String table = "BDados"}) async {
    if (value != null) {
      return (sendGet(
        planilha: planilha,
        table: table,
        func: 'add',
        type: 'data',
        p1: value,
      ) as Future<int?>);
    }
    return null;
  }

  @override
  Future<String?> addFile(
      String targetDir, String fileName, Uint8List data) async {
    return (await sendGet(
        func: 'add',
        type: 'file',
        p1: targetDir,
        p2: fileName,
        p3: data)); //base64.encode(data).toString()));
  }

  @override
  Future<List<dynamic>?> getDatas(
      {String? planilha,
      String table = "BDados",
      String? columnFilter,
      String? valueFilter}) async {
    List<dynamic>? response = await sendGet(
        planilha: planilha,
        table: table,
        func: 'get',
        type: 'datas',
        p1: columnFilter ?? "",
        p2: valueFilter ?? "");
    return response;
    /*if (response != null) {
        if ((response as List).isNotEmpty) {
        return response.map((e) => Assistido.fromList(e)).toList();
      }
    }
    return null;*/
  }

  @override
  Future<List<dynamic>?> getChanges(
      {String? planilha, String table = "BDados"}) async {
    List<dynamic>? response = await sendGet(
      planilha: planilha,
      table: table,
      func: 'get',
      type: 'changes',
    );
    return response;
    /*if (response != null) {
        if ((response as List).isNotEmpty) {
        return response.map((e) => Assistido.fromList(e)).toList();
      }
    }
    return null;*/
  }

  @override
  Future<List<dynamic>?> getRow(String rowId,
      {String? planilha, String table = "BDados"}) async {
    final List<dynamic> response = await sendGet(
      planilha: planilha,
      table: table,
      func: 'get',
      type: 'datas',
      p1: rowId,
    );
    return response;
  }

  @override
  Future<String?> getFile(String targetDir, String fileName) async {
    if (fileName.isNotEmpty) {
      final String? response = await sendGet(
        func: 'get',
        type: 'file',
        p1: targetDir,
        p2: fileName,
      );
      return response;
    }
    return null;
  }

  @override
  Future<String?> setData(String rowsId, List<dynamic> data,
      {String? planilha, String table = "BDados"}) async {
    final String? response = await sendGet(
      planilha: planilha,
      table: table,
      func: 'set',
      type: 'data',
      p1: rowsId,
      p2: data,
    );
    return response;
  }

  @override
  Future<String?> setItens(String rowsId, String columnId, List<dynamic> data,
      {String? planilha, String table = "BDados"}) async {
    final String? response = await sendGet(
      planilha: planilha,
      table: table,
      func: 'set',
      type: 'itens',
      p1: rowsId,
      p2: columnId,
      p3: data,
    );
    return response;
  }

  @override
  Future<String?> setFile(
      String targetDir, String fileName, Uint8List data) async {
    final String? response = await sendPost(
        func: 'set',
        type: 'file',
        p1: targetDir,
        p2: fileName,
        p3: data); //base64.encode(data).toString());
    return response;
  }

  @override
  Future<dynamic> deleteData(String row,
      {String? planilha, String table = "BDados"}) async {
    final response = await sendGet(
      planilha: planilha,
      table: table,
      func: 'del',
      type: 'data',
      p1: row,
    );
    return response;
  }

  @override
  Future<dynamic> deleteFile(String targetDir, String fileName) async {
    final dynamic response = await sendGet(
      func: 'del',
      type: 'file',
      p1: targetDir,
      p2: fileName,
    );
    return response;
  }

  @override
  Future<String?> resetAll({String? planilha = "Euripedes Barsanulfo"}) async {
    await sendGet(
        planilha: planilha, table: "Config", func: 'reset', type: 'all');
    await sendGet(
        planilha: planilha, table: "BDados", func: 'reset', type: 'all');
    return "ok";
  }
}
