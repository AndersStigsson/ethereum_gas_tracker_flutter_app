import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _biggerFont = TextStyle(fontSize: 18.0);
  final String gasPriceURL = "https://ethgas.watch/api/gas";
  final String gasPriceURLProvider = "https://api.felip.se/gas/";
  final String providersURL = "https://api.felip.se/providers";
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  int lastUpdated = 0;

  String providerSelected = "All";
  List providers;
  List gasFees;
  List sources;
  

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      }
    );
    _firebaseMessaging.subscribeToTopic("ethereum_gas");
    this.getGasData("All");
    this.getProviders();
  }

  setUpTimedFetch() {
    Timer.periodic(Duration(seconds: 60), (timer) {
      getGasData(providerSelected);
    });
  }


  void getProviders() async {
    Response res = await get(providersURL);
    var convertDataFromJson = jsonDecode(res.body);
    setState(() {
      //slow = convertDataFromJson['slow'];
      //normal = convertDataFromJson['normal'];
      //fast = convertDataFromJson['fast'];
      providers = convertDataFromJson['providers'];
      providers.insert(0, "All");

    });
    print(providers);
  }

  void getGasData(String provider) async {
    var _url = "";
    if(provider == "All"){
      _url = gasPriceURL;
    } else {
      _url = gasPriceURLProvider + provider;
      print(_url);
    }
    Response res = await get(_url);
    var convertDataFromJson = jsonDecode(res.body);

    setState(() {
      //slow = convertDataFromJson['slow'];
      //normal = convertDataFromJson['normal'];
      //fast = convertDataFromJson['fast'];
      if(provider == "All") {
        gasFees = [
          convertDataFromJson['slow'],
          convertDataFromJson['normal'],
          convertDataFromJson['fast']
        ];
        lastUpdated = convertDataFromJson['lastUpdated'];
      } else {
        gasFees = [
          convertDataFromJson['unified']['slow'],
          convertDataFromJson['unified']['medium'],
          convertDataFromJson['unified']['fast']
        ];
      }


    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Gas tracker with update functionality")),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.refresh),
          onPressed: () {
            print("Refreshed");
            getGasData(providerSelected);
          },
        ),
        body: Column(children: [
          DropdownButton<String>(
              items: providers != null ? providers.map((item) {
                return DropdownMenuItem<String>(
                  child: Text(item),
                  value: item,
                );
              }).toList() : [],
              onChanged: (value) {
                setState(() {
                  providerSelected = value;
                });
                getGasData(providerSelected);
              },
              value: providerSelected
          ),
          Expanded(
            child: ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: gasFees != null ? gasFees.length : 0,
                itemBuilder: /*1*/ (context, i) {
                  if(providerSelected == "All"){
                    return ListTile(
                      title: Text("${gasFees[i]['gwei']}"),
                      subtitle: Text("${gasFees[i]['usd']}"),
                    );
                  } else {
                    return ListTile(
                      title: Text("${gasFees[i]}"),
                      subtitle: Text("${gasFees[i]}"),
                    );
                  }
                }),
          ),
          Text(
              "Last Updated: ${DateTime.fromMillisecondsSinceEpoch(lastUpdated)}"),
        ]));
  }
}
