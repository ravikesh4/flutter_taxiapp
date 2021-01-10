import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/allWidgets/divider.dart';
import 'package:uber_clone/allWidgets/progress_dialog.dart';
import 'package:uber_clone/assistants/requestAssistant.dart';
import 'package:uber_clone/config.dart';
import 'package:uber_clone/dataHandler/appData.dart';
import 'package:uber_clone/models/address.dart';
import 'package:uber_clone/models/place_prediction.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController dropOffTextEditingController = TextEditingController();
  List<PlacePrediction> placePredictionList = [];

  @override
  Widget build(BuildContext context) {

    String placeAddress = Provider.of<AppData>(context).pickUpLocation?.placeName ?? "";
    pickUpTextEditingController.text = placeAddress;

    return Scaffold(
      body: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: 200.0,
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 6.0,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),
                  )
                ]),
                child: Padding(
                  padding:
                      EdgeInsets.only(left: 25, top: 10, right: 25, bottom: 10),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Stack(
                        children: [
                          GestureDetector(
                              child: Icon(Icons.arrow_back),
                          onTap: () {
                                Navigator.pop(context);
                          },
                          ),
                          Center(
                            child: Text(
                              "Set Drop Address",
                              style:
                                  TextStyle(fontSize: 18, fontFamily: "Brand-Bold"),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/pickicon.png",
                            height: 16,
                            width: 16,
                          ),
                          SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(3),
                                child: TextField(
                                  controller: pickUpTextEditingController,
                                  decoration: InputDecoration(
                                    hintText: "Pickup Location",
                                    fillColor: Colors.grey[400],
                                    filled: true,
                                    border: InputBorder.none,
                                    // isDense: true,
                                    contentPadding: EdgeInsets.only(left: 11, top: 0, bottom: 8),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),

                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/desticon.png",
                            height: 16,
                            width: 16,
                          ),
                          SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(3),
                                child: TextField(
                                  onChanged: (val) {
                                    findPlace(val);
                                  },
                                  controller: dropOffTextEditingController,
                                  decoration: InputDecoration(
                                    hintText: "Where to?",
                                    fillColor: Colors.grey[400],
                                    filled: true,
                                    border: InputBorder.none,
                                    // isDense: true,
                                    contentPadding: EdgeInsets.only(left: 11, top: 0, bottom: 8),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              
              
              // title for display prediction
              SizedBox(width: 10.0,),
              (placePredictionList.length > 0) ? Padding(padding: EdgeInsets.all(5),
              child: Container(
                height: 200,
                child: ListView.separated(itemBuilder: (context, index) {
                  return PredictionTile(placePrediction: placePredictionList[index],);
                }, separatorBuilder: (context, index) {
                  return DividerWidget();
                }, itemCount: placePredictionList.length,
                  physics: ClampingScrollPhysics(),
                ),
              ),
              ) : Container(),
              
            ],
          ),
        ),
      ),
    );
  }


  void findPlace(String placeName) async {

    if(placeName.length > 1) {
      String autoCompleteUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${placeName}&key=AIzaSyAXhk1498g3ORPHcP6Wytkouh0Mn28obVo&sessiontoken=1234567890&components=country:in";

      var res = await RequestAssistant.getRequest(autoCompleteUrl);


      if(res == "failed") {
        return;
      }
      // print("Places prediction response:");
      // print(res);

      if(res["status"] == "OK") {
        var predictions = res["predictions"];
        
        var placesList = (predictions as List).map((e) => PlacePrediction.fromJson(e)).toList();
        setState(() {
          placePredictionList = placesList;
        });
        
      }

    }

  }

}

class PredictionTile extends StatelessWidget {
  
  final PlacePrediction placePrediction;

  PredictionTile({this.placePrediction});
  
  @override
  Widget build(BuildContext context) {
    return FlatButton(
      padding: EdgeInsets.all(0.0),
      onPressed: () {
        getPlaceAddressDetails(placePrediction.place_id, context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(width: 10.0,),
            Row(
              children: [
                Icon(Icons.add_location),
                SizedBox(width: 14.0,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.0,),
                      Text(placePrediction.main_text, overflow: TextOverflow.ellipsis ,style: TextStyle(
                        fontSize: 16.0,
                      ),),
                      SizedBox(height: 2.0,),
                      Text(placePrediction.secondary_text,  overflow: TextOverflow.ellipsis ,style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey,
                      ),),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void getPlaceAddressDetails(String placeId, context) async {

    showDialog(context: context,
      builder: (BuildContext context) => ProgressDialog(msg: "Setting drop off, please wait",),
    );

    String placeDetailUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";

    var res = await RequestAssistant.getRequest(placeDetailUrl);

    Navigator.pop(context);

    if(res == 'failed') {
      return;
    }

    if (res['status'] == 'OK') {
      Address address = Address();
      address.placeName = res["result"]["name"];
      address.placeId = placeId;
      address.latitude = res["result"]["geometry"]["location"]["lat"];
      address.longitude = res["result"]["geometry"]["location"]["lng"];

      Provider.of<AppData>(context, listen: false).updateDropOffLocationAddress(address);
      print("drop : ");
      print(address.placeName);

      Navigator.pop(context, "obtainDirection");

    }

  }

}

