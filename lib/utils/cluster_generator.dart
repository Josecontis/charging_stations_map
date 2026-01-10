import 'dart:async';
import 'dart:ui';

import 'package:charging_stations/data/models/marker_cluster.dart';
import 'package:fluster/fluster.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Cluster generator for charging stations
class ClusterGenerator {
  // Cache for generated cluster icons to avoid regenerating them
  static final Map<int, BitmapDescriptor> _iconCache = {};

  // Get cluster icon with caching (LOGIC OPTIMIZATION)
  static Future<BitmapDescriptor> getClusterIcon(
    int clusterSize,
    double pixelRatio,
  ) async {
    if (_iconCache.containsKey(clusterSize)) {
      return _iconCache[clusterSize]!;
    }

    // It shows "999+" for clusters with 1000+ stations (GRAPHIC OPTIMIZATION)
    final String displayText = clusterSize > 999
        ? '999+'
        : clusterSize.toString();

    // Generate new icon and cache it
    final icon = await _generateClusterIcon(displayText, pixelRatio);
    _iconCache[clusterSize] = icon;
    return icon;
  }

  // Draw a red circle with the cluster size text inside
  static Future<BitmapDescriptor> _generateClusterIcon(
    String clusterSize,
    double pixelRatio,
  ) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double size = 100.0;
    const double radius = 50.0;
    const Offset center = Offset(size / 2, size / 2);

    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.2);
    canvas.drawCircle(center, size / 2, shadowPaint);

    // Draw white background
    final Paint whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius, whitePaint);

    // Draw red border
    final Paint borderPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 1.5, borderPaint);

    // Draw text
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: clusterSize,
      style: TextStyle(
        fontSize: 14.0 * pixelRatio,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final image = await pictureRecorder.endRecording().toImage(
      (size * pixelRatio).toInt(),
      (size * pixelRatio).toInt(),
    );
    final data = await image.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
  }

  // Initialize cluster manager with markers
  static Future<Fluster<MarkerCluster>> initClusterManager(
    List<MarkerCluster> markers,
    int minZoom,
    int maxZoom,
  ) async {
    return Fluster<MarkerCluster>(
      minZoom: minZoom,
      maxZoom: maxZoom,
      radius: 150,
      extent: 2048,
      nodeSize: 64,
      points: markers,
      createCluster: (BaseCluster? cluster, double? lng, double? lat) =>
          MarkerCluster(
            id: cluster!.id.toString(),
            position: LatLng(lat!, lng!),
            isCluster: cluster.isCluster,
            clusterId: cluster.id,
            pointsSize: cluster.pointsSize!,
          ),
    );
  }
}
