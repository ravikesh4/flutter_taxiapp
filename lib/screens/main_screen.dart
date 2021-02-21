import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/allWidgets/divider.dart';
import 'package:uber_clone/allWidgets/progress_dialog.dart';
import 'package:uber_clone/assistants/assistantMethods.dart';
import 'package:uber_clone/assistants/geoFireAssistant.dart';
import 'package:uber_clone/config.dart';
import 'package:uber_clone/dataHandler/appData.dart';
import 'package:uber_clone/models/direction_details.dart';
import 'package:uber_clone/models/nearByAvailableDrivers.dart';
import 'package:uber_clone/screens/login_screen.dart';
import 'package:uber_clone/screens/search_screen.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = "mainScreen";

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DirectionDetails tripDirectionDetails;

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap = 0;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight = 300;

  bool drawerOpen = true;
  bool nearByAvailableDriverKeyLoaded = false;

  BitmapDescriptor nearByIcon;

  @override
  void initState() {
    // TODO: implement initState
    AssistantMethods.getCurrentOnlineUserInfo();
    super.initState();
  }

  DatabaseReference rideRequestRef;

  void saveRideRequest() {
    rideRequestRef =
        FirebaseDatabase.instance.reference().child("Ride Requests").push();

    var pickUp = Provider
        .of<AppData>(context, listen: false)
        .pickUpLocation;
    var dropOff = Provider
        .of<AppData>(context, listen: false)
        .dropOffLocation;

    Map pickUpLocationMap = {
      "latitude": pickUp.latitude.toString(),
      "longitude": pickUp.longitude.toString(),
    };

    Map dropOffLocationMap = {
      "latitude": dropOff.latitude.toString(),
      "longitude": dropOff.longitude.toString(),
    };

    Map rideInfoMap = {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUpLocationMap,
      "dropoff": dropOffLocationMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo.name,
      "rider_phone": userCurrentInfo.mobile,
      "pickup_address": pickUp.placeName,
      "dropoff_address": dropOff.placeName,
    };

    rideRequestRef.set(rideInfoMap);
  }

  void cancelRideRequest() {
    rideRequestRef.remove();
  }


  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 250;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = true;
    });

    saveRideRequest();
  }

  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomPaddingOfMap = 230.0;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });

    locatePosition();
  }

  void displayRideDetailContainer() async {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 240;
      bottomPaddingOfMap = 230.0;
      drawerOpen = false;
    });
  }

  void locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition =
    new CameraPosition(target: latLngPosition, zoom: 14);
    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address =
    await AssistantMethods.searchCoordinateAddress(position, context);
    print("This is your address $address");

    initGeoFireListener();
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(
      key: scaffoldKey,
      // appBar: AppBar(
      //   title: Text('Home Page'),
      // ),
      drawer: Container(
        color: Colors.white,
        width: 255,
        child: Drawer(
          child: ListView(
            children: [
              // drawer header
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/user_icon.png",
                        height: 65,
                        width: 65,
                      ),
                      SizedBox(
                        width: 16,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Profile name',
                            style: TextStyle(
                                fontSize: 16, fontFamily: "Brand-Bold"),
                          ),
                          SizedBox(
                            height: 6,
                          ),
                          Text('Visit Profile'),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              DividerWidget(),
              SizedBox(
                height: 12,
              ),

              // Drawer body

              ListTile(
                leading: Icon(Icons.history),
                title: Text(
                  'History',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text(
                  'Visit Profile',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text(
                  'About',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
              ListTile(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => LoginScreen(),));
                },
                leading: Icon(Icons.info),
                title: Text(
                  'Sign out',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
              mapType: MapType.normal,
              // myLocationButtonEnabled: true,
              myLocationEnabled: true,
              initialCameraPosition: _kGooglePlex,
              mapToolbarEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              polylines: polylineSet,
              markers: markersSet,
              circles: circlesSet,
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;

                setState(() {
                  bottomPaddingOfMap = 300;
                });

                locatePosition();
              },
            ),

            // Hamburger button for drawer
            Positioned(
              top: 10,
              left: 22,
              child: GestureDetector(
                onTap: () {
                  if (drawerOpen) {
                    scaffoldKey.currentState.openDrawer();
                  } else {
                    resetApp();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 6,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7),
                        )
                      ]),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      drawerOpen ? Icons.menu : Icons.close,
                      color: Colors.black,
                    ),
                    radius: 20,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSize(
                vsync: this,
                curve: Curves.bounceIn,
                duration: new Duration(milliseconds: 160),
                child: Container(
                  height: searchContainerHeight,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 16,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7),
                        ),
                      ]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 6,
                        ),
                        Text(
                          'Hi There,',
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Where to?,',
                          style:
                          TextStyle(fontSize: 20, fontFamily: "Brand Bold"),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                          onTap: () async {
                            var res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchScreen(),
                                ));
                            if (res == "obtainDirection") {
                              // await getPlaceDirection();
                              displayRideDetailContainer();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 6,
                                    spreadRadius: 0.5,
                                    offset: Offset(0.7, 0.7),
                                  ),
                                ]),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.blueAccent,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text('Search drop off'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 24,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.home,
                              color: Colors.grey,
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  child: Text(Provider
                                      .of<AppData>(context)
                                      .pickUpLocation !=
                                      null
                                      ? Provider
                                      .of<AppData>(context)
                                      .pickUpLocation
                                      ?.placeName
                                      : "Add Home"),
                                  width:
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .width * 0.75,
                                ),
                                SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  'Your home address',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        DividerWidget(),
                        SizedBox(
                          height: 16,
                        ),
                        GestureDetector(
                          onTap: () async {
                            var res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchScreen(),
                                ));
                            if (res == "obtainDirection") {
                              // await getPlaceDirection();
                              displayRideDetailContainer();
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.work,
                                color: Colors.grey,
                              ),
                              SizedBox(
                                width: 12,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Add Drop Location'),
                                  SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    'Your drop address',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSize(
                vsync: this,
                curve: Curves.bounceIn,
                duration: new Duration(milliseconds: 160),
                child: Container(
                  height: rideDetailsContainerHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.tealAccent,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/taxi.png',
                                  height: 70,
                                  width: 80,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Car",
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      (tripDirectionDetails?.distanceText ==
                                          null)
                                          ? ''
                                          : tripDirectionDetails?.distanceText,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                Text(
                                  ((tripDirectionDetails != null)
                                      ? '₹ ${AssistantMethods.calculateFares(
                                      tripDirectionDetails)}'
                                      : ''),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.moneyCheckAlt,
                                size: 18,
                                color: Colors.black54,
                              ),
                              SizedBox(
                                width: 16,
                              ),
                              Text("Cash"),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.black54,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: RaisedButton(
                            onPressed: () {
                              print("Clicked");
                              displayRequestRideContainer();
                            },
                            color: Theme
                                .of(context)
                                .accentColor,
                            child: Padding(
                              padding: EdgeInsets.all(17),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Request",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Icon(
                                    FontAwesomeIcons.taxi,
                                    color: Colors.white,
                                    size: 26,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16)),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        spreadRadius: 0.5,
                        blurRadius: 16,
                        color: Colors.black54,
                        offset: Offset(0.7, 0.7),
                      )
                    ]),
                height: requestRideContainerHeight,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 12.0,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ColorizeAnimatedTextKit(
                          onTap: () {
                            print("Tap Event");
                          },
                          text: [
                            "Requesting...",
                            "Please wait...",
                            "Finding a driver...",
                          ],
                          textStyle:
                          TextStyle(fontSize: 50.0, fontFamily: "Signatra"),
                          colors: [
                            Colors.green,
                            Colors.purple,
                            Colors.pink,
                            Colors.yellow,
                            Colors.red,
                          ],
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        height: 12.0,
                      ),
                      GestureDetector(
                        onTap: () {
                          cancelRideRequest();
                          resetApp();
                        },
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(width: 2, color: Colors.grey),
                          ),
                          child: Icon(Icons.close, size: 26,),
                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Container(
                        width: double.infinity,
                        child: Text("Cancel Ride", textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                          ),),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> getPlaceDirection() async {
    var initialPostion =
        Provider
            .of<AppData>(context, listen: false)
            .pickUpLocation;
    var finalPostion =
        Provider
            .of<AppData>(context, listen: false)
            .dropOffLocation;

    var pickLatLng = LatLng(initialPostion.latitude, initialPostion.longitude);
    var dropLatLng = LatLng(finalPostion.latitude, finalPostion.longitude);

    showDialog(
      context: context,
      builder: (BuildContext context) =>
          ProgressDialog(
            msg: "Please wait",
          ),
    );

    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickLatLng, dropLatLng);

    setState(() {
      tripDirectionDetails = details;
    });

    Navigator.pop(context);

    print("this is encoded points");
    print(details.encodedPoint);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult =
    polylinePoints.decodePolyline(details.encodedPoint);

    pLineCoordinates.clear();

    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        polylineId: PolylineId("PolylineID"),
        color: Colors.pink,
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickLatLng.latitude > dropLatLng.latitude &&
        pickLatLng.longitude > dropLatLng.longitude) {
      latLngBounds = LatLngBounds(southwest: dropLatLng, northeast: pickLatLng);
    } else if (pickLatLng.longitude > dropLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickLatLng.latitude, dropLatLng.longitude),
          northeast: LatLng(dropLatLng.latitude, pickLatLng.longitude));
    } else if (pickLatLng.latitude > dropLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropLatLng.latitude, pickLatLng.longitude),
          northeast: LatLng(pickLatLng.latitude, dropLatLng.longitude));
    } else {
      latLngBounds = LatLngBounds(southwest: pickLatLng, northeast: dropLatLng);
    }

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
            title: initialPostion?.placeName, snippet: "my Location"),
        position: pickLatLng,
        markerId: MarkerId("pickUpId"));

    Marker dropLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
            title: finalPostion?.placeName, snippet: "DropOff Location"),
        position: dropLatLng,
        markerId: MarkerId("dropOffId"));

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropLocMarker);
    });

    Circle pickUpLocCircle = Circle(
      fillColor: Colors.blue,
      center: pickLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.yellowAccent,
      circleId: CircleId("pickUpId"),
    );

    Circle dropLocCircle = Circle(
      fillColor: Colors.red,
      center: dropLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.purpleAccent,
      circleId: CircleId("dropOffId"),
    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropLocCircle);
    });
  }

  void initGeoFireListener() {
    
    Geofire.initialize('availableDrivers');
    
    Geofire.queryAtLocation(currentPosition.latitude, currentPosition.longitude, 10).listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearByAvailableDrivers nearByAvailableDrivers = NearByAvailableDrivers();
            // keysRetrieved.add(map["key"]);

            nearByAvailableDrivers.key = map['key'];
            nearByAvailableDrivers.latitude = map['latitude'];
            nearByAvailableDrivers.longitude = map['longitude'];

            GeoFireAssistant.nearByAvailableDriversList.add(nearByAvailableDrivers);
            if(nearByAvailableDriverKeyLoaded == true) {
              updateAvailableDriverOnMap();
            }

            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriverOnMap();

            // keysRetrieved.remove(map["key"]);
            break;

          case Geofire.onKeyMoved:
            NearByAvailableDrivers nearByAvailableDrivers = NearByAvailableDrivers();
            nearByAvailableDrivers.key = map['key'];
            nearByAvailableDrivers.latitude = map['latitude'];
            nearByAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.updateDriverNearByLocation(nearByAvailableDrivers);
            updateAvailableDriverOnMap();
          // Update your key's location
            break;

          case Geofire.onGeoQueryReady:
          // All Intial Data is loaded
          //   print(map['result'])
            updateAvailableDriverOnMap();
            break;
        }
      }

      setState(() {});
    });
  }

  void updateAvailableDriverOnMap() {
    setState(() {
      markersSet.clear();
    });

    Set<Marker> tmarker = Set<Marker>();
    for(NearByAvailableDrivers driver in GeoFireAssistant.nearByAvailableDriversList) {
      LatLng driverAvailablePosition = LatLng(driver.latitude, driver.longitude);

      Marker marker = Marker(
          markerId: MarkerId('driver${driver.key}'),
        position: driverAvailablePosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          rotation: AssistantMethods.createRandomNumber(360),
      );

      tmarker.add(marker);
    }

    setState(() {
      markersSet = tmarker;
    });
  }

  void createIconMarker() {
    if(nearByIcon == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, 'assets/images/car_ios.png').then((value) {
        nearByIcon = value;
      });
    }
  }
}
