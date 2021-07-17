import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  BuildContext _context;
  Future<bool> _requestPermission(Permission permission) async {
    var result = await permission.request();
    if (result == PermissionStatus.granted) {
      return true;
    }
    return false;
  }

  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    PermissionStatus status = await permission.status;
    return status;
  }

  /// Requests the users permission to read their contacts.
  Future<bool> requestContactsPermission(BuildContext context,
      {Function onPermissionDenied}) async {
    this._context = context;
    var granted = await _requestPermission(Permission.contacts);
    if (!granted && onPermissionDenied != null) {
      onPermissionDenied();
    }
    return granted;
  }

  /// Requests the users permission to read/write to the storage.
  Future<bool> requestStoragePermission(BuildContext context,
      {Function onPermissionDenied}) async {
    this._context = context;
    var granted = await _requestPermission(Permission.storage);
    if (!granted && onPermissionDenied != null) {
      onPermissionDenied();
    }
    return granted;
  }

  /// Requests the users permission to read their microphone.
  Future<bool> requestMicrophonePermission(BuildContext context,
      {Function onPermissionDenied}) async {
    this._context = context;
    var granted = await _requestPermission(Permission.microphone);
    if (!granted && onPermissionDenied != null) {
      onPermissionDenied();
    }
    return granted;
  }

  /// Requests the users permission to their camera.
  Future<bool> requestCameraPermission(BuildContext context,
      {Function onPermissionDenied}) async {
    this._context = context;
    var granted = await _requestPermission(Permission.camera);
    if (!granted && onPermissionDenied != null) {
      onPermissionDenied();
    }
    return granted;
  }

  /// Requests the users permission to read their location when the app is in use
  Future<bool> requestLocationPermission(BuildContext context,
      {Function onPermissionDenied}) async {
    this._context = context;
    var granted = await _requestPermission(Permission.location);
    if (!granted && onPermissionDenied != null) {
      onPermissionDenied();
    }
    return granted;
  }

  /// Check if the app has already granted the Contacts Permission.
  Future<bool> hasContactsPermission() async {
    return hasPermission(Permission.contacts);
  }

  /// Check if the app has already granted the Storage Permission.
  Future<bool> hasStoragePermission() async {
    return hasPermission(Permission.storage);
  }

  /// Check if the app has already granted the Microphone Permission.
  Future<bool> hasMicrophonePermission() async {
    return hasPermission(Permission.microphone);
  }

  /// Check if the app has already granted the Camera Permission.
  Future<bool> hasCameraPermission() async {
    return hasPermission(Permission.camera);
  }

  /// Check if the app has already granted the Location Permission.
  Future<bool> hasLocationPermission() async {
    return hasPermission(Permission.location);
  }

  Future<bool> hasPermission(Permission permission) async {
    var permissionStatus = await permission.status;
    return permissionStatus == PermissionStatus.granted;
  }
}
