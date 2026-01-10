import 'dart:async';
import 'dart:math';

import 'package:charging_stations_map/data/charging_repository.dart';
import 'package:charging_stations_map/models/charging_station.dart';
import 'package:charging_stations_map/models/marker_cluster.dart';
import 'package:charging_stations_map/utils/marker_manager.dart';
import 'package:fluster/fluster.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ChargingController extends GetxController {
  final MarkerManager markerManager = MarkerManager();

  late Fluster<MarkerCluster> clusterManager;
  final List<ChargingStation> _stations = [];
  final Map<String, ChargingStation> _stationMap = {};
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  GoogleMapController? mapController;
  Timer? _debounceTimer;

  late final double devicePixelRatio;

  @override
  void onInit() {
    super.onInit();
    devicePixelRatio = MediaQuery.of(Get.context!).devicePixelRatio;
    _loadStations();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  // Load charging stations from API
  Future<void> _loadStations() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      _stations.clear();

      final stationsJson = await ChargingRepository.fetchChargingStations();

      // Parse and filter stations using helper
      _stations.addAll(_parseAndFilterStations(stationsJson));

      if (_stations.isEmpty) {
        errorMessage.value = 'Nessuna stazione trovata';
        return;
      }

      // Build cluster manager
      clusterManager = await markerManager.loadMarkers(_stations);

      // Calculate initial bounds from stations
      final bounds = _calculateBounds();

      // Get initial markers
      final initialMarkers = await markerManager.updateMarkers(
        clusterManager,
        devicePixelRatio,
        updatedZoom: 5.5,
        bounds: bounds,
        onClusterTap: _onClusterTap,
        onMarkerTap: _onMarkerTap,
        stationMap: _stationMap,
      );

      if (initialMarkers != null) {
        markers.assignAll(initialMarkers);
      }
    } catch (e) {
      debugPrint('Error loading charging stations: $e');
      errorMessage.value = 'Error: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Helper: parse and filter stations
  List<ChargingStation> _parseAndFilterStations(List stationsJson) {
    final filtered = <ChargingStation>[];
    for (var stationJson in stationsJson) {
      try {
        final station = ChargingStation.fromJson(stationJson);
        if (station.latitude != null &&
            station.longitude != null &&
            station.id != null &&
            station.latitude! >= 35.5 &&
            station.latitude! <= 47.1 &&
            station.longitude! >= 6.6 &&
            station.longitude! <= 18.5) {
          filtered.add(station);
          _stationMap[station.id!] = station;
        } else {
          if (station.latitude != null && station.longitude != null) {
            debugPrint(
              'Station filtered out (outside Italy): ${station.id} '
              'Lat: ${station.latitude}, Lng: ${station.longitude}',
            );
          }
        }
      } catch (e) {
        debugPrint('Error parsing station: $e');
      }
    }
    return filtered;
  }

  // Calculate bounds from all stations
  List<double>? _calculateBounds() {
    if (_stations.isEmpty) return null;

    double minLat = _stations.first.latitude!;
    double maxLat = _stations.first.latitude!;
    double minLng = _stations.first.longitude!;
    double maxLng = _stations.first.longitude!;

    for (var station in _stations) {
      if (station.latitude != null && station.longitude != null) {
        minLat = min(minLat, station.latitude!);
        maxLat = max(maxLat, station.latitude!);
        minLng = min(minLng, station.longitude!);
        maxLng = max(maxLng, station.longitude!);
      }
    }

    // Return bounds in format: [minLng, minLat, maxLng, maxLat]
    return [minLng, minLat, maxLng, maxLat];
  }

  // Handle camera movement with debouncing
  Future<void> onCameraMove(CameraPosition position) async {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce to avoid excessive updates while moving (LOGIC OPTIMIZATION)
    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      await _updateMarkersForPosition(position);
    });
  }

  // Update markers for camera position
  Future<void> _updateMarkersForPosition(CameraPosition position) async {
    if (mapController == null) return;

    try {
      final bounds = await mapController!.getVisibleRegion();

      final updated = await markerManager.updateMarkers(
        clusterManager,
        devicePixelRatio,
        updatedZoom: position.zoom,
        bounds: [
          bounds.southwest.longitude,
          bounds.southwest.latitude,
          bounds.northeast.longitude,
          bounds.northeast.latitude,
        ],
        onClusterTap: _onClusterTap,
        onMarkerTap: _onMarkerTap,
        stationMap: _stationMap,
      );

      if (updated != null) {
        markers.assignAll(updated);
      }
    } catch (e) {
      debugPrint('Error updating markers: $e');
    }
  }

  // Handle cluster tap - zoom to expand cluster and show markers inside
  Future<void> _onClusterTap(LatLngBounds clusterBounds) async {
    if (mapController != null) {
      try {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(clusterBounds, 50),
        );
      } catch (e) {
        debugPrint('Error zooming into cluster: $e');
      }
    }
  }

  // Handle marker tap - show info window with station details
  void _onMarkerTap(String markerId) {
    final station = _stationMap[markerId];
    if (station != null && mapController != null) {
      // The info window will be shown automatically by Google Maps
      debugPrint('Marker tapped: ${station.title} - ${station.fullAddress}');
    }
  }

  // Store map controller reference
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }
}
