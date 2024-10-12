import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerScreen extends StatefulWidget {
  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _pickedLocation;

  void _selectLocation(LatLng location) {
    setState(() {
      _pickedLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เลือกตำแหน่งบนแผนที่'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _pickedLocation == null
                ? null
                : () {
                    Navigator.pop(context, _pickedLocation);
                  },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(13.7563, 100.5018), // พิกัดเริ่มต้น (กรุงเทพฯ)
          zoom: 12,
        ),
        onTap: _selectLocation,
        markers: _pickedLocation != null
            ? {
                Marker(
                  markerId: MarkerId('picked-location'),
                  position: _pickedLocation!,
                )
              }
            : {},
      ),
    );
  }
}
