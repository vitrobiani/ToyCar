
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'BleService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp( const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monster Truck!',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Monster Truck!'),
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
  int _counter = 0;
  final _ble = BleService();
  final _esp32Id ="F4:2D:C9:6D:92:62";
  double t_x = 0.55;
  double t_y = 0.55;
  JoystickMode _joystickMode = JoystickMode.all;
  Timer? t;
  bool isSafeToSend = true;



  @override
  void initState() {
    super.initState();
    _ble.connect(_esp32Id).catchError((e) {
      print("BLE connection failed: $e");
    });
    _ble.dataStream.listen((msg) {
      print("ESP32 says: $msg");
    });
  }

  void dispose() {
    _ble.disconnect();
    super.dispose();
  }

  Future<void> _incrementCounter() async {
    await _ble.send("DRIVE_LEFT\n");
    setState(() {
      _counter++;
    });
  }

  @override
  void didChangeDependencies() {
    // _x = MediaQuery.of(context).size.width / 2 - ballSize / 2;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade600,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text('Monster Truck!'),
        actions: [
          JoystickModeDropdown(
            mode: _joystickMode,
            onChanged: (JoystickMode value) {
              setState(() {
                _joystickMode = value;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: JoystickArea(
          mode: _joystickMode,
          initialJoystickAlignment: const Alignment(0, 0.8),
          onStickDragEnd: () {
            _ble.send("STOP");
          },
          listener: (details) {
            setState(() {
              if (isSafeToSend) {
                if (details.y <= -t_y && details.x >= t_x)
                  _ble.send("DRIVE_RIGHT");
                else if (details.y <= -t_y && details.x <= -t_x)
                  _ble.send("DRIVE_LEFT");
                else if (details.y >= t_y)
                  _ble.send("BACKWARD");
                else if (details.y <= -t_y)
                  _ble.send("FORWARD");
                else if (details.x <= -t_x)
                  _ble.send("LEFT");
                else if (details.x >= t_x)
                  _ble.send("RIGHT");
                else
                  _ble.send("STOP");
                isSafeToSend = false;
                t = Timer(Duration(milliseconds: 500),() {
                  isSafeToSend = true;
                }, );
              }
            });
          },
        ),
      ),
    );
  }
}

class JoystickModeDropdown extends StatelessWidget {
  final JoystickMode mode;
  final ValueChanged<JoystickMode> onChanged;

  const JoystickModeDropdown(
      {super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: FittedBox(
          child: DropdownButton(
            value: mode,
            onChanged: (v) {
              onChanged(v as JoystickMode);
            },
            items: const [
              DropdownMenuItem(
                  value: JoystickMode.all, child: Text('All Directions')),
              DropdownMenuItem(
                  value: JoystickMode.horizontalAndVertical,
                  child: Text('Vertical And Horizontal')),
              DropdownMenuItem(
                  value: JoystickMode.horizontal, child: Text('Horizontal')),
              DropdownMenuItem(
                  value: JoystickMode.vertical, child: Text('Vertical')),
            ],
          ),
        ),
      ),
    );
  }
}

