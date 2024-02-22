import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:socketremote/websocket.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Import the toast package

final Logger _logger = Logger();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cvbot Remote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _ipController = TextEditingController();
  late WebSocketService webSocketService;
  bool _isConnected = false;
  int currentMode = 0;

  @override
  void initState() {
    super.initState();
    webSocketService = WebSocketService();
  }

  Future<void> _connectToWebSocket() async {
    String ipAddress = 'ws://${_ipController.text}:5000/control';
    try {
      await webSocketService.connect(ipAddress);
      setState(() {
        _isConnected = true;
      });
      Fluttertoast.showToast(
          msg: 'Connected to WebSocket server',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0);
    } catch (e, stackTrace) {
      _logger.e('Failed to connect to WebSocket server: $e');
      Fluttertoast.showToast(
          msg:
              'Failed to connect to WebSocket server: $e\nStack Trace: $stackTrace',
          toastLength: Toast
              .LENGTH_LONG, // Use LONG toast length to accommodate the stack trace
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      setState(() {
        _isConnected = false;
      });
    }
  }

  Future<void> sendMessage(String message) async {
    if (_isConnected) {
      // Check if the message is 'toggle' before toggling the state and showing the toast
      if (message == 'toggle') {
        // Toggle the current mode
        setState(() {
          currentMode = currentMode == 0 ? 1 : 0;
        });

        // Show a toast message based on the current mode
        String toastMessage;
        if (currentMode == 0) {
          toastMessage = 'Toggled to Remote Control';
        } else {
          toastMessage = 'Toggled to CV Control';
        }
        Fluttertoast.showToast(
          msg: toastMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }

      // Send the message to the server
      webSocketService.sendMessage(message);
    } else {
      Fluttertoast.showToast(
          msg: 'WebSocket service not connected',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  @override
  void dispose() {
    webSocketService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CVbot Remote')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Socket server IP',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: FloatingActionButton(
                    onPressed: _connectToWebSocket,
                    child: const Icon(Icons.check),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              currentMode == 0 ? 'Remote Control Mode' : 'CV Control Mode',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          if (_isConnected)
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: ElevatedButton(
                        onPressed: () async => await sendMessage('toggle'),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            currentMode == 0 ? Colors.black : Colors.lightGreen,
                          ),
                        ),
                        child: const Icon(Icons.visibility)),
                  ),
                  if (currentMode == 0)
                    Joystick(
                      mode: JoystickMode.horizontalAndVertical,
                      listener: (details) async {
                        if (details.x > 0.5) {
                          await sendMessage('R');
                        } else if (details.x < -0.5) {
                          await sendMessage('L');
                        }

                        if (details.y > 0.5) {
                          await sendMessage('B');
                        } else if (details.y < -0.5) {
                          await sendMessage('F');
                        }
                      },
                    ),
                  if (currentMode == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 30.0),
                      child: FloatingActionButton(
                        onPressed: () async => await sendMessage('S'),
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.stop),
                      ),
                    )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
