import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _currentAddress;
  Position? _currentPosition;
  String _checkintime = '--:--';
  String _checkouttime = '--:--';
  String? _elapsedtime = '--:--';
  final counter = ValueNotifier<int>(0);
  DateTime? t1;
  DateTime? t2;
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> authBiometrics() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to enter your confirmation',
          options: const AuthenticationOptions(
              useErrorDialogs: false, biometricOnly: true));
      // ···
    } on PlatformException catch (e) {
      if (e.code == auth_error.notEnrolled) {
        // Add handling of no hardware here.
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        // ...
      } else {
        // ...
      }
    }
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      if (position.isMocked) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please disable fake GPS!')));
      } else {
        setState(() {
          _currentPosition = position;
          if (counter.value == 0) {
            _checkintime = DateFormat('hh:mm a').format(DateTime.now());
            t1 = DateTime.now();
          } else if (counter.value == 1) {
            _checkouttime = DateFormat('hh:mm a').format(DateTime.now());
            t2 = DateTime.now();
            _elapsedtime = t2?.difference(t1!).inHours.toString();
          }
        });
        _getAddressFromLatLng(_currentPosition!);
        counter.value++;
      }
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getCurrentPositionSimple() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      if (position.isMocked) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please disable fake GPS!')));
      } else {
        setState(() => _currentPosition = position);
        _getAddressFromLatLng(_currentPosition!);
      }
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  @override
  void initState() {
    _getCurrentPositionSimple();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        body: Stack(children: <Widget>[
      Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [15 / 85, 15 / 85],
                  colors: [Color.fromRGBO(71, 128, 228, 1), Colors.white]))),
      SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(children: [
              CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey,
                  child: Icon(
                    Icons.person,
                    color: Colors.black,
                  )),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Employee Name',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Jabatan',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  )
                ],
              )
            ]),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 400,
                width: MediaQuery.of(context).size.width,
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                        height: 400,
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Expanded(
                                flex: 1,
                                child: StreamBuilder(
                                  stream: Stream.periodic(
                                      const Duration(seconds: 1)),
                                  builder: (context, snapshot) {
                                    return Text(
                                      DateFormat('hh:mm:ss a')
                                          .format(DateTime.now()),
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    );
                                  },
                                )),
                            Expanded(
                                flex: 1,
                                child: StreamBuilder(
                                  stream: Stream.periodic(
                                      const Duration(seconds: 1)),
                                  builder: (context, snapshot) {
                                    return Text(DateFormat('EEEE, dd MMMM yyyy')
                                        .format(DateTime.now()));
                                  },
                                )),
                            Expanded(
                              flex: 3,
                              child: ValueListenableBuilder(
                                  valueListenable: counter,
                                  builder: (context, value, _) {
                                    if (counter.value == 0) {
                                      return ElevatedButton.icon(
                                          onPressed: () async {
                                            await authBiometrics();
                                            _getCurrentPosition();
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blue[100]),
                                          icon: Icon(Icons.fingerprint),
                                          label: Text('Check in'));
                                    } else if (counter.value == 1) {
                                      return ElevatedButton.icon(
                                          onPressed: () async {
                                            await authBiometrics();
                                            _getCurrentPosition();
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.purple[100]),
                                          icon: Icon(Icons.fingerprint),
                                          label: Text('Check out'));
                                    } else {
                                      return ElevatedButton.icon(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'You have finished recording your attendance today.')));
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green[100]),
                                          icon: Icon(Icons.fingerprint),
                                          label: Text('Finished'));
                                    }
                                  }),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Container(
                                  color: Colors.grey.shade200,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                          flex: 2,
                                          child: Icon(Icons.location_on)),
                                      Expanded(flex: 1, child: SizedBox()),
                                      Expanded(
                                          flex: 17,
                                          child:
                                              Text('${_currentAddress ?? ""}')),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                                flex: 1,
                                child: Text.rich(TextSpan(children: [
                                  TextSpan(text: 'Lokasi tidak tepat?  '),
                                  TextSpan(
                                      text: 'Perbarui lokasi?',
                                      style: TextStyle(color: Colors.lightBlue),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _getCurrentPositionSimple();
                                        })
                                ]))),

                            //Text(
                            //  'Lokasi tidak tepat, perbarui lokasi')),
                            Expanded(flex: 1, child: Divider()),
                            Expanded(
                              flex: 2,
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        children: [
                                          Icon(Icons.more_time),
                                          Text(
                                            '${_checkintime}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text('Check in')
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        children: [
                                          Icon(Icons.timer_off_outlined),
                                          Text(
                                            '${_checkouttime}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text('Check out')
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(children: [
                                        Icon(Icons.history),
                                        Text('${_elapsedtime}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text('Total hrs')
                                      ]),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        )),
                  ),
                ),
              ),
            ),
          ],
        ),
      ))
    ]));
  }
}
