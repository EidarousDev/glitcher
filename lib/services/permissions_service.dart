import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  final PermissionHandler _permissionHandler = PermissionHandler();
  Future<bool> _requestPermission(PermissionGroup permission) async {
    var result = await _permissionHandler.requestPermissions([permission]);
    if (result[permission] == PermissionStatus.granted) {
      return true;
    }
    return false;
  }

  /// Requests the users permission to read their contacts.
  Future<bool> requestContactsPermission({Function onPermissionDenied}) async {
    var granted = await _requestPermission(PermissionGroup.contacts);
    if (!granted) {
      onPermissionDenied();
    }
    return granted;
  }

  /// Requests the users permission to read/write to the storage.
  Future<bool> requestStoragePermission({Function onPermissionDenied}) async {
    var granted = await _requestPermission(PermissionGroup.storage);
    if (!granted) {
      onPermissionDenied();
    }
    return granted;
  }

  /// Requests the users permission to read their microphone.
  Future<bool> requestMicrophonePermission(
      {Function onPermissionDenied}) async {
    var granted = await _requestPermission(PermissionGroup.microphone);
    if (!granted) {
      onPermissionDenied();
    }
    return granted;
  }

  /// Requests the users permission to their camera.
  Future<bool> requestCameraPermission({Function onPermissionDenied}) async {
    var granted = await _requestPermission(PermissionGroup.camera);
    if (!granted) {
      onPermissionDenied();
    }
    return granted;
  }

  /// Requests the users permission to read their location when the app is in use
  Future<bool> requestLocationPermission({Function onPermissionDenied}) async {
    var granted = await _requestPermission(PermissionGroup.location);
    if (!granted) {
      onPermissionDenied();
    }
    return granted;
  }

  /// Check if the app has already granted the Contacts Permission.
  Future<bool> hasContactsPermission() async {
    return hasPermission(PermissionGroup.contacts);
  }

  /// Check if the app has already granted the Storage Permission.
  Future<bool> hasStoragePermission() async {
    return hasPermission(PermissionGroup.storage);
  }

  /// Check if the app has already granted the Microphone Permission.
  Future<bool> hasMicrophonePermission() async {
    return hasPermission(PermissionGroup.microphone);
  }

  /// Check if the app has already granted the Camera Permission.
  Future<bool> hasCameraPermission() async {
    return hasPermission(PermissionGroup.camera);
  }

  /// Check if the app has already granted the Location Permission.
  Future<bool> hasLocationPermission() async {
    return hasPermission(PermissionGroup.location);
  }

  Future<bool> hasPermission(PermissionGroup permission) async {
    var permissionStatus =
        await _permissionHandler.checkPermissionStatus(permission);
    return permissionStatus == PermissionStatus.granted;
  }
}
