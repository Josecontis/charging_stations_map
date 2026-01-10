import 'dart:ui';

import 'package:fluster/fluster.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Marker cluster model that conforms to the [Clusterable] abstract class.
// Useful for fluster library.
class MarkerCluster extends Clusterable {
  final String id;
  final LatLng position;
  BitmapDescriptor? icon;
  Function()? onTap;
  double alpha;
  bool visible;
  Offset anchor;

  MarkerCluster({
    required this.id,
    required this.position,
    this.icon,
    this.onTap,
    super.isCluster = false,
    super.clusterId,
    super.pointsSize = 0,
    this.alpha = 1.0,
    this.visible = true,
    this.anchor = const Offset(0.5, 1.0),
  }) : super(
         markerId: id,
         latitude: position.latitude,
         longitude: position.longitude,
       );

  // Convert to Google Maps Marker
  Marker toMarker() => Marker(
    markerId: MarkerId(isCluster! ? 'cluster_$id' : id),
    position: LatLng(position.latitude, position.longitude),
    icon: icon ?? BitmapDescriptor.defaultMarker,
    alpha: alpha,
    onTap: onTap,
    visible: visible,
    anchor: anchor,
  );

  MarkerCluster copyWith({
    String? id,
    LatLng? position,
    BitmapDescriptor? icon,
    Function()? onTap,
    double? alpha,
    bool? visible,
    Offset? anchor,
  }) {
    return MarkerCluster(
      id: id ?? this.id,
      position: position ?? this.position,
      icon: icon ?? this.icon,
      onTap: onTap ?? this.onTap,
      alpha: alpha ?? this.alpha,
      visible: visible ?? this.visible,
      anchor: anchor ?? this.anchor,
    );
  }
}
