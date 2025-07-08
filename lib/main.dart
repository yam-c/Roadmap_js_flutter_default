import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _location;
  late final WebViewController controller;
  int a = 0; // 메모리 변수
  int b = 0; // 영속 변수

  // 1. 알림 객체 생성
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('http://192.168.14.219'));
    _getLocation();
    _loadB();
    _initNotification();
    _requestNotificationPermission();
  }

  Future<void> _initNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('your_channel_id', 'your_channel_name',
            importance: Importance.max, priority: Priority.high);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics);
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _location = '위치 서비스 꺼짐';
      });
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _location = '위치 권한 거부됨';
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _location = '영구적으로 위치 권한 거부됨';
      });
      return;
    }
    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      _location = '위도: ${pos.latitude}, 경도: ${pos.longitude}';
    });
  }

  Future<void> _loadB() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      b = prefs.getInt('b') ?? 0;
    });
  }

  void _incA() {
    setState(() {
      a++;
    });
    _showNotification('a 증가', 'a 값이 $a로 증가했습니다.');
  }

  Future<void> _incB() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      b++;
      prefs.setInt('b', b);
    });
    _showNotification('b 증가', 'b 값이 $b로 증가했습니다.');
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_location ?? '위치 정보를 불러오는 중...'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text('a(메모리): $a'),
                    ElevatedButton(
                      onPressed: _incA,
                      child: const Text('a 증가'),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Column(
                  children: [
                    Text('b(영속): $b'),
                    ElevatedButton(
                      onPressed: _incB,
                      child: const Text('b 증가'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: controller),
          ),
        ],
      ),
    );
  }
}
