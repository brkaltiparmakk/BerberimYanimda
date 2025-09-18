import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<Position?> getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return null;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}
