class ChargingStation {
  final String? id;
  final String? title;
  final String? addressLine1;
  final String? town;
  final String? stateOrProvince;
  final String? postcode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final int? numberOfPoints;
  final String? usageType;
  final String? statusType;

  ChargingStation({
    this.id,
    this.title,
    this.addressLine1,
    this.town,
    this.stateOrProvince,
    this.postcode,
    this.country,
    this.latitude,
    this.longitude,
    this.numberOfPoints,
    this.usageType,
    this.statusType,
  });

  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    final addressInfo = json['AddressInfo'];

    return ChargingStation(
      id: json['ID']?.toString(),
      title: addressInfo?['Title'],
      addressLine1: addressInfo?['AddressLine1'],
      town: addressInfo?['Town'],
      stateOrProvince: addressInfo?['StateOrProvince'],
      postcode: addressInfo?['Postcode'],
      country: addressInfo?['Country']?['Title'],
      latitude: addressInfo?['Latitude']?.toDouble(),
      longitude: addressInfo?['Longitude']?.toDouble(),
      numberOfPoints: json['NumberOfPoints'],
      usageType: json['UsageType']?['Title'],
      statusType: json['StatusType']?['Title'],
    );
  }

  String get fullAddress {
    List<String> parts = [];
    if (addressLine1 != null && addressLine1!.isNotEmpty) {
      parts.add(addressLine1!);
    }
    if (town != null && town!.isNotEmpty) parts.add(town!);
    if (stateOrProvince != null && stateOrProvince!.isNotEmpty) {
      parts.add(stateOrProvince!);
    }
    if (postcode != null && postcode!.isNotEmpty) parts.add(postcode!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  @override
  String toString() {
    return 'ChargingStation{id: $id, title: $title, lat: $latitude, lng: $longitude}';
  }
}
