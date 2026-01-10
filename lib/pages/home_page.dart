import 'package:charging_stations_map/data/charging_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ChargingController _chargingController;

  @override
  void initState() {
    super.initState();
    _chargingController = Get.find<ChargingController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stazioni di Ricarica'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        // Loading widget
        if (_chargingController.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                SizedBox(height: 16),
                Text(
                  'Caricamento stazioni...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Empty state
        if (_chargingController.markers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.ev_station_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nessuna stazione trovata',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }

        // Map
        return GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(41.8719, 12.5674), // Italy
            zoom: 5.5,
          ),
          onMapCreated: _chargingController.onMapCreated,
          markers: _chargingController.markers,
          onCameraMove: _chargingController.onCameraMove,
          myLocationButtonEnabled: true,
          myLocationEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
        );
      }),
    );
  }
}
