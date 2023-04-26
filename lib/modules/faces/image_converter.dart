import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';

imglib.Image? cameraImageToImage(CameraImage cameraImage) {
  try {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return convertYUV420ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return convertBGRA8888(cameraImage);
    }
    throw Exception('Image format not supported');
  } catch (e) {
    debugPrint("ERROR:$e");
  }
  return null;
}

imglib.Image convertBGRA8888(CameraImage image) {
  return imglib.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: image.planes[0].bytes.buffer,
    format: imglib.Format.uint8,
    numChannels: 4,
    order: imglib.ChannelOrder.bgra
  );
}

imglib.Image convertYUV420ToImage(CameraImage image) {
  int width = image.width;
  int height = image.height;
  var img = imglib.Image(width: width, height: height);
  //const int hexFF = 0xFF000000;
  final int uvyButtonStride = image.planes[1].bytesPerRow;
  final int? uvPixelStride = image.planes[1].bytesPerPixel;
  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      final int uvIndex =
          uvPixelStride! * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
      final int index = y * width + x;
      final yp = image.planes[0].bytes[index];
      final up = image.planes[1].bytes[uvIndex];
      final vp = image.planes[2].bytes[uvIndex];
      int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
      int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
          .round()
          .clamp(0, 255);
      int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
      if (img.data != null) {
        if (img.data!.length >= index) {
          img.data!.setPixelRgb(x, y, r, g, b);
        }
      }
    }
  }
  return img;
}

/*
CameraImage? convertInputImageToCameraImage(InputImage inputImage){
  return CameraImage();
}
*/
InputImage? convertCameraImageToInputImage(
    CameraImage image, int sensorOrientation) {
  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();

  final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
  final imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation);
  if (imageRotation == null) return null;
  final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
  if (inputImageFormat == null) return null;

  final planeData = image.planes.map(
    (Plane plane) {
      return InputImagePlaneMetadata(
        bytesPerRow: plane.bytesPerRow,
        height: plane.height,
        width: plane.width,
      );
    },
  ).toList();

  final inputImageData = InputImageData(
    size: imageSize,
    imageRotation: imageRotation,
    inputImageFormat: inputImageFormat,
    planeData: planeData,
  );

  final inputImage =
      InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  return inputImage;
}

imglib.Image copyCrop(imglib.Image image,
    {required int x, required int y, required int width, required int height}) {
  imglib.Image imageResp = imglib.Image(
      height: height,
      width: width,
      format: image.format,
      exif: image.exif,
      iccp: image.iccProfile);

  for (int yi = 0, sy = y; yi < height; ++yi, ++sy) {
    for (int xi = 0, sx = x; xi < width; ++xi, ++sx) {
      imageResp.setPixel(xi, yi, image.getPixel(sx, sy));
    }
  }
  return imageResp;
}

imglib.Image? cropFace(imglib.Image image, Face faceDetected, {int step = 10}) {
  double x = faceDetected.boundingBox.left - 10;
  double y = faceDetected.boundingBox.top - step;
  double w = faceDetected.boundingBox.width + 20;
  double h = faceDetected.boundingBox.height + 2 * step;
  final imageResp = imglib.copyCrop(image,
      x: x.round(), y: y.round(), width: w.round(), height: h.round());
  return imglib.decodeJpg(imglib.encodeJpg(imageResp));
}

imglib.Image convertCameraImageToImage(CameraImage cameraImage) {
  var img = cameraImageToImage(cameraImage);
  var img1 = imglib.copyRotate(img!, angle: -90);
  return img1;
}

Float32List imageToByteListFloat32(imglib.Image image) {
  var convertedBytes = Float32List(1 * 112 * 112 * 3);
  var buffer = Float32List.view(convertedBytes.buffer);
  int pixelIndex = 0;

  for (var i = 0; i < 112; i++) {
    for (var j = 0; j < 112; j++) {
      var pixel = image.getPixelSafe(j, i);
      buffer[pixelIndex++] = (pixel.r - 128) / 128;
      buffer[pixelIndex++] = (pixel.g - 128) / 128;
      buffer[pixelIndex++] = (pixel.b - 128) / 128;
    }
  }
  return convertedBytes.buffer.asFloat32List();
}

Future<Uint8List?> cropImage(XFile? imageFile) async {
  if (imageFile != null) {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatioPresets: Platform.isAndroid
          ? [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ]
          : [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9
            ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        )
      ],
    );
    if (croppedFile != null) {
      return croppedFile.readAsBytes();
    }
  }
  return null;
}
