import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:pedometer/pedometer.dart';
import 'dart:async';
import 'dart:io';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'location_data.dart';
import 'steps_data.dart';
import 'activity_data.dart';

void main() {
  runApp(SensingApp());
}

class SensingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensing app',
      home: AppHome(title: 'Sensing app'),
    );
  }
}

class AppHome extends StatefulWidget {
  AppHome({required this.title});
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
  final List<ActivityEvent> _events = [];
  ActivityRecognition activityRecognition = ActivityRecognition.instance;

  String url = 'https://silly-stingray-56.loca.lt/';
  String weatherAPIkey = '82dd81e254d959de34cd6747c3d9b47f';

  @override
  void initState() {
    // CHECK PERMISSION & GET STEPS
    checkPermissions();

    // GET LOCATION
    getLocation();

    // GET ACTIVITY
    getActivity();

    super.initState();
  }

  void _startTracking() {
    activityStreamSubscription =
        activityRecognition.activityStream(runForegroundService: true).listen(onActivityData);
  }

  void checkPermissions() async {
    /// LOCATION
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

    /// ACTIVITY
    if (Platform.isAndroid) {
      if (await Permission.activityRecognition.request().isGranted) {
        _startTracking();
      }
    } else {
      _startTracking();
    }

    /// STEPS
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(getSteps);
    //_pedestrianStatusStream.listen(onPedestrianStatusChanged);
  }

  void getLocation() async {
    _locationData = await location.getLocation();
    placemarks = await placemarkFromCoordinates(_locationData!.latitude!, _locationData!.longitude!);
    setState(() {});
    LocationData locationData = LocationData(
        dateTime: DateTime.now(),
        latitude: _locationData!.latitude!,
        longitude: _locationData!.longitude!,
        name: placemarks!.last.name!,
        address: placemarks!.last.street!);
    print(sendLocation(locationData));

    //print(_locationData.latitude);
  }

  void getActivity() {
    activityStreamSubscription =
        activityRecognition.activityStream(runForegroundService: true).listen(onActivityData);
  }

  void getSteps(StepCount event) {
    /// Handle step count changed
    setState(() {
      _steps = event.steps.toString();
    });

    StepsData stepsData = StepsData(dateTime: DateTime.now(), steps: num.parse(_steps));
    print(sendSteps(stepsData));
  }

  /// WEATHER
  void getWeather() {
    
    WeatherData weatherData = fetchWeather();

  }

  Future<WeatherData> fetchWeather() async {
    final response = await http
      .get(Uri.parse('https://api.openweathermap.org/data/2.5/onecall?lat=_locationData!.latitude!&lon=_locationData!.latitude!&exclude=current,minutely,daily,alerts&appid=weatherAPIkey'));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.   
      return WeatherData.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load weather data');
    }    
  }
 
  Future<http.Response> sendLocation(LocationData locationData) async {
    var response = await http.post(Uri.parse(url + 'location'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(locationData.toJson()));
    return response;
  }

  Future<http.Response> sendSteps(StepsData stepsData) async {
    var response = await http.post(Uri.parse(url + 'steps'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(stepsData.toJson()));
    return response;
  }

  Future<http.Response> sendActivity(ActivityData activityData) async {
    var response = await http.post(Uri.parse(url + 'activity'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(activityData.toJson()));
    return response;
  }

  void onActivityData(ActivityEvent activityEvent) {
    print('ACTIVITY - $activityEvent');
    setState(() {
      _events.add(activityEvent);
    });
    ActivityData activityData = ActivityData(
        dateTime: DateTime.now(),
        certainty: _events.last.confidence,
        activity: _events.last.type.toString().split('.').last);
    print(sendActivity(activityData));
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
            "Current activity :  ${_events.last.type.toString().split('.').last} ${_events.last.confidence}"),
      ])),
    );
  }

  @override
  void dispose() {
    activityStreamSubscription?.cancel();
    super.dispose();
  }
}
