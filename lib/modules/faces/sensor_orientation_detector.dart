/*
import 'dart:async';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_sensors/flutter_sensors.dart';

enum DeviceOrientation {
  portraitUp,
  portraitDown,
  landscapeLeft,
  landscapeRight
}

class SensorOrientationDetector extends Disposable {
  StreamSubscription<SensorEvent>? _accelSubscription;
  DeviceOrientation _orientation = DeviceOrientation.portraitUp;

  Future<void> init() async {
    final stream = await SensorManager().sensorUpdates(
      sensorId: Sensors.ACCELEROMETER,
      interval: const Duration(seconds: 5),
    );

    _accelSubscription = stream.listen((event) {
      if (_isPortrait(event)) {
        if (event.data[2] < 0) {
          _orientation = DeviceOrientation.portraitDown;
        } else {
          _orientation = DeviceOrientation.portraitUp;
        }
      } else {
        if (event.data[0] < 0) {
          _orientation = DeviceOrientation.landscapeRight;
        } else {
          _orientation = DeviceOrientation.landscapeLeft;
        }
      }
    });
  }

  bool _isPortrait(SensorEvent event) {
    return event.data[0].abs() < event.data[1].abs();
  }

  DeviceOrientation get value => _orientation;

  @override
  void dispose() {
    _accelSubscription?.cancel();
  }
}*/
