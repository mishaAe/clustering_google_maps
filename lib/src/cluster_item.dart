import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dart_geohash/dart_geohash.dart';
import '../clustering_google_maps.dart';

class ClusterItem {
  LatLng? getLocation() {
    return null;
  }

  String? getId() {
    return null;
  }

  Future<BitmapDescriptor>?  getBitmapDescriptor(
      AggregationSetup  aggregationSetup) async {
    return BitmapDescriptor.defaultMarker;
  }

  String getGeoHash() {
    final geoHash = GeoHasher();
    return geoHash.encode(getLocation()!.latitude, getLocation()!.longitude);
  }
}
