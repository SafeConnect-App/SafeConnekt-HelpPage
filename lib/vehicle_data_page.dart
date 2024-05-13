import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class VehicleDataPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String vehicleNumber = ModalRoute.of(context)!.settings.arguments as String;

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
                            _launchPhoneDialer(vehicleData[0]['contact_number']);
                          },
                          'Call',
                        ),
                        SizedBox(height: 16),
                        _buildItemWithIconAndAction(
                          'Emergency Number',
                          Icons.error,
                          Colors.red,
                          () {
                            _launchPhoneDialer(vehicleData[0]['emergency_number']);
                          },
                          'SOS',
                        ),
                        SizedBox(height: 16),
                        // Fetch and display QR code image
                        FutureBuilder<Uint8List?>(
                          future: _fetchQrCodeImage(qrCodeUrl),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Failed to load QR code image');
                            } else if (snapshot.hasData) {
                              return Column(
                                children: [
                                  SizedBox(height: 16),
                                  Text(
                                    'QR Code',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              return Center(child: Text('No data available for $vehicleNumber'));
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

  Widget _buildItemWithIconAndAction(String text, IconData icon, Color color, VoidCallback? onPressed, String actionText) {
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
    final Uri url = Uri.parse('https://safeconnect-e81248c2d86f.herokuapp.com/vehicle/get_vehicle_data/$vehicleNumber');
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
}
