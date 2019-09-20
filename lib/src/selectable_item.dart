import 'package:geohash/geohash.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../clustering_google_maps.dart';

class StateItem extends ClusterItem {
  dynamic state;

  Future<BitmapDescriptor> getBitmapDescriptor(
      AggregationSetup aggregationSetup) async {
    var icon = aggregationSetup.iconData[state.toString()];
    if (icon != null)
      return icon;
    return BitmapDescriptor.defaultMarker;
  }
}