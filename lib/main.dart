// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const GPSBLEApp());
}

class GPSBLEApp extends StatefulWidget {
  const GPSBLEApp({Key? key}) : super(key: key);
  @override
  State<GPSBLEApp> createState() => _GPSBLEAppState();
}

class _GPSBLEAppState extends State<GPSBLEApp> {
  BluetoothDevice? esp32Device;
  BluetoothCharacteristic? gpsCharacteristic;
  bool connected = false;

  @override
  void initState() {
    super.initState();
    Geolocator.requestPermission();
  }

  Future<void> connectToESP32() async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.name == "ESP32_GPS_SERVER") {
          esp32Device = r.device;
          await FlutterBluePlus.stopScan();
          await esp32Device!.connect();
          connected = true;

          List<BluetoothService> services = await esp32Device!.discoverServices();
          for (var s in services) {
            for (var c in s.characteristics) {
              if (c.uuid.toString() == "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
                gpsCharacteristic = c;
                break;
              }
            }
          }
          setState(() {});
          break;
        }
      }
    });
  }

  Future<void> sendGpsData() async {
    if (gpsCharacteristic == null) return;
    Position pos = await Geolocator.getCurrentPosition();
    String data = "${pos.latitude},${pos.longitude}";
    await gpsCharacteristic!.write(data.codeUnits);
    debugPrint("📤 Enviado: $data");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("GPS BLE Transmitter")),
        body: Center(
          child: connected
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("✅ Conectado al ESP32"),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: sendGpsData,
                      child: const Text("Enviar coordenadas actuales"),
                    ),
                  ],
                )
              : ElevatedButton(
                  onPressed: connectToESP32,
                  child: const Text("Conectar con ESP32"),
                ),
        ),
      ),
    );
  }
}
