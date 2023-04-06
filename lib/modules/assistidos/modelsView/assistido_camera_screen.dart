import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../models/assistido_models.dart';
import '../stores/assistidos_store.dart';
import 'package:intl/intl.dart';

class AssistidoCameraScreen extends StatefulWidget {
  final Assistido assistido;
  final AssistidosStore store;
  const AssistidoCameraScreen({
    Key? key,
    required this.assistido,
    required this.store,
  }) : super(key: key);

  @override
  State<AssistidoCameraScreen> createState() => _AssistidoCameraScreenState();
}

class _AssistidoCameraScreenState extends State<AssistidoCameraScreen> {
  bool isInited = false;
  bool isCompleter = false;
  late List<CameraDescription> _cameras;
  late CameraController _controller;

  Future<bool> init() async {
    if (!isInited) {
      _cameras = await Modular.get<Future<List<CameraDescription>>>();
      _controller = CameraController(_cameras.first, ResolutionPreset.medium);
      await _controller.initialize();
      isInited = true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: init(),
        builder: (BuildContext context, AsyncSnapshot<bool> init) {
          if (init.hasData) {
            if (init.data != null) {
              if (init.data!) {
                return FutureBuilder<File?>(
                  future: widget.store.getImg(widget.assistido),
                  builder:
                      (BuildContext context, AsyncSnapshot<File?> imageFile) {
                    if (imageFile.hasData) {
                      if (imageFile.data != null) {
                        return _imageCard(context, imageFile.data);
                      }
                    }
                    return _uploaderCard(context);
                  },
                );
              }
            }
          }
          return const Center(child: CircularProgressIndicator());
        },
      );

  Widget _imageCard(BuildContext context, File? imageFile) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Card(
            elevation: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _image(context, imageFile),
            ),
          ),
          const SizedBox(height: 24.0),
          _menu(imageFile),
        ],
      ),
    );
  }

  Widget _image(BuildContext context, File? imageFile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    if (imageFile != null) {
      return FutureBuilder<bool>(
          future: imageFile.exists(),
          builder: (BuildContext context, AsyncSnapshot<bool> isExists) {
            if (isExists.hasData) {
              return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 0.8 * screenWidth,
                    maxHeight: 0.7 * screenHeight,
                  ),
                  child: Image.file(imageFile));
            }
            return const Center(child: CircularProgressIndicator());
          });
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _menu(File? imageFile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: () {
            _clearImage();
          },
          backgroundColor: Colors.redAccent,
          tooltip: 'Delete',
          child: const Icon(Icons.delete),
        ),
      ],
    );
  }

  Widget _uploaderCard(BuildContext context) {
    return Center(
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: CameraPreview(
          _controller,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              height: 270.0,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DottedBorder(
                    radius: const Radius.circular(12.0),
                    borderType: BorderType.RRect,
                    dashPattern: const [8, 4],
                    color: Theme.of(context).highlightColor.withOpacity(1),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            color: Theme.of(context).highlightColor,
                            size: 64.0,
                          ),
                          const SizedBox(height: 24.0),
                          Text(
                            'Select and press to "Capture"',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Theme.of(context)
                                      .highlightColor
                                      .withOpacity(1),
                                ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    ElevatedButton(
                      onPressed: () {
                        _cameraImage();
                      },
                      child: const Text('Capture'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cameraImage() async {
    final pickedImage = await _controller.takePicture();
    final now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd_H-m-s');
    if (widget.assistido.photoName == "") {
      widget.assistido.photoName =
          '${widget.assistido.nomeM1.replaceAll(RegExp(r"\s+"), "")}_${formatter.format(now)}.jpg';
    }
    await widget.store
        .setImage(widget.assistido, await pickedImage.readAsBytes());
    setState(() {});
  }

  void _clearImage() {
    setState(() {
      widget.store.deleteImage(widget.assistido);
    });
  }
}
