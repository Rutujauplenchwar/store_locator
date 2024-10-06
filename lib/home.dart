import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'store_details.dart';
import 'store.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? position;
  String? currentAddress = 'Fetching location...';
  List<Store> nearbyStores = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPosition();
  }

  Future<void> fetchPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        currentAddress = "Location services are disabled.";
      });
      Fluttertoast.showToast(msg: "Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          currentAddress = "Location permission denied.";
        });
        Fluttertoast.showToast(msg: "Please enable location permission.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        currentAddress = "Location permission denied forever.";
      });
      Fluttertoast.showToast(msg: "Please enable location permission from settings.");
      return;
    }

    try {
      Position currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      position = currentPosition;

      List<Placemark> placemarks = await placemarkFromCoordinates(position!.latitude, position!.longitude);
      Placemark place = placemarks[0];
      setState(() {
        currentAddress = "${place.locality}, ${place.country}";
      });

      await fetchNearbyStores(position!.latitude, position!.longitude);
    } catch (e) {
      setState(() {
        currentAddress = "Failed to get location.";
      });
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  Future<void> fetchNearbyStores(double latitude, double longitude) async {
    final int radiusInMeters = 3000;

    final String query = '''
    [out:json];
    node["shop"](around:$radiusInMeters, $latitude, $longitude);
    out;
  ''';

    final Uri uri = Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeQueryComponent(query)}');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      List<Store> stores = [];

      for (var element in data['elements']) {
        if (element['type'] == 'node' && element['tags'] != null) {
          if (element['tags']['name'] != null && element['tags']['name'].isNotEmpty) {
            stores.add(Store.fromJson(element, latitude, longitude));
          }
        }
      }
      setState(() {
        nearbyStores = stores;
      });
    } else {
      throw Exception('Failed to load stores');
    }
  }

  void filterStores(String query) {
    final filteredList = nearbyStores.where((store) {
      return store.name.toLowerCase().contains(query.toLowerCase()) ||
          store.address.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      nearbyStores = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Your Store'),
        backgroundColor: Colors.teal[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                currentAddress ?? 'Fetching location...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search Stores...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: filterStores,
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: nearbyStores.length,
                itemBuilder: (context, index) {
                  var store = nearbyStores[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4,
                    child: ListTile(
                      title: Text(
                        store.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(store.address),
                          Text("Distance: ${store.distance.toStringAsFixed(2)} km"),
                          Text("Open: ${store.openingTime} - ${store.closingTime}"),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreDetailsScreen(storeDetails: store),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
