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
import 'package:sensing_app/weather_data.dart';
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
  final List<String> _eventTypes = [];
  final List<ActivityData> detectedActivities = [];
  final List<LocationData> detectedLocations = [];
  WeatherData? weatherData;
  WeatherData? historicalWeatherData;
  StepsData? stepsData;

  ActivityRecognition activityRecognition = ActivityRecognition.instance;

  String thekey = "";

  // int freqLocation = 10;
  // int freqWeather = 1140;
  // int freqActivity = 5;
  // int freqSending = 120;

  int freqLocation = 1;
  int freqWeather = 1;
  int freqActivity = 1;
  int freqSending = 2;

  String url = 'https://sadproject.loca.lt/';
  String weatherAPIkey = '82dd81e254d959de34cd6747c3d9b47f';

  Timer? timerLocation;
  Timer? timerActivity;
  Timer? timerSendData;
  Timer? timerWeather;

  @override
  void initState() {
    checkPermissions();
    timerLocation = Timer.periodic(Duration(minutes: freqLocation), (Timer t) => getLocation());
    timerActivity = Timer.periodic(Duration(minutes: freqActivity), (Timer t) => detectActivity());
    timerSendData = Timer.periodic(Duration(minutes: freqSending), (Timer t) => sendData());
    timerWeather = Timer.periodic(Duration(minutes: freqWeather), (Timer t) => sendWeatherData());
    super.initState();
  }

  @override
  void dispose() {
    timerLocation?.cancel();
    timerActivity?.cancel();
    timerSendData?.cancel();
    timerWeather?.cancel();
    activityStreamSubscription?.cancel();
    super.dispose();
  }

  // @override
  // void initState() {
  //   // CHECK PERMISSION & GET STEPS
  //   checkPermissions();

  //   // GET LOCATION
  //   getLocation();

  //   // GET ACTIVITY
  //   getActivity();

  //   //getWeather();

  //   super.initState();
  // }

  void detectActivity() {
    // the most common activity currently in events
    var map = Map();

    String detected;
    if (_eventTypes.length == 0)
      detected = 'unknown';
    else {
      _eventTypes.forEach((element) {
        if (!map.containsKey(element)) {
          map[element] = 1;
        } else {
          map[element] += 1;
        }
      });

      var thevalue = 0;

      map.forEach((k, v) {
        if (v > thevalue) {
          thevalue = v;
          thekey = k;
        }
      });

      print(thekey);

      // List sortedValues = map.values.toList()..sort();
      // print(sortedValues);
      // print(map);
      // int popularValue = sortedValues.last;
      // detected = map[popularValue];
    }
    ActivityData activityData = ActivityData(
      dateTime: DateTime.now(),
      certainty: 100,
      activity: thekey, // the most common activity currently in events
    );

    detectedActivities.add(activityData);
    _events.clear();
    _eventTypes.clear();
  }

  void sendData() {
    //sleep(Duration(seconds: 5));
    print("Sending data");
    detectedActivities.forEach((item) {
      print(item);
      print(sendActivity(item));
    });
    detectedLocations.forEach((item) {
      print(item);
      print(sendLocation(item));
    });

    sendSteps(stepsData!);

    detectedLocations.clear();
    detectedActivities.clear();
  }

  void sendWeatherData() {
    sleep(Duration(seconds: 5));
    print("sending weather");
    //fetchWeather();
    getWeather();
    sleep(Duration(seconds: 5));
    sendWeather(weatherData!);
    //sendWeather(yesterdayWeatherData!);
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
    // weatherData = await fetchWeather();
    // fetchWeather().then((value) => print(value.body.toString()));
    // fetchHistoricalWeather().then((value) => print(value.body.toString()));
    setState(() {});
    LocationData locationData = LocationData(
        dateTime: DateTime.now(),
        latitude: _locationData!.latitude!,
        longitude: _locationData!.longitude!,
        name: placemarks!.last.name!,
        address: placemarks!.last.street!);

    detectedLocations.add(locationData);
    print(detectedLocations);

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

    stepsData = StepsData(dateTime: DateTime.now(), steps: num.parse(_steps));
    //print(sendSteps(stepsData));
  }

  /// WEATHER
  getWeather() {
    print("@@@@@ trying to get weather");
    fetchWeather().then((value) => weatherData = WeatherData.fromJson(jsonDecode(value.body)));
    // print(sendWeather(weatherData!));
  }

  /// HISTORICAL WEATHER
  getHistoricalWeather() {
    print("@@@@@ trying to get historical weather");
    fetchHistoricalWeather()
        .then((value) => historicalWeatherData = WeatherData.fromJson(jsonDecode(value.body)));
    print(sendWeather(historicalWeatherData!));
  }

  Future<http.Response> fetchWeather() {
    return http.get(Uri.parse('https://api.openweathermap.org/data/2.5/onecall?lat=' +
        _locationData!.latitude.toString() +
        '&lon=' +
        _locationData!.longitude.toString() +
        '&exclude=minutely,alerts&appid=' +
        weatherAPIkey));
  }

  Future<http.Response> fetchHistoricalWeather() {
    final DateTime date_now = DateTime.now().subtract(Duration(days: 1));
    final timestamp = date_now.millisecondsSinceEpoch ~/ 1000;
    return http.get(Uri.parse('https://api.openweathermap.org/data/2.5/onecall/timemachine?lat=' +
        _locationData!.latitude.toString() +
        '&lon=' +
        _locationData!.longitude.toString() +
        '&dt=' +
        timestamp.toString() +
        '&appid=' +
        weatherAPIkey));
  }

  Future<http.Response> sendWeather(WeatherData weatherData) async {
    var response = await http.post(Uri.parse(url + 'weather'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(weatherData.toJson()));
    return response;
  }

  Future<http.Response> sendLocation(LocationData locationData) async {
    print("sending location");
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
    print("sending activity");
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
      _eventTypes.add(activityEvent.type.toString().split('.').last);
    });

    //print(sendActivity(activityData));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("SENSING APP")
        // Text("The coordinates are :  ${_locationData!.latitude!}, ${_locationData!.longitude!}"),
        // Text("The place is: " + placemarks!.last.toString()),
        // Text("Steps taken: " + _steps),
        // Text(
        //     "Current activity :  ${_events.last.type.toString().split('.').last} ${_events.last.confidence}"),
      ])),
    );
  }
}
