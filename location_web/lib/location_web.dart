import 'dart:html' as js;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:location_platform_interface/location_platform_interface.dart';

/// The web implementation of [LocationPlatform].
///
/// This class implements the `package:location` functionality for the web.
class LocationWebPlugin extends LocationPlatform {
  /// A constructor that allows to use the Location Plugin on the web
  LocationWebPlugin(js.Navigator navigator)
      : _geolocation = navigator.geolocation,
        _permissions = navigator.permissions,
        _accuracy = LocationAccuracy.high;

  final js.Geolocation _geolocation;
  final js.Permissions? _permissions;

  LocationAccuracy _accuracy;

  /// Registers this class as the default instance of [LocationPlatform].
  static void registerWith(Registrar registrar) {
    LocationPlatform.instance = LocationWebPlugin(js.window.navigator);
  }

  @override
  Future<bool> changeSettings({
    required LocationAccuracy accuracy,
    required int interval,
    required double distanceFilter,
  }) async {
    _accuracy = accuracy;
    return true;
  }

  @override
  Future<LocationData> getLocation() async {
    final js.Geoposition result = await _geolocation.getCurrentPosition(
      enableHighAccuracy: _accuracy.index >= LocationAccuracy.high.index,
    );

    return _toLocationData(result);
  }

  @override
  Future<PermissionStatus> hasPermission() async {
    final js.PermissionStatus? result =
        await _permissions?.query(<String, String>{'name': 'geolocation'});

    if (result == null) {
      throw ArgumentError("Couldn't get permission state from browser");
    }

    switch (result.state) {
      case 'granted':
        return PermissionStatus.granted;
      case 'prompt':
        return PermissionStatus.denied;
      case 'denied':
        return PermissionStatus.deniedForever;
      default:
        throw ArgumentError('Unknown permission ${result.state}.');
    }
  }

  @override
  Future<PermissionStatus> requestPermission() async {
    try {
      await _geolocation.getCurrentPosition();
      return PermissionStatus.granted;
    } catch (e) {
      return PermissionStatus.deniedForever;
    }
  }

  @override
  Future<bool> requestService() async {
    return _geolocation != null;
  }

  @override
  Future<bool> serviceEnabled() async {
    return _geolocation != null;
  }

  @override
  Stream<LocationData> get onLocationChanged {
    return _geolocation
        .watchPosition(
            enableHighAccuracy: _accuracy.index >= LocationAccuracy.high.index)
        .map(_toLocationData);
  }

  LocationData _toLocationData(js.Geoposition result) {
    return LocationData.fromMap(<String, double?>{
      'latitude': result.coords?.latitude?.toDouble(),
      'longitude': result.coords?.longitude?.toDouble(),
      'accuracy': 0,
      'altitude': 0,
      'speed': 0,
      'speed_accuracy': 0,
      'heading': 0,
      'time': result.timestamp?.toDouble(),
    });
  }
}
