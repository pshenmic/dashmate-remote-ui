import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}


class DashmateCoreStatus {
  final String network;
  final String chain;
  final String p2pService;
  final String dockerStatus;
  final String serviceStatus;
  final String peersCount;
  final String blockHeight;
  final String syncAsset;

  DashmateCoreStatus({
    required this.network,
    required this.chain,
    required this.p2pService,
    required this.dockerStatus,
    required this.serviceStatus,
    required this.peersCount,
    required this.blockHeight,
    required this.syncAsset,
  });

  factory DashmateCoreStatus.fromJson(Map<String, dynamic> json) {
    return DashmateCoreStatus(
      network: json['network'],
      chain: json['chain'],
      p2pService: json['p2pService'],
      dockerStatus: json['dockerStatus'],
      serviceStatus: json['serviceStatus'],
      peersCount: json['peersCount'].toString(),
      blockHeight: json['blockHeight'].toString(),
      syncAsset: json['syncAsset'],
    );
  }
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
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Dashmate Remote UI'),
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
  DashmateCoreStatus? _status = null;

  void _fetchStatus() async {
    print('Fetch_status');

    var response = await http.post(
      Uri.parse('http://127.0.0.1:9999'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 'id',
        'method': 'status core',
        'params': {
          'format': 'json'
        },
      }),
    );

    var json = jsonDecode(response.body);
    var status = DashmateCoreStatus.fromJson(jsonDecode(json['result']));

    setState(() {
      _status = status;
    });
  }

  void _conectSSH() async {
    print('Connecting to ssh');
    final socket = await SSHSocket.connect('18.196.234.11', 22);

    final client = SSHClient(
      socket,
      username: 'ubuntu',
      onPasswordRequest: () {
        stdout.write('Password: ');
        stdin.echoMode = false;
        return stdin.readLineSync() ?? exit(1);
      },
      identities: [
        // A single private key file may contain multiple keys.
        ...SSHKeyPair.fromPem(
            await File('/Users/pshenmic/.ssh/id_rsa_dashdeploy').readAsString())
      ],
    );

    await client.authenticated;

    final serverSocket = await ServerSocket.bind('127.0.0.1', 9999);
    print('Listening on ${serverSocket.address.address}:${serverSocket.port}');

    await for (final socket in serverSocket) {
      final forward = await client.forwardLocal('127.0.0.1', 9000);
      forward.stream.cast<List<int>>().pipe(socket);
      socket.pipe(forward.sink);
    }

    // client.close();
    // await client.done;
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
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          children: [
            Container(child:
              Column(children: [
                ElevatedButton(child: Text('Connect to masternode (via SSH)'), onPressed: _conectSSH),
                ElevatedButton(child: Text('Fetch masternode status'), onPressed: _fetchStatus),
              ],)
            ),
            Divider(
                color: Colors.black
            ),
            _status == null ? Container() :
            Container(child: Column(children: [
              Table(
                children: [
                  TableRow(children: [
                    Text("Network", style: TextStyle(fontSize: 15.0),),
                    Text("${_status?.network}", style: TextStyle(fontSize: 15.0),),
                  ]),
                  TableRow(children: [
                    Text("Chain", style: TextStyle(fontSize: 15.0),),
                    Text("${_status?.chain}", style: TextStyle(fontSize: 15.0),),
                  ]),
                  TableRow(children: [
                    Text("P2P service", style: TextStyle(fontSize: 15.0),),
                    Text("${_status?.p2pService}", style: TextStyle(fontSize: 15.0),),
                  ]),
                  TableRow(children: [
                    Text("Docker Container Status", style: TextStyle(fontSize: 15.0),),
                    Text("${_status?.dockerStatus}", style: TextStyle(fontSize: 15.0),),
                  ]),
                  TableRow(children: [
                    Text("Service Status", style: TextStyle(fontSize: 15.0),),
                    Text("${_status?.serviceStatus}", style: TextStyle(fontSize: 15.0),),
                  ]),
                  TableRow(children: [
                    Text("Peers Count", style: TextStyle(fontSize: 15.0),),
                    Text("${_status?.peersCount}", style: TextStyle(fontSize: 15.0),),
                  ]),
                  TableRow(children: [
                    Text("Block Height", style: TextStyle(fontSize: 15.0),),
                    Text("${_status?.blockHeight}", style: TextStyle(fontSize: 15.0),),
                  ]),
                  TableRow(children: [
                    Text("Sync Asset", style: TextStyle(fontSize: 15.0),),
                    Text("${_status?.syncAsset}", style: TextStyle(fontSize: 15.0),),
                  ]),
                ],
              ),
            ],),)
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
