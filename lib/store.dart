import 'dart:math';

class Store {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String openingTime;
  final String closingTime;
  final double distance;

  Store({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.openingTime,
    required this.closingTime,
    required this.distance,
  });

  factory Store.fromJson(Map<String, dynamic> json, double userLatitude, double userLongitude) {
    double storeLatitude = json['lat'] as double;
    double storeLongitude = json['lon'] as double;

    double distance = calculateDistance(userLatitude, userLongitude, storeLatitude, storeLongitude);

    return Store(
      name: json['tags']['name'] ?? 'Unknown Store',
      address: json['tags']['addr:full'] ?? 'No Address',
      latitude: storeLatitude,
      longitude: storeLongitude,
      openingTime: json['tags']['opening_hours'] ?? 'Not specified',
      closingTime: json['tags']['closing_hours'] ?? 'Not specified',
      distance: distance,
    );
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = (lat2 - lat1) * (3.141592653589793 / 180);
    double dLon = (lon2 - lon1) * (3.141592653589793 / 180);
    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
            (cos(lat1 * (3.141592653589793 / 180)) * cos(lat2 * (3.141592653589793 / 180)) *
                (sin(dLon / 2) * sin(dLon / 2)));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
}
