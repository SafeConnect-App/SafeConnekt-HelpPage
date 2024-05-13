
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/home_page.dart';
import 'package:flutter_application_1/search_page.dart';
import 'package:flutter_application_1/vehicle_data_page.dart';


void main() async {
    WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Data',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: (settings) {
        final arguments = settings.arguments;
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => HomePage());
          case '/registered_vehicles':
            return MaterialPageRoute(builder: (context) => InputPage());
          default:
            if (settings.name != null && settings.name!.startsWith('/registered_vehicles/')) {
              // Extract vehicle number from the route
              final vehicleNumber = settings.name!.split('/').last;
              return MaterialPageRoute(
                builder: (context) => VehicleDataPage(),
                settings: RouteSettings(name: settings.name, arguments: vehicleNumber),
              );
            }
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
            );
        }
      },
    );
  }
}




