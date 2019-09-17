import 'package:geohash/geohash.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../clustering_google_maps.dart';

class ClusterItem {
  bool isSelected = false;
  LatLng getLocation() {
    return null;
  }

  String getId() {
    return null;
  }

  Future<BitmapDescriptor> getBitmapDescriptor(
      AggregationSetup aggregationSetup) async {
    return BitmapDescriptor.defaultMarker;
  }

  String getGeoHash() {
    return Geohash.encode(getLocation().latitude, getLocation().longitude);
  }
}
