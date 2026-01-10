import 'package:charging_stations_map/bindings/home_binding.dart';
import 'package:charging_stations_map/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

void main() async {
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("File .env loaded successfully");
  } catch (e) {
    debugPrint("File .env not found");
  }
  runApp(const ChargingStationsApp());
}

class ChargingStationsApp extends StatelessWidget {
  const ChargingStationsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EV Charging Map',
      debugShowCheckedModeBanner: false,
      initialBinding: HomeBinding(),
      home: const HomePage(),
    );
  }
}
