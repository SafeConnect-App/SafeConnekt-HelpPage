import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mime/mime.dart'; // Import the mime package

class VehicleDataPage extends StatefulWidget {
  @override
  _VehicleDataPageState createState() => _VehicleDataPageState();
}

class _VehicleDataPageState extends State<VehicleDataPage> {
  Uint8List? _selectedImage;
  String? _fileName;
  String? _mediaType; // To store media type ('image' or 'video')
  Position? _currentPosition;
  String? _address;

  @override
  Widget build(BuildContext context) {
    final String vehicleNumber =
        ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle Number: $vehicleNumber'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchVehicleData(vehicleNumber),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final vehicleData = snapshot.data!['Data'];
            if (vehicleData != null && vehicleData.isNotEmpty) {
              final qrCodeUrl = vehicleData[0]['qrcode_url'];
              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$vehicleNumber',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildItemWithIcon(
                          'Owner Name: ${vehicleData[0]['owner_name']}',
                          Icons.person,
                          Colors.blue,
                        ),
                        SizedBox(height: 16),
                        _buildItemWithIcon(
                          'Vehicle Type: ${vehicleData[0]['vehicle_type']}',
                          Icons.directions_car,
                          Colors.orange,
                        ),
                        SizedBox(height: 16),
                        _buildItemWithIcon(
                          'Vehicle Brand: ${vehicleData[0]['vehicle_brand']}',
                          Icons.directions_car,
                          Colors.orange,
                        ),
                        SizedBox(height: 16),
                        _buildItemWithIcon(
                          'Vehicle Number: ${vehicleData[0]['vehicle_no']}',
                          Icons.confirmation_number,
                          Colors.orange,
                        ),
                        SizedBox(height: 16),
                        _buildItemWithIconAndAction(
                          'Email: ${vehicleData[0]['email']}',
                          Icons.email,
                          Colors.blue,
                          () {
                            _launchEmail(vehicleData[0]['email']);
                          },
                          'Email',
                        ),
                        SizedBox(height: 16),
                        _buildItemWithIconAndAction(
                          'Contact Number',
                          Icons.phone,
                          Colors.green,
                          () {
                            _launchPhoneDialer(
                                vehicleData[0]['contact_number']);
                          },
                          'Call',
                        ),
                        SizedBox(height: 16),
                        _buildItemWithIconAndAction(
                          'Emergency Number',
                          Icons.error,
                          Colors.red,
                          () {
                            _launchPhoneDialer(
                                vehicleData[0]['emergency_number']);
                          },
                          'SOS',
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _showImageSourceActionSheet(
                                context, vehicleData[0]['emergency_number']);
                          },
                          child: Text('Capture and Upload Image'),
                        ),
                        SizedBox(height: 16),
                        _selectedImage != null
                            ? Column(
                                children: [
                                  Image.memory(_selectedImage!,
                                      width: 200, height: 200),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      _submitImage(
                                          vehicleData[0]['emergency_number']);
                                    },
                                    child: Text('Submit Image'),
                                  ),
                                ],
                              )
                            : Container(),
                        FutureBuilder<Uint8List?>(
                          future: _fetchQrCodeImage(qrCodeUrl),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Failed to load QR code image');
                            } else if (snapshot.hasData) {
                              return Column(
                                children: [
                                  SizedBox(height: 16),
                                  Text(
                                    'QR Code',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: Image.memory(
                                      snapshot.data!,
                                      width: 200,
                                      height: 200,
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Text('No data available');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return Center(
                  child: Text('No data available for $vehicleNumber'));
            }
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  Widget _buildItemWithIcon(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 18, color: color),
        ),
      ],
    );
  }

  Widget _buildItemWithIconAndAction(String text, IconData icon, Color color,
      VoidCallback? onPressed, String actionText) {
    return onPressed != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
            ),
            label: Text(
              actionText,
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: color),
          )
        : Row(
            children: [
              Icon(
                icon,
                color: color,
              ),
              SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(fontSize: 18, color: color),
              ),
            ],
          );
  }

  Future<Map<String, dynamic>> _fetchVehicleData(String vehicleNumber) async {
    final Uri url = Uri.parse(
        'https://safeconnekt-f9f414081a75.herokuapp.com/vehicle/get_vehicle_data$vehicleNumber');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load vehicle data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching vehicle data: $e');
      throw Exception('Failed to load vehicle data: $e');
    }
  }

  Future<Uint8List?> _fetchQrCodeImage(String qrCodeUrl) async {
    try {
      final response = await http.get(Uri.parse(qrCodeUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to load QR code image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching QR code image: $e');
      throw Exception('Failed to load QR code image: $e');
    }
  }

  void _launchEmail(String email) async {
    final Uri _emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    await launch(_emailLaunchUri.toString());
  }

  void _launchPhoneDialer(String phoneNumber) async {
    final Uri _phoneLaunchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launch(_phoneLaunchUri.toString());
  }

  Future<void> _showImageSourceActionSheet(
      BuildContext context, String emergencyContact) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromGallery();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera),
                  title: Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _captureImageFromCamera();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImage = result.files.first.bytes;
        _fileName = result.files.first.name;
        _mediaType = 'image'; // Set _mediaType to 'image'
      });
    }
  }

  Future<void> _captureImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = bytes;
        _fileName = pickedFile.name;
        _mediaType = 'image'; // Set _mediaType to 'image'
      });
    }
  }

  Future<void> _submitImage(String emergencyContact) async {
    await Firebase.initializeApp();
    if (_selectedImage == null) return; // No image/video selected

    final String randomId = DateTime.now().millisecondsSinceEpoch.toString();
    final String contactWithCountryCode = "+91$emergencyContact";

    try {
      // 1. Get Location and Address FIRST
      _currentPosition = await getLocation();
      if (_currentPosition != null) {
        _address = await getAddressFromLatLng(_currentPosition!);
      } else {
        _address = 'Location not available';
      }

      // 2. Proceed with Image Upload only if location/address is available
      if (_selectedImage == null) return;

      final String randomId = DateTime.now().millisecondsSinceEpoch.toString();
      final String contactWithCountryCode = "+91$emergencyContact";

      // Use mime package to determine the file type (image or video)
      final mimeType = lookupMimeType(_fileName!)!.split('/')[0];
      _mediaType = mimeType;

      // Use the correct file extension based on mimeType
      final fileExtension = mimeType == 'image' ? 'jpg' : 'mp4';

      final firebase_storage.Reference ref =
          firebase_storage.FirebaseStorage.instance.ref().child(
              'logs/${DateTime.now().millisecondsSinceEpoch}.$fileExtension');

      final firebase_storage.UploadTask uploadTask =
          ref.putData(_selectedImage!);

      final firebase_storage.TaskSnapshot downloadUrl = await uploadTask;
      final String mediaUrl = await downloadUrl.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(contactWithCountryCode)
          .collection('logsForEmergencyContact')
          .doc(randomId)
          .set({
        'mediaLink': mediaUrl,
        'address': _address,
        'type': _mediaType,
        'duration_seconds':
            'null', // You'll need to implement duration logic (for videos)
        'google_maps_url': _currentPosition != null
            ? 'https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}'
            : 'Location not available',
        'latitude': _currentPosition?.latitude ?? null, // Add latitude
        'longitude': _currentPosition?.longitude ?? null, // Add longitude
      });

      setState(() {
        _selectedImage = null;
        _fileName = null;
        _mediaType = null;
        _currentPosition = null;
        _address = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Media uploaded successfully')),
      );
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload media')),
      );
    }
  }

  // Function to get the user's current location
  Future<Position> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  // Function to get address from latitude and longitude
  Future<String> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String address =
            "${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
        return address;
      } else {
        return "Address not found";
      }
    } catch (e) {
      return "Error getting address: $e";
    }
  }
}