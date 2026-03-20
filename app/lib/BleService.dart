import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const String _serviceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
const String _txCharUuid  = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
const String _rxCharUuid  = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";

class BleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _txChar;
  BluetoothCharacteristic? _rxChar;

  final _dataStreamController = StreamController<String>.broadcast();
  Stream<String> get dataStream => _dataStreamController.stream;

  Future<void> connect(String targetId) async {
    // 1. Wait for BT adapter to be on
    await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .first;

    // 2. Scan and find the device first
    print("Scanning for $targetId...");
    final completer = Completer<BluetoothDevice>();

    final scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        print(r.device.remoteId.str.toUpperCase());
        if (r.device.remoteId.str.toUpperCase() == targetId.toUpperCase()) {
          if (!completer.isCompleted) {
            print("Found device: ${r.device.remoteId}");
            completer.complete(r.device);
          }
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    try {
      _device = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception("Device not found during scan"),
      );
    } finally {
      await scanSub.cancel();
      await FlutterBluePlus.stopScan();
    }

    // 3. Now connect to the found device
    print("Connecting...");
    await _device!.connect(
      autoConnect: false,
      timeout: const Duration(seconds: 10), license: License.free,
    );
    print("Connected, discovering services...");

    // 4. Discover services
    await _discoverServices();
    print("Ready!");
  }

  Future<void> _discoverServices() async {
    final services = await _device!.discoverServices();

    for (final service in services) {
      if (service.serviceUuid.toString().toLowerCase() == _serviceUuid) {
        for (final char in service.characteristics) {
          final uuid = char.characteristicUuid.toString().toLowerCase();

          if (uuid == _txCharUuid) {
            _txChar = char;
            await _txChar!.setNotifyValue(true);
            _txChar!.lastValueStream.listen((value) {
              if (value.isNotEmpty) {
                _dataStreamController.add(utf8.decode(value));
              }
            });
          }

          if (uuid == _rxCharUuid) {
            _rxChar = char;
          }
        }
      }
    }

    if (_rxChar == null) throw Exception("UART service not found on device");
  }

  Future<void> send(String data) async {
    if (_rxChar == null) throw Exception("Not connected or service not found");
    await _rxChar!.write(utf8.encode(data), withoutResponse: false);
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;
    _txChar = null;
    _rxChar = null;
  }

  void dispose() {
    _dataStreamController.close();
  }
}