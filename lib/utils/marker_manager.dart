import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:charging_stations_map/models/charging_station.dart';
import 'package:charging_stations_map/models/marker_cluster.dart';
import 'package:charging_stations_map/utils/cluster_generator.dart';
import 'package:fluster/fluster.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerManager {
  // Current map zoom initial setted to 5 because Italy is well visible (GRAPHIC OPTIMIZATION)
  RxDouble currentZoom = 5.0.obs;

  // Create cluster manager from charging stations
  Future<Fluster<MarkerCluster>> loadMarkers(
    List<ChargingStation> stations,
  ) async {
    final List<MarkerCluster> markers = [];

    for (ChargingStation station in stations) {
      if (station.latitude != null && station.longitude != null) {
        markers.add(
          MarkerCluster(
            id: station.id.toString(),
            position: LatLng(station.latitude!, station.longitude!),
          ),
        );
      }
    }

    return ClusterGenerator.initClusterManager(
      markers,
      0, // min zoom
      17, // max zoom
    );
  }

  // Update markers based on zoom and bounds (GRAPHIC OPTIMIZATION)
  Future<Set<Marker>?> updateMarkers(
    Fluster<MarkerCluster>? clusterManager,
    double pixelRatio, {
    double? updatedZoom,
    List<double>? bounds,
    Future<void> Function(LatLngBounds bounds)? onClusterTap,
    void Function(String markerId)? onMarkerTap,
    Map<String, ChargingStation>? stationMap,
  }) async {
    if (clusterManager == null) return null;

    if (updatedZoom != null) {
      currentZoom(updatedZoom);
    }

    if (bounds == null) return null;

    // Get clusters only for visible area
    List<MarkerCluster> clusters = clusterManager.clusters(
      bounds,
      currentZoom.toInt(),
    );

    Set<Marker> markerSet = {};
    for (MarkerCluster cluster in clusters) {
      if (cluster.isCluster == true && cluster.pointsSize! > 1) {
        // Generate cluster icon with count
        cluster.icon = await ClusterGenerator.getClusterIcon(
          cluster.pointsSize!,
          pixelRatio,
        );

        // Set anchor to center for circular cluster icons
        cluster.anchor = const Offset(0.2, 0.2);

        // Set onClusterTap to zoom in
        if (onClusterTap != null) {
          cluster.onTap = () {
            final clusterBounds = _calculateClusterBounds(
              clusterManager,
              cluster,
            );
            if (clusterBounds != null) {
              onClusterTap(clusterBounds);
            }
          };
        }
      } else {
        // Add tap callback for single markers (stations)
        if (onMarkerTap != null) {
          cluster.onTap = () => onMarkerTap(cluster.id);
        }
      }

      Marker marker = cluster.toMarker();
      if (cluster.isCluster == false &&
          stationMap != null &&
          stationMap.containsKey(cluster.id)) {
        final station = stationMap[cluster.id]!;

        // Create marker with info window
        marker = Marker(
          markerId: marker.markerId,
          position: marker.position,
          icon: marker.icon,
          anchor: marker.anchor,
          onTap: cluster.onTap,
          infoWindow: InfoWindow(
            title: station.title ?? 'Stazione di ricarica',
            snippet: station.fullAddress.isNotEmpty
                ? station.fullAddress
                : 'Indirizzo non disponibile',
          ),
        );
      }

      markerSet.add(marker);
    }

    return markerSet;
  }

  // Calculate bounds for a cluster
  LatLngBounds? _calculateClusterBounds(
    Fluster<MarkerCluster> clusterManager,
    MarkerCluster cluster,
  ) {
    if (cluster.clusterId == null) return null;

    // Get all points in this cluster
    List<MarkerCluster> clusterPoints = clusterManager.points(
      cluster.clusterId!,
    );

    if (clusterPoints.isEmpty) return null;

    final latitudes = clusterPoints.map((m) => m.position.latitude).toList();
    final longitudes = clusterPoints.map((m) => m.position.longitude).toList();

    final northEast = LatLng(latitudes.reduce(max), longitudes.reduce(max));
    final southWest = LatLng(latitudes.reduce(min), longitudes.reduce(min));

    return LatLngBounds(northeast: northEast, southwest: southWest);
  }
}
