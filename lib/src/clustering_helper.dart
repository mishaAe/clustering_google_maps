import 'dart:async';
import 'package:clustering_google_maps/clustering_google_maps.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ClusteringHelper {
  ClusteringHelper.forMemory({
    required this.list,
    required this.updateMarkers,
    required this.tapCallback,
    this.maxZoomForAggregatePoints = 13.5,
    required this.aggregationSetup,
  });

  final double maxZoomForAggregatePoints;
  final AggregationSetup aggregationSetup;
  final Function updateMarkers;
  final Function tapCallback;
  final List<ClusterItem> list;

  GoogleMapController? mapController;
  double currentZoom = 0.0;
  Function? showSinglePoint;

  Future<void> onCameraMove(CameraPosition position, {bool forceUpdate = false}) async {
    currentZoom = position.zoom;
    if (forceUpdate) {
      await updateMap();
    }
  }

  Future<void> onMapIdle() => updateMap();

  Future<void> updateMap() async {
    try {
      if (currentZoom < maxZoomForAggregatePoints) {
        await updateAggregatedPoints(zoom: currentZoom);
      } else {
        if (showSinglePoint != null) {
          showSinglePoint!();
        } else {
          await updatePoints(currentZoom);
        }
      }
    } catch (e, st) {
      debugPrint('Error in updateMap: $e\n$st');
      // Fallback to showing all points if there's an error
      await updatePoints(currentZoom);
    }
  }

  Future<void> updateData(List<ClusterItem> newList) async {
    list.clear();
    list.addAll(newList);
    await updateMap();
  }

  int getZoomLevel(double zoom) {
    final limits = aggregationSetup.maxZoomLimits;
    for (int i = 0; i < limits.length; i++) {
      if (zoom <= limits[i]) return i + 1;
    }
    return limits.length + 1;
  }

  Future<List<ClusterItem>> getAggregatedPoints(double zoom) async {
    try {
      final latLngBounds = await mapController?.getVisibleRegion();
      if (latLngBounds == null) return [];

      final filteredList = _getPointsInBounds(list, latLngBounds);
      return _retrieveAggregatedPoints(filteredList, <ClusterItem>[], getZoomLevel(zoom));
    } catch (e, st) {
      debugPrint('getAggregatedPoints error: $e\n$st');
      return [];
    }
  }

  List<ClusterItem> _getPointsInBounds(List<ClusterItem> points, LatLngBounds bounds) {
    return points.where((p) {
      final location = p.getLocation();
      if (location == null) return false;

      final lat = location.latitude;
      final lng = location.longitude;
      final ne = bounds.northeast;
      final sw = bounds.southwest;

      final latValid = (ne.latitude > sw.latitude)
          ? lat <= ne.latitude && lat >= sw.latitude
          : lat <= ne.latitude || lat >= sw.latitude;

      double lngMin = sw.longitude;
      double lngMax = ne.longitude;

      if (lngMin > lngMax) {
        return latValid && (lng >= lngMin || lng <= lngMax);
      } else {
        return latValid && (lng >= lngMin && lng <= lngMax);
      }
    }).toList();
  }

  Future<void> updateAggregatedPoints({double zoom = 0.0}) async {
    final aggregation = await getAggregatedPoints(zoom);
    final markers = <Marker>{};

    for (final point in aggregation) {
      final bitmapDescriptor = await point.getBitmapDescriptor(aggregationSetup);
      if (bitmapDescriptor == null) continue;

      final id = point.getId();
      if (id == null) continue;

      final location = point.getLocation();
      if (location == null) continue;

      markers.add(Marker(
        markerId: MarkerId(id),
        position: location,
        icon: bitmapDescriptor,
        consumeTapEvents: true,
        onTap: () => tapCallback(point),
      ));
    }

    updateMarkers(markers);
  }

  Future<void> updatePoints(double zoom) async {
    try {
      final markers = <Marker>{};
      for (final point in list) {
        final id = point.getId();
        final location = point.getLocation();
        final bitmap = await point.getBitmapDescriptor(aggregationSetup);

        if (id == null || location == null || bitmap == null) continue;

        markers.add(Marker(
          markerId: MarkerId(id),
          position: location,
          icon: bitmap,
          consumeTapEvents: true,
          onTap: () => tapCallback(point),
        ));
      }

      updateMarkers(markers);
    } catch (e, st) {
      debugPrint('Error updating points: $e\n$st');
      // Ensure markers are cleared on error to prevent stale state
      updateMarkers({});
    }
  }

  Future<void> updatePoint(double zoom) async {
    try {
      final aggregation = await getAggregatedPoints(zoom);
      if (aggregation.isEmpty) return;

      final point = aggregation.first;
      final bitmap = await point.getBitmapDescriptor(aggregationSetup);
      final id = point.getId();
      final location = point.getLocation();

      if (bitmap == null || id == null || location == null) return;

      final markers = {
        Marker(
          markerId: MarkerId(id),
          position: location,
          icon: bitmap,
          consumeTapEvents: true,
          onTap: () => tapCallback(point),
        )
      };

      updateMarkers(markers);
    } catch (e) {
      debugPrint('Error updating single point: $e');
    }
  }

  List<ClusterItem> _retrieveAggregatedPoints(
    List<ClusterItem> inputList,
    List<ClusterItem> resultList,
    int level,
  ) {
    if (inputList.isEmpty) {
      return resultList;
    }

    final newInputList = List<ClusterItem>.from(inputList);
    final geoHash = newInputList[0].getGeoHash().substring(0, level);

    final matchingPoints = newInputList.where((p) => p.getGeoHash().substring(0, level) == geoHash).toList();

    newInputList.removeWhere((p) => p.getGeoHash().substring(0, level) == geoHash);

    if (matchingPoints.length == 1) {
      resultList.add(matchingPoints[0]);
    } else {
      double latitude = 0;
      double longitude = 0;

      for (final point in matchingPoints) {
        final location = point.getLocation();
        if (location != null) {
          latitude += location.latitude;
          longitude += location.longitude;
        }
      }

      final count = matchingPoints.length;
      final aggregatedPoint = AggregatedPoints(LatLng(latitude / count, longitude / count), count);
      resultList.add(aggregatedPoint);
    }

    return _retrieveAggregatedPoints(newInputList, resultList, level);
  }
}
