import 'dart:async';
import 'package:clustering_google_maps/src/aggregated_points.dart';
import 'package:clustering_google_maps/src/aggregation_setup.dart';
import 'package:clustering_google_maps/src/cluster_item.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:meta/meta.dart';

class ClusteringHelper {
  ClusteringHelper.forMemory({
    @required this.list,
    @required this.updateMarkers,
    @required this.tapCallback,
    this.maxZoomForAggregatePoints = 13.5,
    @required this.aggregationSetup,
  })  : assert(list != null),
        assert(aggregationSetup != null);

  //After this value the map show the single points without aggregation
  final double maxZoomForAggregatePoints;

  //Custom bitmap: string of assets position
  final AggregationSetup aggregationSetup;

  GoogleMapController mapController;

  //Variable for save the last zoom
  double currentZoom = 0.0;

  //Function called when the map must show single point without aggregation
  // if null the class use the default function
  Function showSinglePoint;

  //Function for update Markers on Google Map
  Function updateMarkers;

  Function tapCallback;

  //List of points for memory clustering
  List<ClusterItem> list;

  //Call during the editing of CameraPosition
  //If you want updateMap during the zoom in/out set forceUpdate to true
  //this is NOT RECCOMENDED
  onCameraMove(CameraPosition position, {forceUpdate = false}) {
    currentZoom = position.zoom;
    if (forceUpdate) {
      updateMap();
    }
  }

  //Call when user stop to move or zoom the map
  Future<void> onMapIdle() async {
    updateMap();
  }

  updateMap() {
    if (currentZoom < maxZoomForAggregatePoints) {
      updateAggregatedPoints(zoom: currentZoom);
    } else {
      if (showSinglePoint != null) {
        showSinglePoint();
      } else {
        updatePoints(currentZoom);
      }
    }
  }

  // Used for update list
  // NOT RECCOMENDED for good performance (SQL IS BETTER)
  updateData(List<ClusterItem> newList) {
    list = newList;
    updateMap();
  }

  int getZoomLevel(double zoom) {
    int level = 5;
    if (zoom <= aggregationSetup.maxZoomLimits[0]) {
      level = 1;
    } else if (zoom < aggregationSetup.maxZoomLimits[1]) {
      level = 2;
    } else if (zoom < aggregationSetup.maxZoomLimits[2]) {
      level = 3;
    } else if (zoom < aggregationSetup.maxZoomLimits[3]) {
      level = 4;
    } else if (zoom < aggregationSetup.maxZoomLimits[4]) {
      level = 5;
    } else if (zoom < aggregationSetup.maxZoomLimits[5]) {
      level = 6;
    } else if (zoom < aggregationSetup.maxZoomLimits[6]) {
      level = 7;
    }
    return level;
  }

  Future<List<ClusterItem>> getAggregatedPoints(double zoom) async {
    print("loading aggregation");
    int level = getZoomLevel(zoom);

    try {
      List<ClusterItem> aggregatedPoints;
      final latLngBounds = await mapController.getVisibleRegion();
      final listBounds = list.where((p) {
        final double leftTopLatitude = latLngBounds.northeast.latitude;
        final double leftTopLongitude = latLngBounds.southwest.longitude;
        final double rightBottomLatitude = latLngBounds.southwest.latitude;
        final double rightBottomLongitude = latLngBounds.northeast.longitude;

        final bool latQuery = (leftTopLatitude > rightBottomLatitude)
            ? p.getLocation().latitude <= leftTopLatitude &&
                p.getLocation().latitude >= rightBottomLatitude
            : p.getLocation().latitude <= leftTopLatitude ||
                p.getLocation().latitude >= rightBottomLatitude;

        final bool longQuery = (leftTopLongitude < rightBottomLongitude)
            ? p.getLocation().longitude >= leftTopLongitude &&
                p.getLocation().longitude <= rightBottomLongitude
            : p.getLocation().longitude >= leftTopLongitude ||
                p.getLocation().longitude <= rightBottomLongitude;
        return latQuery && longQuery;
      }).toList();

      aggregatedPoints = _retrieveAggregatedPoints(listBounds, List(), level);
      return aggregatedPoints;
    } catch (e) {
      print(e.toString());
      return List<ClusterItem>();
    }
  }

  final List<ClusterItem> aggList = [];

  List<ClusterItem> _retrieveAggregatedPoints(List<ClusterItem> inputList,
      List<ClusterItem> resultList, int level) {
    if (inputList.isEmpty) {
      return resultList;
    }
    final List<ClusterItem> newInputList = List.from(inputList);
    List<ClusterItem> tmp;
    final t = newInputList[0].getGeoHash().substring(0, level);
    tmp = newInputList
        .where((p) => p.getGeoHash().substring(0, level) == t)
        .toList();
    newInputList.removeWhere((p) => p.getGeoHash().substring(0, level) == t);
    double latitude = 0;
    double longitude = 0;
    tmp.forEach((l) {
      latitude += l
          .getLocation()
          .latitude;
      longitude += l
          .getLocation()
          .longitude;
    });
    final count = tmp.length;
    ClusterItem a;
    if (tmp.length == 1)
      a = tmp[0];
    else
      a = AggregatedPoints(LatLng(latitude / count, longitude / count), count);
    resultList.add(a);
    return _retrieveAggregatedPoints(newInputList, resultList, level);
  }

  Future<void> updateAggregatedPoints({double zoom = 0.0}) async {
    List<ClusterItem> aggregation = await getAggregatedPoints(zoom);
    print("aggregation lenght: " + aggregation.length.toString());

    final Set<Marker> markers = Set();

    for (var i = 0; i < aggregation.length; i++) {
      final a = aggregation[i];
      BitmapDescriptor bitmapDescriptor =
          await a.getBitmapDescriptor(aggregationSetup);
      final MarkerId markerId = MarkerId(a.getId());

      final marker = Marker(
        onTap: () {
          tapCallback(a);
        },
        consumeTapEvents: true,
        markerId: markerId,
        position: a.getLocation(),
        icon: bitmapDescriptor,
      );

      markers.add(marker);
    }
    updateMarkers(markers);
  }

  updatePoints(double zoom) async {
    print("update single points");
    try {
      List<ClusterItem> listOfPoints;
      listOfPoints = list;
      Set<Marker> markers = Set();
      for (ClusterItem p in listOfPoints) {
        final MarkerId markerId = MarkerId(p.getId());
        BitmapDescriptor bitmap = await p.getBitmapDescriptor(aggregationSetup);
        markers.add(Marker(
            markerId: markerId,
            position: p.getLocation(),
            consumeTapEvents: true,
            icon: bitmap,
            onTap: () {
              tapCallback(p);
            }));
      }
      updateMarkers(markers);
    } catch (ex) {
      print(ex.toString());
    }
  }
}
