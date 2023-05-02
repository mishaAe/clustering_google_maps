import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../clustering_google_maps.dart';

class StateItem extends ClusterItem {
  Future<BitmapDescriptor> getBitmapDescriptor(
    AggregationSetup aggregationSetup,
  ) async {
    if (isSelected()) {
      return aggregationSetup.selectedIcon!;
    }
    final icon = aggregationSetup.iconData![getState()] ?? BitmapDescriptor.defaultMarker;
    return icon;
  }

  String? getState() {
    return null;
  }

  bool isSelected() {
    return false;
  }
}
