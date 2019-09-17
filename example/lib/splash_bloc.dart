import 'dart:convert';
import 'package:clustering_google_maps/clustering_google_maps.dart';
import 'package:example/app_db.dart';
import 'package:example/fake_point.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sqflite/sqflite.dart';

class SplashBloc {
  Future<List<ClusterItem>> getListOfLatLngAndGeohash(
      BuildContext context) async {
    print("START GET FAKE DATA");
    try {
      final fakeList = await loadDataFromJson(context);
      List<ClusterItem> myPoints = List();
      for (int i = 0; i < fakeList.length; i++) {
        final fakePoint = fakeList[i];
        final p = FakePoint(location: LatLng(fakePoint["LATITUDE"], fakePoint["LONGITUDE"]));
//        FakePoint(
//          LatLng(fakePoint["LATITUDE"], fakePoint["LONGITUDE"]),
//          0,
//        );
        myPoints.add(p);
      }
      print("EXTRACT COMPLETE");
      return myPoints;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> addFakePointsToDB(context) async {
    print("START GET FAKE DATA");
    try {
      final fakeList = await loadDataFromJson(context);
      for (int i = 0; i < fakeList.length; i++) {
        final point = fakeList[i];
        final f = FakePoint(
          location: LatLng(point["LATITUDE"], point["LONGITUDE"]),
          id: i,
        );
        await saveFakePointToDB(f);
      }
      print("EXTRACT COMPLETE");
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<dynamic>> loadDataFromJson(BuildContext context) async {
    final fakeData = await DefaultAssetBundle.of(context)
        .loadString('assets/map_point.json');
    return json.decode(fakeData.toString());
  }

  Future<void> saveFakePointToDB(FakePoint fakePoint) async {
    var db = await AppDatabase.get().getDb();
    try {
      await db.transaction((Transaction txn) async {
        await txn.rawInsert('INSERT INTO '
            '${FakePoint.tblFakePoints}(${FakePoint.dbGeohash},${FakePoint.dbLat},${FakePoint.dbLong})'
            ' VALUES("${fakePoint.geohash}",${fakePoint.location.latitude},${fakePoint.location.longitude})');
      });
    } catch (e) {
      print("erorr = " + e.toString());
      throw Exception(e);
    }
  }
}
