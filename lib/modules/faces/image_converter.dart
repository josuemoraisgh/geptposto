import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geptposto/modules/faces/camera_controle_service.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

final _orientations = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

InputImage? inputImageFromCameraImage(
    CameraImage cameraImage, CameraService cameraService) {
  // get image rotation
  // it is used in android to convert the InputImage from Dart to Java
  // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
  // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
  //final camera = (await availableCameras())[0];
  if (cameraService.camera == null || cameraService.cameraController == null) {
    return null;
  }
  final sensorOrientation = cameraService.camera!.sensorOrientation;

  InputImageRotation? rotation;
  if (Platform.isIOS) {
    rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
  } else if (Platform.isAndroid) {
    var rotationCompensation =
        _orientations[cameraService.cameraController?.value.deviceOrientation];
    if (rotationCompensation == null) return null;
    if (cameraService.camera?.lensDirection == CameraLensDirection.front) {
      // front-facing
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      // back-facing
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
    }
    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
  }
  if (rotation == null) return null;

  // get image format
  final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
  // validate format depending on platform
  // only supported formats:
  // * nv21 for Android
  // * bgra8888 for iOS
  // since format is constraint to nv21 or bgra8888, both only have one plane
  if (format == null ||
      ((cameraImage.planes.length != 1) &&
          ((Platform.isAndroid && format == InputImageFormat.nv21) ||
              (Platform.isIOS && format == InputImageFormat.bgra8888)))) {
    return null;
  }

  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in cameraImage.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();

  // compose InputImage using bytes
  return InputImage.fromBytes(
    bytes: bytes,
    metadata: InputImageMetadata(
      size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
      rotation: rotation, // used only in Android
      format: format, // used only in iOS
      bytesPerRow: cameraImage.planes[0].bytesPerRow, // used only in iOS
    ),
  );
}

Uint8List encodeNV21(imglib.Image image) {
  Uint8List argb = image.data!.toUint8List();
  int width = image.width;
  int height = image.height;

  var nv21 = List<int>.filled((width * height * 3) ~/ 2, 0);

  final int frameSize = width * height;
  int yIndex = 0;
  int uvIndex = frameSize;

  int R, G, B, Y, U, V;
  int index = 0;
  for (int j = 0; j < height; j++) {
    for (int i = 0; i < width; i++) {
      //            24  16  8   0
      // color: 0x FF  FF  FF  FF
      //           A   B   G   R
      //           A   R   G   B
      //a = (argb[index] & 0xff000000) >> 24; // a is not used obviously
      R = (argb[index] & 0xff0000) >> 16;
      G = (argb[index] & 0x00ff00) >> 8;
      B = (argb[index] & 0x0000ff) >> 0;

      // well known BGR ou RGB to YUV algorithm
      Y = ((66 * R + 129 * G + 25 * B + 128) >> 8) + 16;
      U = ((-38 * R - 74 * G + 112 * B + 128) >> 8) + 128;
      V = ((112 * R - 94 * G - 18 * B + 128) >> 8) + 128;

      /* NV21 has a plane of Y and interleaved planes of VU each sampled by a factor of 2                 
        meaning for every 4 Y pixels there are 1 V and 1 U.
        Note the sampling is every otherpixel AND every other scanline.*/
      nv21[yIndex++] = ((Y < 0) ? 0 : ((Y > 255) ? 255 : Y));
      if (j % 2 == 0 && index % 2 == 0 && j != 0 && index != 0) {
        nv21[uvIndex++] = ((V < 0) ? 0 : ((V > 255) ? 255 : V));
        nv21[uvIndex++] = ((U < 0) ? 0 : ((U > 255) ? 255 : U));
      }
      index++;
    }
  }

  return Uint8List.fromList(nv21);
}

InputImage inputImageFromImgLibImage(imglib.Image image) {
  final bytes = encodeNV21(image);
  final metadata = InputImageMetadata(
      format: Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888,
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: InputImageRotation.rotation0deg,
      bytesPerRow: Platform.isAndroid ? 0 : 28); // ignored

  return InputImage.fromBytes(bytes: bytes, metadata: metadata);
}

///
/// Converts a [CameraImage] in YUV420 format to [image_lib.Image] in RGB format
///
imglib.Image? imgLibImageFromCameraImage(
    CameraImage cameraImage, CameraService cameraService) {
  if (cameraImage.format.group == ImageFormatGroup.nv21) {
    var inputImage = inputImageFromCameraImage(cameraImage, cameraService);
    return inputImage != null ? imgLibImageFromInputImage(inputImage) : null;
  } else if (cameraImage.format.group == ImageFormatGroup.yuv420) {
    return imgLibImageFromCameraImageYUV420(cameraImage);
  } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
    return imgLibImageFromCameraImageBGRA8888(cameraImage);
  } else {
    throw Exception('Undefined image type.');
  }
}

///
/// Converts a [CameraImage] in BGRA888 format to [image_lib.Image] in RGB format
///
imglib.Image imgLibImageFromCameraImageBGRA8888(CameraImage cameraImage) {
  // ignore: constant_identifier_names
  const IOS_BYTES_OFFSET = 28;
  return imglib.Image.fromBytes(
    width: cameraImage.planes[0].width!,
    height: cameraImage.planes[0].height!,
    bytes: cameraImage.planes[0].bytes.buffer,
    bytesOffset: IOS_BYTES_OFFSET,
    order: imglib.ChannelOrder.bgra,
  );
}

///
/// Converts a [CameraImage] in YUV420 format to [image_lib.Image] in RGB format
///
imglib.Image imgLibImageFromCameraImageYUV420(CameraImage cameraImage) {
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

imglib.Image imgLibImageFromInputImage(InputImage inputImage) {
  final width = inputImage.metadata!.size.width.toInt();
  final height = inputImage.metadata!.size.height.toInt();

  Uint8List yuv420sp = inputImage.bytes!;
  //int total = width * height;
  //Uint8List rgb = Uint8List(total);
  final outImg =
      imglib.Image(width: width, height: height); // default numChannels is 3

  final int frameSize = width * height;

  for (int j = 0, yp = 0; j < height; j++) {
    int uvp = frameSize + (j >> 1) * width, u = 0, v = 0;
    for (int i = 0; i < width; i++, yp++) {
      int y = (0xff & yuv420sp[yp]) - 16;
      if (y < 0) y = 0;
      if ((i & 1) == 0) {
        v = (0xff & yuv420sp[uvp++]) - 128;
        u = (0xff & yuv420sp[uvp++]) - 128;
      }
      int y1192 = 1192 * y;
      int r = (y1192 + 1634 * v);
      int g = (y1192 - 833 * v - 400 * u);
      int b = (y1192 + 2066 * u);

      if (r < 0)
        // ignore: curly_braces_in_flow_control_structures
        r = 0;
      // ignore: curly_braces_in_flow_control_structures
      else if (r > 262143) r = 262143;

      if (g < 0)
        // ignore: curly_braces_in_flow_control_structures
        g = 0;
      // ignore: curly_braces_in_flow_control_structures
      else if (g > 262143) g = 262143;
      if (b < 0)
        // ignore: curly_braces_in_flow_control_structures
        b = 0;
      // ignore: curly_braces_in_flow_control_structures
      else if (b > 262143) b = 262143;

      // I don't know how these r, g, b values are defined, I'm just copying what you had bellow and
      // getting their 8-bit values.
      outImg.setPixelRgb(i, j, ((r << 6) & 0xff0000) >> 16,
          ((g >> 2) & 0xff00) >> 8, (b >> 10) & 0xff);

      /*rgb[yp] = 0xff000000 |
            ((r << 6) & 0xff0000) |
            ((g >> 2) & 0x00ff00) |
           ((b >> 10) & 0x0000ff);*/
    }
  }
  final rotatedImage =
      imglib.copyRotate(outImg, angle: inputImage.metadata!.rotation.rawValue);
  return rotatedImage;
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

Float32List float32ListFromImgLibImage(imglib.Image imageResized) {
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

Future<InputImage?> convertCameraImageToInputImageWithRotateA(
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

imglib.Image convertCameraImageToImageWithRotate(
    CameraImage cameraImage, num angle) {
  var img = cameraImageToImage(cameraImage);
  var img1 = imglib.copyRotate(img, angle: angle);
  return img1;
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
*/
