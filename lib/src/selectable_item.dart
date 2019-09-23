import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../clustering_google_maps.dart';

class StateItem extends ClusterItem {
  Future<BitmapDescriptor> getBitmapDescriptor(
      AggregationSetup aggregationSetup) async {
    var icon = aggregationSetup.iconData[getState()];
    if (icon != null)
      return icon;
    return BitmapDescriptor.defaultMarker;
  }

  String getState() {
    return '';
  }
}