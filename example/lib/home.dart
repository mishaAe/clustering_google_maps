import 'package:clustering_google_maps/clustering_google_maps.dart';
import 'package:example/app_db.dart';
import 'package:example/fake_point.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:clustering_google_maps/clustering_google_maps.dart'
    show LatLngAndGeohash, ClusteringHelper, AggregationSetup;

class HomeScreen extends StatefulWidget {
  final List<ClusterItem> list;

  HomeScreen({Key key, this.list}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ClusteringHelper clusteringHelper;
  GoogleMapController _mapController;
  ClusterItem currentItem;
  final CameraPosition initialCameraPosition =
      CameraPosition(target: LatLng(0.000000, 0.000000), zoom: 0.0);

  Set<Marker> markers = Set();

  void _onMapCreated(GoogleMapController mapController) async {
    print("onMapCreated");
    _mapController = mapController;
    clusteringHelper.mapController = mapController;
    clusteringHelper.updateMap();
  }

  updateMarkers(Set<Marker> markers) {
    setState(() {
      this.markers = markers;
    });
  }

  @override
  void initState() {
    if (widget.list != null) {
      initMemoryClustering();
    }

    super.initState();
  }

  // For memory solution
  initMemoryClustering() {
    clusteringHelper = ClusteringHelper.forMemory(
      list: widget.list,
      updateMarkers: updateMarkers,
      tapCallback: (ClusterItem item) {
        print("clicckedon");
        print(item);
        if (item is FakePoint) {
          if (currentItem != null)
            currentItem.isSelected = false;
          item.isSelected = true;
          currentItem = item;
          _mapController.animateCamera(CameraUpdate.newLatLng(
              LatLng(item.getLocation().latitude, item.getLocation().longitude)));
        }
      },
      aggregationSetup: AggregationSetup(markerSize: 150),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Clustering Example"),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: initialCameraPosition,
        markers: markers,
        onCameraMove: (newPosition) =>
            clusteringHelper.onCameraMove(newPosition, forceUpdate: false),
        onCameraIdle: clusteringHelper.onMapIdle,
      ),
      floatingActionButton: FloatingActionButton(
        child:
            widget.list == null ? Icon(Icons.content_cut) : Icon(Icons.update),
        onPressed: () {
          //Force map update
          clusteringHelper.updateMap();
        },
      ),
    );
  }
}
