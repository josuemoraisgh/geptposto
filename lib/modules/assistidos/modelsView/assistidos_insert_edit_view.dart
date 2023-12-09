import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:geptposto/modules/assistidos/assistidos_controller.dart';
import 'package:intl/intl.dart';
import 'package:rx_notifier/rx_notifier.dart';
import '../models/stream_assistido_model.dart';

class AssistidosInsertEditView extends StatefulWidget {
  final StreamAssistido? assistido;
  const AssistidosInsertEditView({super.key, this.assistido});

  @override
  State<AssistidosInsertEditView> createState() =>
      _AssistidosInsertEditViewState();
}

class _AssistidosInsertEditViewState extends State<AssistidosInsertEditView> {
  late bool _isAdd;
  late final StreamAssistido _assistido;
  final _assistidosProviderStore =
      Modular.get<AssistidosController>().assistidosProviderStore;
  final isPhotoChanged = RxNotifier<bool>(false);
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  @override
  void initState() {
    _assistido = StreamAssistido.vazio(_assistidosProviderStore);
    _isAdd = widget.assistido == null ? true : false;
    if (_isAdd == false) {
      _assistido.copy(widget.assistido);
    }
    _assistido.saveJustLocal();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey1,
      autovalidateMode: AutovalidateMode.always, //.onUserInteraction,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _assistido.nomeM1,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                icon: Icon(Icons.person),
                labelText: 'Informe o nome',
              ),
              keyboardType: TextInputType.name,
              autovalidateMode: AutovalidateMode.always,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor entre com um nome';
                } else if (value.length < 4) {
                  return 'Nome muito pequeno';
                }
                return null;
              },
              onChanged: (v) => _assistido.nomeM1 = v,
            ),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Foto do Assistido",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      decorationColor: Colors.black),
                ),
                const SizedBox(height: 10),
                _getImage(context),
              ],
            ),
            const SizedBox(height: 15),
            Row(children: [
              const Icon(Icons.admin_panel_settings, color: Colors.black54),
              const SizedBox(width: 15),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  "Condição",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      decorationColor: Colors.black),
                ),
                DropdownButton<String>(
                  dropdownColor: Theme.of(context).colorScheme.background,
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                      decorationColor: Colors.black),
                  items: ['ATIVO', 'ESPERA', 'INATIVO']
                      .map((String dropDownStringItem) {
                    return DropdownMenuItem<String>(
                      value: dropDownStringItem,
                      child: Text(dropDownStringItem),
                    );
                  }).toList(),
                  onChanged: (String? novoItemSelecionado) {
                    if (novoItemSelecionado != null) {
                      _assistido.condicao = novoItemSelecionado;
                    }
                  },
                  value: _assistido.condicao.replaceAll(" ", ""),
                ),
              ])
            ]),
            TextFormField(
              initialValue: _assistido.dataNascM1,
              decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  icon: Icon(Icons.date_range),
                  labelText: 'Data de Nascimento'),
              keyboardType: TextInputType.datetime,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                DataInputFormatter(),
              ],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value != null) {
                  if (value.isNotEmpty && value.length < 10) {
                    return 'Data de Nascimento Incorreta!!';
                  }
                }
                return null;
              },
              onChanged: (v) => _assistido.dataNascM1 = v,
            ),
            const SizedBox(height: 15),
            Row(children: [
              const Icon(Icons.admin_panel_settings, color: Colors.black54),
              const SizedBox(width: 15),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  "Estado Civil",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      decorationColor: Colors.black),
                ),
                DropdownButton<String>(
                  dropdownColor: Theme.of(context).colorScheme.background,
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                      decorationColor: Colors.black),
                  items: [
                    'Nãodeclarado(a)',
                    'Solteiro(a)',
                    'Casado(a)',
                    'Amaziado(a)',
                    'Separado(a)',
                    'Divorciado(a)',
                    'Viúvo(a)'
                  ].map((String dropDownStringItem) {
                    return DropdownMenuItem<String>(
                      value: dropDownStringItem,
                      child: Text(dropDownStringItem),
                    );
                  }).toList(),
                  onChanged: (String? novoItemSelecionado) {
                    if (novoItemSelecionado != null) {
                      _assistido.estadoCivil = novoItemSelecionado;
                    }
                  },
                  value: _assistido.estadoCivil.replaceAll(" ", ""),
                ),
              ])
            ]),
            TextFormField(
              initialValue: _assistido.fone,
              decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  icon: Icon(Icons.phone),
                  labelText: 'Telefone'),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TelefoneInputFormatter(),
              ],
              validator: (value) {
                String pattern = r'(^\([0-9]{2}\) (?:9)?[0-9]{4}\-[0-9]{4}$)';
                RegExp regExp = RegExp(pattern);
                if (value != null) {
                  if (value.isNotEmpty && !regExp.hasMatch(value)) {
                    return 'Please enter valid mobile number';
                  }
                }
                return null;
              },
              onChanged: (v) => _assistido.fone = v,
            ),
            TextFormField(
              initialValue: _assistido.rg,
              decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  icon: Icon(Icons.assignment_ind),
                  labelText: "RG ou CNH"),
              validator: (value) => null,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (v) => _assistido.rg = v,
            ),
            TextFormField(
              initialValue: _assistido.cpf,
              decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  icon: Icon(Icons.attribution),
                  labelText: "CPF"),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CpfInputFormatter(),
              ],
              autovalidateMode: AutovalidateMode.always,
              validator: (value) {
                if (value != null) {
                  if ((value.isNotEmpty) && (!isCpf(value))) {
                    return 'CPF invalido!! Corriga por favor';
                  }
                }
                return null;
              },
              onChanged: (v) => _assistido.cpf = v,
            ),
            const SizedBox(height: 15),
            Row(children: [
              const Icon(Icons.admin_panel_settings, color: Colors.black54),
              const SizedBox(width: 15),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  "Logradouro",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      decorationColor: Colors.black),
                ),
                DropdownButton<String>(
                  dropdownColor: Theme.of(context).colorScheme.background,
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                      decorationColor: Colors.black),
                  items: [
                    'Rua',
                    'Avenida',
                    'Praça',
                    'Travessa',
                    'Passarela',
                    'Vila',
                    'Via',
                    'Viaduto',
                    'Viela',
                  ].map((String dropDownStringItem) {
                    return DropdownMenuItem<String>(
                      value: dropDownStringItem,
                      child: Text(dropDownStringItem),
                    );
                  }).toList(),
                  onChanged: (String? novoItemSelecionado) {
                    if (novoItemSelecionado != null) {
                      _assistido.logradouro = novoItemSelecionado;
                    }
                  },
                  value: _assistido.logradouro.replaceAll(" ", ""),
                ),
              ])
            ]),
            TextFormField(
              initialValue: _assistido.endereco,
              decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  icon: Icon(Icons.place),
                  labelText: "Endereço"),
              autovalidateMode: AutovalidateMode.always,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor entre com um enderço válido';
                } else if (value.length < 4) {
                  return 'Endereço muito pequeno';
                }
                return null;
              },
              onChanged: (v) => _assistido.endereco = v,
            ),
            TextFormField(
              initialValue: _assistido.numero,
              decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  icon: Icon(Icons.numbers),
                  labelText: "Número"),
              autovalidateMode: AutovalidateMode.always,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor entre com um número';
                }
                return null;
              },
              onChanged: (v) => _assistido.numero = v,
            ),
            TextFormField(
              initialValue: _assistido.bairro,
              decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  icon: Icon(Icons.south_america_outlined),
                  labelText: "Bairro"),
              validator: (value) => null,
              onChanged: (v) {
                _assistido.bairro = v;
              },
            ),
            TextFormField(
              initialValue: _assistido.complemento,
              decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  icon: Icon(Icons.travel_explore),
                  labelText: "Complemento"),
              validator: (value) => null,
              onChanged: (v) => _assistido.complemento = v,
            ),
            TextFormField(
              initialValue: _assistido.cep,
              decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  icon: Icon(Icons.elevator_sharp),
                  labelText: "CEP"),
              validator: (value) => null,
              onChanged: (v) => _assistido.cep = v,
            ),
            const SizedBox(height: 20),
            Table(
              border: TableBorder.all(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: <TableRow>[
                    TableRow(
                      children: <Widget>[
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.top,
                          child: Container(
                            width: 32,
                            color: Colors.green,
                            child: const Text(
                              "Nome",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.top,
                          child: Container(
                            width: 32,
                            color: Colors.green,
                            child: const Text(
                              "Idade",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] +
                  montaTabela(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _deleteMorador(context),
                  child: const Text("Del"),
                ),
                const SizedBox(width: 10), // give it width
                ElevatedButton(
                  onPressed: () {
                    setState(
                      () {
                        _assistido.nomesMoradores.add(" ");
                        _assistido.parentescos.add(" ");
                        _assistido.datasNasc.add(
                            DateFormat('dd/MM/yyyy').format(DateTime.now()));
                      },
                    );
                    _insertEditMorador(
                        context, _assistido.nomesMoradores.length - 1);
                  },
                  child: const Text("Add"),
                ),
                const SizedBox(width: 10), // give it width
              ],
            ),
            TextFormField(
                initialValue: _assistido.obs,
                decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    icon: Icon(Icons.check),
                    labelText: "OBS"),
                validator: (value) => null,
                maxLines: 5,
                onChanged: (v) => setState(() => _assistido.obs = v)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _assistido.nomeM1.length > 4
                      ? () async {
                          if (_formKey1.currentState!.validate()) {
                            _formKey1.currentState!.save();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Assistido Salvo')),
                            );
                            if (_isAdd) {
                              _assistido.saveJustRemote();
                            } else {
                              widget.assistido?.copy(_assistido);
                              widget.assistido?.saveAll();
                            }
                            Modular.to.pop();
                          }
                        }
                      : null,
                  child: const Text("Salvar Aterações"),
                ),
                const SizedBox(width: 10), // give it width
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMorador(BuildContext context) {
    var condicoes = List.generate(
      _assistido.nomesMoradores.length,
      (index) {
        final st = _assistido.nomesMoradores[index].split(" ");
        return '${st[0]} ${st.length > 1 ? st[1] : ""}';
      },
    );
    final RxNotifier<String> opcoes = RxNotifier<String>(condicoes[0]);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RxBuilder(
          builder: (BuildContext context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.background,
            title: const Text("Delete Morador"),
            titleTextStyle: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
            actionsOverflowButtonSpacing: 20,
            actions: [
              ElevatedButton(
                  onPressed: Modular.to.pop, child: const Text("Cancelar")),
              ElevatedButton(
                  onPressed: () {
                    final int index = condicoes.indexOf(opcoes.value);
                    setState(() {
                      _assistido.datasNasc.removeAt(index);
                      _assistido.nomesMoradores.removeAt(index);
                      _assistido.parentescos.removeAt(index);
                    });
                    Modular.to.pop();
                  },
                  child: const Text("Deletar")),
            ],
            content: Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: Colors.black54),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Condição",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          decorationColor: Colors.black),
                    ),
                    DropdownButton<String>(
                      value: opcoes.value,
                      icon: const Icon(Icons.arrow_downward),
                      elevation: 16,
                      dropdownColor: Theme.of(context).colorScheme.background,
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                          decorationColor: Colors.black),
                      items: condicoes.map((String dropDownStringItem) {
                        return DropdownMenuItem<String>(
                          value: dropDownStringItem,
                          child: Text(dropDownStringItem),
                        );
                      }).toList(),
                      onChanged: (String? novoItemSelecionado) {
                        if (novoItemSelecionado != null) {
                          _formKey2.currentState?.didChangeDependencies();
                          opcoes.value = novoItemSelecionado;
                        }
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _insertEditMorador(BuildContext context, int index) {
    var condicoes = ['Cônjuge', 'Filho(a)', 'Neto(a)', 'Agregado(a)', ' '];
    String datasNasc = _assistido.datasNasc[index];
    String nomesMoradores = _assistido.nomesMoradores[index];
    final RxNotifier<bool> change = RxNotifier<bool>(false);
    final RxNotifier<String> parentescos = RxNotifier<String>(
        " "); //Tem que ser igual ao ultimo elemento de condicoes
    if (_assistido.parentescos.length > index) {
      if (condicoes.contains(_assistido.parentescos[index])) {
        parentescos.value = _assistido.parentescos[index];
      }
    } else {
      for (int i = _assistido.parentescos.length; i <= index; i++) {
        _assistido.parentescos.add(" ");
      }
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RxBuilder(
          builder: (BuildContext context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.background,
            title: const Text("Insira/Edit Moradores"),
            titleTextStyle: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
            actionsOverflowButtonSpacing: 20,
            actions: [
              ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Modular.to.pop();
                  },
                  child: const Text("Cancelar")),
              ElevatedButton(
                  onPressed: _formKey2.currentState?.validate() ?? false
                      ? () {
                          setState(
                            () {
                              _assistido.datasNasc[index] = datasNasc;
                              _assistido.nomesMoradores[index] = nomesMoradores;
                              _assistido.parentescos[index] = parentescos.value;
                            },
                          );
                          Modular.to.pop();
                        }
                      : null,
                  child: const Text("Salvar")),
            ],
            content: Form(
              key: _formKey2,
              autovalidateMode: AutovalidateMode.always, //.onUserInteraction,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: nomesMoradores,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        icon: Icon(Icons.person),
                        labelText: 'Informe o nome',
                      ),
                      keyboardType: TextInputType.name,
                      autovalidateMode: AutovalidateMode.always,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor entre com um nome';
                        } else if (value.length < 4) {
                          return 'Nome muito pequeno';
                        }
                        return null;
                      },
                      onChanged: (v) {
                        nomesMoradores = v;
                        _formKey2.currentState?.didChangeDependencies();
                        change.value = !change.value;
                      },
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings,
                            color: Colors.black54),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Condição",
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                  decorationColor: Colors.black),
                            ),
                            DropdownButton<String>(
                              value: parentescos.value,
                              icon: const Icon(Icons.arrow_downward),
                              elevation: 16,
                              dropdownColor:
                                  Theme.of(context).colorScheme.background,
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black54,
                                  decorationColor: Colors.black),
                              items: condicoes.map((String dropDownStringItem) {
                                return DropdownMenuItem<String>(
                                  value: dropDownStringItem,
                                  child: Text(dropDownStringItem),
                                );
                              }).toList(),
                              onChanged: (String? novoItemSelecionado) {
                                if (novoItemSelecionado != null) {
                                  _formKey2.currentState
                                      ?.didChangeDependencies();
                                  parentescos.value = novoItemSelecionado;
                                }
                              },
                            )
                          ],
                        )
                      ],
                    ),
                    TextFormField(
                      initialValue: datasNasc,
                      decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          icon: Icon(Icons.date_range),
                          labelText: 'Data de Nascimento'),
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        DataInputFormatter(),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value != null) {
                          if (value.isEmpty) {
                            return 'Data de Nascimento Incorreta!!';
                          }
                        }
                        return null;
                      },
                      onChanged: (v) {
                        datasNasc = v;
                        _formKey2.currentState?.didChangeDependencies();
                        change.value = !change.value;
                      },
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _getImage(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return ValueListenableBuilder(
      valueListenable: isPhotoChanged,
      builder: (BuildContext context, bool isphoto, _) => FutureBuilder(
        future: _assistido.photoUint8List,
        builder: (BuildContext context, AsyncSnapshot photoUint8List) {
          return photoUint8List.hasData
              ? Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth,
                      maxHeight: screenHeight,
                    ),
                    child: (photoUint8List.data!.isNotEmpty)
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.memory(
                                  Uint8List.fromList(photoUint8List.data)),
                              const SizedBox(height: 4.0),
                              FloatingActionButton(
                                onPressed: () async {
                                  _assistido.photoName = "";
                                  setState(() {});
                                },
                                backgroundColor: Colors.redAccent,
                                tooltip: 'Delete',
                                child: const Icon(Icons.delete),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/semFoto.png",
                                fit: BoxFit.cover,
                                width: 250,
                                height: 250,
                              ),
                              const SizedBox(height: 20.0),
                              FloatingActionButton(
                                onPressed: () {
                                  Modular.to.pushNamed("faces", arguments: {
                                    'assistido': _assistido,
                                    'isPhotoChanged': isPhotoChanged
                                  });
                                },
                                backgroundColor: Colors.green,
                                tooltip: 'New',
                                child: const Icon(Icons.add_a_photo),
                              ),
                            ],
                          ),
                  ),
                )
              : const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  List<TableRow> montaTabela() {
    List<TableRow> resp = <TableRow>[];
    if (_assistido.nomesMoradores.isNotEmpty) {
      final list1 = _assistido.nomesMoradores;
      final list2 = _assistido.datasNasc;
      for (int i = 0; i < list1.length; i++) {
        var aux = list1[i].split(" ");
        var nome = '${aux[0]} ${(aux.length > 1 ? aux[1] : "")}';
        resp.add(
          TableRow(
            children: <Widget>[
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.top,
                child: Container(
                  width: 32,
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _insertEditMorador(context, i),
                        child: const Icon(
                          Icons.edit,
                          size: 30.0,
                          color: Colors.blue,
                          semanticLabel: 'Edit',
                        ),
                      ),
                      Text(
                        nome,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.top,
                child: Container(
                  width: 32,
                  color: Colors.white,
                  child: Text(
                    (DateTime.now().year -
                            DateFormat('dd/MM/yyyy').parse(list2[i]).year)
                        .toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
    return resp;
  }

  bool isCpf(String? cpf) {
    if (cpf == null) {
      return false;
    }

    // get only the numbers
    final numbers = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    // Test if the CPF has 11 digits
    if (numbers.length != 11) {
      return false;
    }
    // Test if all CPF digits are the same
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) {
      return false;
    }

    // split the digits
    final digits = numbers.split('').map(int.parse).toList();

    // Calculate the first verifier digit
    var calcDv1 = 0;
    for (var i in Iterable<int>.generate(9, (i) => 10 - i)) {
      calcDv1 += digits[10 - i] * i;
    }
    calcDv1 %= 11;

    final dv1 = calcDv1 < 2 ? 0 : 11 - calcDv1;

    // Tests the first verifier digit
    if (digits[9] != dv1) {
      return false;
    }

    // Calculate the second verifier digit
    var calcDv2 = 0;
    for (var i in Iterable<int>.generate(10, (i) => 11 - i)) {
      calcDv2 += digits[11 - i] * i;
    }
    calcDv2 %= 11;

    final dv2 = calcDv2 < 2 ? 0 : 11 - calcDv2;

    // Test the second verifier digit
    if (digits[10] != dv2) {
      return false;
    }

    return true;
  }
}
