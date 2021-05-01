import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appmeteo/temperature.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http ;
import 'temperature.dart';
import 'my_flutter_app_icons.dart';


void main() {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.blue,

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Meteo'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String key = "ville";
  List<String> villes = [];
  String villeChoisie ;
  Coordinates coordsVilleChoisie ;
  Temperature temperature ;
  Location location;
  LocationData locationData;
  Stream<LocationData> stream;
  String nameCurrent = "Ville actuelle";

  AssetImage night = AssetImage ("assets/n.jpg");
  AssetImage sun = AssetImage("assets/d1.jpg");
  AssetImage rain = AssetImage("assets/d2.jpg");


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    obtenir();
    location = new Location();
    getFirstLocation();
    listenToStream();
  }



  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        centerTitle: true,
        title: new Text(widget.title),
      ),
      drawer: new Drawer(
        child: new Container(
          child: new ListView.builder(
              itemCount: villes.length+2,
              itemBuilder: (context , i) {
                if(i == 0){
                  return DrawerHeader(
                    child: new Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        texteAvecStyle("Mes Villes " , fontSize: 22.0 ),
                        new RaisedButton(
                          color: Colors.white,
                          elevation: 8.0,
                            child: texteAvecStyle("Ajouter une ville ", color: Colors.blue),
                            onPressed: ajoutVille
                        ),
                      ],
                    ),
                  );
                }else if(i == 1){
                  return new ListTile(
                    title: texteAvecStyle(nameCurrent),
                    onTap: (){
                      setState(() {
                        villeChoisie = null;
                        coordsVilleChoisie = null;
                        Navigator.pop(context);
                      });
                    },
                  );
                }else{
                  String ville = villes[i - 2];
                  return new ListTile(
                    title: texteAvecStyle(ville),
                    trailing: new IconButton(
                        icon: new Icon(Icons.delete , color: Colors.white,) ,
                        onPressed: (()=>supprimer(ville))),
                    onTap: (){
                      setState(() {
                        villeChoisie = ville;
                        coordFromCity();
                        Navigator.pop(context);
                      });
                    },
                  );
                }
          }),
        color: Colors.blue,
        ),

      ),
      body: (temperature == null )
          ? new Center (child: new Text((villeChoisie == null )? nameCurrent: villeChoisie))
          : new Container(width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
        decoration: new BoxDecoration(
          image: new DecorationImage(image: getBackground() , fit: BoxFit.cover),
        ),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            texteAvecStyle((villeChoisie == null)? nameCurrent : villeChoisie , fontSize: 35.0 , fontStyle: FontStyle.italic ),
            texteAvecStyle(temperature.description , fontSize: 25.0),
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                new Image(image: getIcon(),),
                texteAvecStyle(" ${kelToCel(temperature.temp)} C", fontSize: 75.0)
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                extra("${kelToCel(temperature.min)}", MyFlutterApp.down),
                extra("${kelToCel(temperature.max)}" , MyFlutterApp.up),
                extra("${temperature.pressure.toInt()}" , MyFlutterApp.temperatire),
                extra("${temperature.humidity.toInt()}%" , MyFlutterApp.drizzle),
              ],
            )
          ],
        ),
      )

    );

  }

  Text texteAvecStyle(String data , {color: Colors.white , fontSize: 17.0 , fontStyle: FontStyle.italic , textAlign: TextAlign.center}){
    return new Text(
        data,
        textAlign: textAlign,
        style: new TextStyle(
          color: color,
          fontStyle: fontStyle,
          fontSize: fontSize
        ),
    );

  }

  Future<Null> ajoutVille() async {
    return showDialog(
        barrierDismissible: true,
        builder: (BuildContext buildcontext){
          return new SimpleDialog(
            contentPadding: EdgeInsets.all(20.0),
            title: texteAvecStyle("Ajouter une ville " , fontSize: 22.0 , color: Colors.blue ),
            children: [
               new TextField(
                 decoration: new InputDecoration(labelText: "ville: "),
                 onSubmitted: (String str){
                   ajouter(str);
                   Navigator.pop(buildcontext);
                 },
               )
            ],
          );
        },
        context: context,
    );
  }

  void obtenir() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String> list = await sharedPreferences.getStringList(key);
    if(list != null){
      setState(() {
        villes = list;
      });
    }
  }
  void ajouter(String str) async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    villes.add(str);
    await sharedPreferences.setStringList(key, villes);
    obtenir();

  }

  void supprimer(String str) async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    villes.remove(str);
    await sharedPreferences.setStringList(key, villes);
    obtenir();

  }

  AssetImage getBackground(){
    print(temperature.icon);
    if(temperature.icon.contains("n")){
      return night;
    }
    else{
      if(temperature.icon.contains("01") || temperature.icon.contains("02") ||temperature.icon.contains("03") ){
        return sun;
      } else{
        return rain;
      }
    }
  }

  //Location
// on a la position une fois
  getFirstLocation () async{
    try{
      locationData = await location.getLocation();
      print("Nouvelle position : ${locationData.latitude} / ${locationData.longitude}");
      locationToString();
    }catch(e){
      print("Nous avons une erreur :$e");
    }
  }
//a chaque changement de position on a la location au niveau du terminal
  listenToStream(){
    stream = location.onLocationChanged;
    stream.listen((newPosition){

      if((locationData == null) || (newPosition.longitude != locationData.longitude)&& (newPosition.latitude != locationData.latitude)){
      setState(() {
        print("New => ${newPosition.latitude} ---------- ${newPosition.longitude}");
        locationData = newPosition;
        locationToString();
      });
    }});
  }

  locationToString() async{
    if(locationData != null){
      Coordinates coordinates = new Coordinates(locationData.latitude, locationData.longitude);
      final cityName = await Geocoder.local.findAddressesFromCoordinates(coordinates);
      setState(() {
        nameCurrent = cityName.first.locality ;
        api();
      });
      print(cityName.first.locality);

    }
  }

  coordFromCity () async{
    if(villeChoisie != null){
      List<Address> addresses = await Geocoder.local.findAddressesFromQuery(villeChoisie);
      if(addresses.length > 0){
        Address first = addresses.first;
        Coordinates coords = first.coordinates ;
        setState(() {
            coordsVilleChoisie = coords;
            api();
        });
      }
    }
  }

  Column extra(String data , IconData icondata){

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        new Icon(icondata , color: Colors.white, size: 32.0,),
        texteAvecStyle(data)
      ],
    );

  }

  api() async {
    double lat ;
    double lon ;
    if(coordsVilleChoisie != null){
      lat = coordsVilleChoisie.latitude;
      lon = coordsVilleChoisie.longitude;

    }
    else if(locationData != null){
      lat = locationData.latitude;
      lon = locationData.longitude;
    }

    if(lat != null && lon != null) {
      final key = "&APPID=752f182aa0363a3ec9f7f4a3a9d304ee";
      String lang = "&lang=${Localizations.localeOf(context).languageCode}";
      String baseApi = "http://api.openweathermap.org/data/2.5/weather?";
      String coordString = "lat=$lat&lon=$lon";
      String units = "&units=metrics";
      String totalString = baseApi + coordString + units + lang + key ;
      final response = await http.get(totalString);

      if(response.statusCode == 200){
        Map map = json.decode(response.body);
        setState(() {
          temperature = Temperature(map);
          print(lat);
        });
      }
      else{
        print("NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO");
      }
    }
  }

  int kelToCel(double kelv){
    return (kelv-273.15).toInt();
  }

  AssetImage getIcon(){
    String icon = temperature.icon.replaceAll('d','').replaceAll('n', '');
    return AssetImage("assets/$icon.png");

  }

}




