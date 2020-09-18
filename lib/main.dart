import 'dart:convert';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udharokhata/helpers/stateNotifier.dart';
import 'package:udharokhata/pages/customers.dart';
import 'package:udharokhata/pages/settings.dart';
import 'package:udharokhata/services/autoBackup.dart';
import 'package:udharokhata/services/loadBusinessInfo.dart';

import 'blocs/businessBloc.dart';
import 'models/business.dart';
import 'pages/addBusiness.dart';
import 'pages/signin.dart';

void main() {
  runApp(
    ChangeNotifierProvider<AppStateNotifier>(
      create: (context) => AppStateNotifier(),
      child: MyApp(),
    ),
  );
  BackgroundFetch.registerHeadlessTask(autoBackupData);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(builder: (context, appState, child) {
      return MaterialApp(
        title: 'Khata',
        theme: ThemeData(
            primaryColor: Color(0xFF192a56),
            accentColor: Color(0xFFe74c3c),
            fontFamily: 'Roboto'),
        home: SignIn(),
      );
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final BusinessBloc businessBloc = BusinessBloc();
  int _selectedIndex = 0;
  List<Business> _businesses = [];
  Business _selectedBusiness;

  final List<Widget> _widgetOptions = [
    Customers(),
    Settings(),
  ];

  @override
  void initState() {
    super.initState();
    loadBusinessInfo();
    initPlatformState();
    getAllBusinesses();
  }

  refresh() {
    getAllBusinesses();
  }

  void getAllBusinesses() async {
    List<Business> businesses = await businessBloc.getBusinesss();
    final prefs = await SharedPreferences.getInstance();
    int selectedBusinessId = prefs.getInt('selected_business');
    Business selectedBusiness;
    businesses.forEach((business) {
      if (business.id == selectedBusinessId) {
        selectedBusiness = business;
      }
    });

    businesses.add(null);

    setState(() {
      _businesses = businesses;
      _selectedBusiness = selectedBusiness;
    });
  }

  Future<void> initPlatformState() async {
    if (!mounted) return;
    BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 60,
            stopOnTerminate: false,
            enableHeadless: false,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE), (String taskId) async {
      BackgroundFetch.finish(taskId);
    }).then((int status) {
      print('[BackgroundFetch] configure success: $status');
    }).catchError((e) {
      print('[BackgroundFetch] configure ERROR: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khata',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                fontFamily: 'Poppins')),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DropdownButton<Business>(
              value: _selectedBusiness,
              underline: Container(
                height: 0,
              ),
              onChanged: (Business newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedBusiness = newValue;
                  });
                  changeSelectedBusiness(context, newValue.id);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddBusiness(refresh),
                    ),
                  );
                }
              },
              items: _businesses
                  .map<DropdownMenuItem<Business>>((Business business) {
                if (business != null) {
                  return DropdownMenuItem<Business>(
                    value: business,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                      child: Row(
                        children: [
                          business.logo != null
                              ? Image.memory(
                                  Base64Decoder().convert(business.logo),
                                  width: 16,
                                )
                              : SizedBox(width: 16),
                          SizedBox(width: 8),
                          Text(
                            business.companyName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return DropdownMenuItem<Business>(
                    value: business,
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        Text(
                          "Add/Remove Company",
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ));
              }).toList(),
            ),
          )
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.people), title: Text('Customers')),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu), title: Text('More')),
          ],
          currentIndex: _selectedIndex,
          fixedColor: Colors.deepPurple,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
