import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:pedometer/pedometer.dart';
import 'dart:async';
import 'dart:io';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(SensingApp());
}

/// A Flutter application demonstrating the functionality of this plugin
class SensingApp extends StatelessWidget {
  /// [MaterialColor] to be used in the app [ThemeData]

  @override
  Widget build(BuildContext context) {
    /// Returns a [List] with [IconData] to show in the [AppHome] [AppBar].
    final List<IconData> icons = [
      Icons.location_on,
      Icons.info_outline,
    ];

    return MaterialApp(
      title: 'Sensing app',
      home: AppHome(title: 'Sensing app'),
    );
  }
}

/// A Flutter example demonstrating how the [pluginName] plugin could be used
class AppHome extends StatefulWidget {
  /// Constructs the [AppHome] class
  AppHome({required this.title});

  /// The [title] of the application, which is shown in the application's
  /// title bar.
  final String title;

  @override
  _AppHomeState createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _steps = '?';
  loc.Location location = loc.Location();
  List<Placemark>? placemarks;
  loc.LocationData? _locationData;
  StreamSubscription<ActivityEvent>? activityStreamSubscription;
  List<ActivityEvent> _events = [];
  ActivityRecognition activityRecognition = ActivityRecognition.instance;

  @override
  void initState() {
    checkPermissions();
    getLocation();
    initPlatformState();
    _init();
    _events.add(ActivityEvent.empty());
    super.initState();
  }

  void _init() async {
    // Android requires explicitly asking permission
    if (Platform.isAndroid) {
      if (await Permission.activityRecognition.request().isGranted) {
        _startTracking();
      }
    }

    // iOS does not
    else {
      _startTracking();
    }
  }

  void _startTracking() {
    activityStreamSubscription =
        activityRecognition.activityStream(runForegroundService: true).listen(onData);
  }

  void checkPermissions() async {
    bool _serviceEnabled;
    loc.PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }
  }

  void getLocation() async {
    _locationData = await location.getLocation();
    placemarks = await placemarkFromCoordinates(_locationData!.latitude!, _locationData!.longitude!);
    setState(() {});

    //print(_locationData.latitude);
  }

  void onStepCount(StepCount event) {
    print("@@@ $event");
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _steps = 'Step Count not available';
    });
  }

  void onData(ActivityEvent activityEvent) {
    print('ACTIVITY - $activityEvent');
    setState(() {
      _events.add(activityEvent);
    });
  }

  void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream.listen(onPedestrianStatusChanged).onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("The coordinates are :  ${_locationData!.latitude!}, ${_locationData!.longitude!}"),
        Text("The place is: " + placemarks!.last.toString()),
        Text("Steps taken: " + _steps),
        Text(
            "Current activity :  ${_events.last.type.toString().split('.').last} (${_events.last.confidence}"),
      ])),
    );
  }

  @override
  void dispose() {
    activityStreamSubscription?.cancel();
    super.dispose();
  }
}
