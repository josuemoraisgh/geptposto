import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as imglib;
import 'package:camera/camera.dart';

/*
InputImage imageToInputImage(imglib.Image image, int cameraRotation) {
  // Converte a imagem para o formato NV21
  final nv21 = image.data?.getBytes() ?? [] as Uint8List;
  final inputImageData = InputImageData(
    imageRotation: cameraRotation == 0
        ? InputImageRotation.rotation90deg
        : InputImageRotation.rotation270deg,
    inputImageFormat: InputImageFormat.nv21,
    size: Size(image.width.toDouble(), image.height.toDouble()),
    planeData: [
      InputImagePlaneMetadata(
          width: image.width, height: image.height, bytesPerRow: 2)
    ],
  );
  // Cria o objeto 'InputImage' a partir do objeto 'InputImageData'
  final inputImage = InputImage.fromBytes(
    bytes: nv21,
    inputImageData: inputImageData,
  );
  return inputImage;
}*/

imglib.Image convertCameraImageToImageWithRotate(
    CameraImage cameraImage, num angle) {
  var img = convertCameraImageToImage(cameraImage);
  var img1 = imglib.copyRotate(img, angle: angle);
  return img1;
}

///
/// Converts a [CameraImage] in YUV420 format to [image_lib.Image] in RGB format
///
imglib.Image convertCameraImageToImage(CameraImage cameraImage) {
  if (cameraImage.format.group == ImageFormatGroup.yuv420) {
    return convertYUV420ToImage(cameraImage);
  } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
    return convertBGRA8888ToImage(cameraImage);
  } else {
    throw Exception('Undefined image type.');
  }
}

///
/// Converts a [CameraImage] in BGRA888 format to [image_lib.Image] in RGB format
///
imglib.Image convertBGRA8888ToImage(CameraImage cameraImage) {
  return imglib.Image.fromBytes(
    width: cameraImage.planes[0].width!,
    height: cameraImage.planes[0].height!,
    bytes: cameraImage.planes[0].bytes.buffer,
    order: imglib.ChannelOrder.bgra,
  );
}

///
/// Converts a [CameraImage] in YUV420 format to [image_lib.Image] in RGB format
///
imglib.Image convertYUV420ToImage(CameraImage cameraImage) {
  final imageWidth = cameraImage.width;
  final imageHeight = cameraImage.height;

  final yBuffer = cameraImage.planes[0].bytes;
  final uBuffer = cameraImage.planes[1].bytes;
  final vBuffer = cameraImage.planes[2].bytes;

  final int yRowStride = cameraImage.planes[0].bytesPerRow;
  final int yPixelStride = cameraImage.planes[0].bytesPerPixel!;

  final int uvRowStride = cameraImage.planes[1].bytesPerRow;
  final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

  final image = imglib.Image(width: imageWidth, height: imageHeight);

  for (int h = 0; h < imageHeight; h++) {
    int uvh = (h / 2).floor();

    for (int w = 0; w < imageWidth; w++) {
      int uvw = (w / 2).floor();

      final yIndex = (h * yRowStride) + (w * yPixelStride);

      // Y plane should have positive values belonging to [0...255]
      final int y = yBuffer[yIndex];

      // U/V Values are subsampled i.e. each pixel in U/V chanel in a
      // YUV_420 image act as chroma value for 4 neighbouring pixels
      final int uvIndex = (uvh * uvRowStride) + (uvw * uvPixelStride);

      // U/V values ideally fall under [-0.5, 0.5] range. To fit them into
      // [0, 255] range they are scaled up and centered to 128.
      // Operation below brings U/V values to [-128, 127].
      final int u = uBuffer[uvIndex];
      final int v = vBuffer[uvIndex];

      // Compute RGB values per formula above.
      int r = (y + v * 1436 / 1024 - 179).round();
      int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
      int b = (y + u * 1814 / 1024 - 227).round();

      r = r.clamp(0, 255);
      g = g.clamp(0, 255);
      b = b.clamp(0, 255);

      image.setPixelRgb(w, h, r, g, b);
    }
  }

  return image;
}

int getImageRotation(int sensorOrientation, Orientation screemOrientation) {
  if (screemOrientation == Orientation.landscape) {
    if (sensorOrientation == 270) {
      debugPrint("270");
      return (sensorOrientation + 90) % 360;
    }
    return (360 - (sensorOrientation - 90)) % 360;
  } else {
    return sensorOrientation;
  }
}

Future<InputImage?> convertCameraImageToInputImageWithRotate(
    CameraImage image, int rotation) async {

  final imageSize = Size(image.width.toDouble(), image.height.toDouble());
  final imageRotation = InputImageRotationValue.fromRawValue(rotation);
  if (imageRotation == null) return null;
  final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
  if (inputImageFormat == null) return null;

  final inputImageMetadata = InputImageMetadata(
    size: imageSize,
    rotation: imageRotation,
    format: inputImageFormat,
    bytesPerRow: image.planes[0].bytesPerRow,
  );

  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();
  final inputImage =
      InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
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

Float32List imageByteToFloat32Normal(imglib.Image imageResized) {
  var convertedBytes = Float32List(1 * 112 * 112 * 3);
  var buffer = Float32List.view(convertedBytes.buffer);
  int pixelIndex = 0;
  for (var i = 0; i < 112; i++) {
    for (var j = 0; j < 112; j++) {
      var pixel = imageResized.getPixelSafe(j, i);
      buffer[pixelIndex++] = pixel.r.toDouble() / 255;
      buffer[pixelIndex++] = pixel.g.toDouble() / 255;
      buffer[pixelIndex++] = pixel.b.toDouble() / 255;
    }
  }
  return convertedBytes.buffer.asFloat32List();
}

/*
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
*/