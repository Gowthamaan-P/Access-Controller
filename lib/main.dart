import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;

import 'bluetooth_handler.dart';
import 'constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'ElMessiri',
        primarySwatch: Colors.cyan,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Lobby'),
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

  // ignore: non_constant_identifier_names
  File id, qr_users, backup, log, log_backup;
  var display;

  @override
  void initState()  {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setEnabledSystemUIOverlays([]);

    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return WillPopScope(
        child:Scaffold(
          appBar: AppBar(
            title: Text(widget.title, style: TextStyle(color: Colors.white, fontSize: 25),),
            centerTitle: true,
            backgroundColor: Color(0xFF0D47A1),
            automaticallyImplyLeading: false,
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: ListView(
              children: <Widget>[
                SizedBox(height: height*0.05,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: height*0.35,
                        width: width*35,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context){return BluetoothHandler();}));
                          },
                          child: Card(
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                  flex: 3,
                                  child: Icon(Icons.bluetooth, color: Colors.lightBlue, size: height*0.2,),
                                ),
                                Expanded(flex: 1, child: heading("Connection")),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: height*0.35,
                        width: width*35,
                        child: InkWell(
                          onTap: getUsers,
                          child: Card(
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                  flex: 3,
                                  child:Icon(Icons.check_circle_rounded, color: Colors.green[900], size: height*0.2,) ,
                                ),
                                Expanded(flex: 1, child: heading("Allowed List")),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height*0.05,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: height*0.35,
                        width: width*35,
                        child: InkWell(
                          onTap: _register,
                          child: Card(
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                  flex: 3,
                                  child: Icon(Icons.person_add_alt_1_rounded, color: Colors.indigo[900], size: height*0.2,),
                                ),
                                Expanded(flex: 1, child: heading("Enroll")),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: height*0.35,
                        width: width*35,
                        child: InkWell(
                          onTap: _authenticate,
                          child: Card(
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                  flex: 3,
                                  child: Icon(Icons.qr_code_scanner_rounded, color: Colors.brown, size: height*0.2,),
                                ),
                                Expanded(flex: 1, child: heading("Scan & Allow")),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height*0.05,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: height*0.35,
                        width: width*35,
                        child: InkWell(
                          onTap: getLog,
                          child: Card(
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                  flex: 3,
                                  child: Icon(Icons.storage_rounded, color: Colors.deepOrange, size: height*0.2,),
                                ),
                                Expanded(flex: 1, child: heading("Entry Log")),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: height*0.35,
                        width: width*35,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        onWillPop: ()async => false,
    );
  }

  Text heading(String title){
    return Text(
      title,
      style: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        color: Colors.pink,
      ),
    );
  }

  Future<String> get _localPath async {
    display = await getExternalStorageDirectory();
    final directory = await getApplicationDocumentsDirectory();
    await Permission.storage.request();
    print(directory.path);
    print("${directory.path}");
    return directory.path;
  }

  Future<bool> get _localFile async {
    final path = await _localPath;
    id =  File('$path/id.txt');
    backup = File('$path/backup.txt');
    log_backup = File('$path/logBackup.txt');
    qr_users = File('${display.path}/allowedList.txt');
    log = File('${display.path}/entryLog.txt');
    return true;
  }

  Future<bool> searchContent(File file , String target) async {

    try {
      // Read the file
      String contents = await file.readAsString();
      // Returning the contents of the file
      print("$contents");
      if(contents.contains(target))
        return true;
      else
        return false;
    } catch (e) {
      // If encountering an error, return
      print("${e.toString()}");
      return false;
    }
  }

  Future<File> writeContent(String value, File file) async {
    // Write the file
    value = value + "\n";
    return file.writeAsString(value, mode: FileMode.append);
  }

  Future<String> readContent(File file) async {

    try {
      // Read the file
      String contents = await file.readAsString();
      // Returning the contents of the file
      print("Contents $contents");
        return contents;
    } catch (e) {
      // If encountering an error, return
      print("${e.toString()}");
      return e.toString();
    }
  }

  Future _authenticate() async {

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await Permission.camera.request();
    String barcode = await scanner.scan();
    if (barcode == null) {
      print('nothing return.');
    }
    else {
      print("entered $barcode");
      if(obj.server==null){
        showDialog(
            context: context,
            builder: (context) {
              Future.delayed(Duration(seconds: 3), () {
                Navigator.of(context).pop(true);
              });
              return AlertDialog(
                title: Text('Bluetooth Device not Connected', style: TextStyle(color: Colors.redAccent[700]),),
                content: Text('Connect to device for authentication'),
              );
            });
      }
      else{
      if (await _localFile) {
        print(" file got $barcode");
        List<String> data = List();
        data.addAll(LineSplitter().convert(barcode));
        if(await searchContent(id, data[0])) {
          sendMessage('Y');
          print("searched ${data[0]}");
          final str = '${data [0]}    ${data[1]}    ${data[2]}    ${data[3]}    ${DateTime.now().toString().substring(0,19)}    Allowed';
          writeContent(str, log);
          final strg = '${data [0]}|${data[1]}|${data[2]}|${data[3]}|${DateTime.now().toString().substring(0,19)}|ALLOWED';
          writeContent(strg, log_backup);
          showDialog(
              context: context,
              builder: (context) {
                Future.delayed(Duration(seconds: 3), () {
                  Navigator.of(context).pop(true);
                });
                return AlertDialog(
                  title: Text('Authentication Passed', style: TextStyle(color: Colors.greenAccent[700]),),
                  content: Text('Welcome'),
                );
              });
        }
        else{
          sendMessage('N');
          List<String> data = List();
          data.addAll(LineSplitter().convert(barcode));
          print("searched ${barcode.substring(0,4)}");
          final str = '${data [0]}    ${data[1]}    ${data[2]}    ${data[3]}    ${DateTime.now().toString().substring(0,19)}    NOT Allowed';
          writeContent(str, log);
          final strg = '${data [0]}|${data[1]}|${data[2]}|${data[3]}|${DateTime.now().toString().substring(0,19)}|NOT ALLOWED';
          writeContent(strg, log_backup);
          showDialog(
           context: context,
           builder: (context) {
             Future.delayed(Duration(seconds: 3), () {
               Navigator.of(context).pop(true);
             });
             return AlertDialog(
               title: Text('Entry not Allowed', style: TextStyle(color: Colors.redAccent[700]),),
               content: Text('Contact the authorities for entry'),
             );
           });
     }
      }
      }
    }

    SystemChrome.setPreferredOrientations([ ]);
  }

  Future _register() async {

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await Permission.camera.request();
    String barcode = await scanner.scan();
    if (barcode == null) {
      print('nothing return.');
    }
    else {
      print("entered $barcode");
      if(await _localFile){
        List<String> data = List();
        data.addAll(LineSplitter().convert(barcode));
        if(await searchContent(id,  data[0] ))
          {
            showDialog(
                context: context,
                builder: (context) {
                  Future.delayed(Duration(seconds: 3), () {
                    Navigator.of(context).pop(true);
                  });
                  return AlertDialog(
                    title: Text('Account already exists', style: TextStyle(color: Colors.redAccent[700]),),
                    content: Text('Contact the authorities for registration'),
                  );
                });
          }
        else {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Authenticate the User'),
                  content: Text(
                      '''
ID: ${data[0]}
Name: ${data[1]}
Phone number: ${data[2]}
Address: ${data[3]}
                      '''
                  ),
                  actions: <Widget>[
                    RaisedButton(
                        color: Colors.green,
                        child: Text("Add",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontFamily: "MyriadProRegular",
                          ),
                        ),
                        onPressed: () {
                          print(" file got $barcode");
                          writeContent(data[0], id);
                          final str = '${data [0]}    ${data[1]}    ${data[2]}    ${data[3]}    ${DateTime.now().toString().substring(0,19)}';
                          writeContent(str, qr_users);
                          final strg = '${data [0]}|${data[1]}|${data[2]}|${data[3]}|${DateTime.now().toString().substring(0,19)}';
                          writeContent(strg, backup);
                          Navigator.of(context).pop();
                        }),
                    RaisedButton(
                        color: Colors.red,
                        child: Text("Close",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontFamily: "MyriadProRegular",
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        }),
                  ],
                );
              });
        }
      }
    }

    SystemChrome.setPreferredOrientations([ ]);
  }

  void sendMessage(String value) {
    BluetoothConnection connection;
    String text = value.trim();

    BluetoothConnection.toAddress(obj.server.address).then((_connection) async {
      print('Connected to the device');
      print("${obj.server.address}");
      connection = _connection;

      if (text.length > 0) {
        try {
          print("Send inside work");
          connection.output.add(utf8.encode(text + "\r\n"));
          await connection.output.allSent;
          print("Over");
          connection.close();
        } catch (e) {
          // Ignore error, but notify state
          setState(() {});
        }
      }
    });

  }

  void getUsers() async{

    if(await _localFile){
      String user = await readContent(backup);
      List<String> users = List();
      if(user.contains('Error')){
        users =[];
      }
      else{
        users.addAll(LineSplitter().convert(user));
      }
      Navigator.of(context).push(MaterialPageRoute(builder: (context){return Users(users: users,);}));
    }
  }

  void getLog() async{

    if(await _localFile){
      String user = await readContent(log_backup);
      List<String> users = List();
      if(user.contains('Error')){
        users =[];
      }
      else{
        users.addAll(LineSplitter().convert(user));
      }
      Navigator.of(context).push(MaterialPageRoute(builder: (context){return Log(log: users,);}));
    }
  }

}

class Users extends StatefulWidget {

  final List<String> users;
  Users({this.users});
  @override
  _UsersState createState() => _UsersState();
}

class _UsersState extends State<Users> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Authenticated Users", style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Color(0xFF0D47A1),
      ),
      body: (widget.users.length ==0  ) ? Center(child: Text("No users found. Register to add Users"),)
          : ListView(
        children: <Widget>[
          Padding(padding: EdgeInsets.all(5.0) , child: createTable(),)
        ],
      )
    );
  }

  Widget createTable() {
    List<TableRow> rows = [];
    List<String> parts =[];

    rows.add(TableRow(children: [
      TableCell(child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Text('ID',textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.pink, fontSize: 18),),
      ),),
      TableCell(child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Text('NAME',textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.w700, color: Colors.pink, fontSize: 18),),
      ),),
      TableCell(child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Text('PHONE',textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.w700, color: Colors.pink, fontSize: 18),),
      ),),
      TableCell(child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Text('ADDRESS',textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.pink, fontSize: 18),),
      ),),
      TableCell(child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Text('DATE', textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.w700, color: Colors.pink, fontSize: 18),),
      ),),
    ]));

    for (int i=0; i< widget.users.length; i++) {
      parts.addAll(widget.users[i].split('|'));
      rows.add(TableRow(children: [
        TableCell(child: Padding(
          padding: EdgeInsets.all(2.0),
          child: Text('${parts[0]}'),
        ),),
        TableCell(child: Padding(
          padding: EdgeInsets.all(2.0),
          child: Text('${parts[1]}'),
        ),),
        TableCell(child: Padding(
          padding: EdgeInsets.all(2.0),
          child: Text('${parts[2]}'),
        ),),
        TableCell(child: Padding(
          padding: EdgeInsets.all(2.0),
          child: Text('${parts[3]}'),
        ),),
        TableCell(child: Padding(
          padding: EdgeInsets.all(2.0),
          child: Text('${parts[4]}'),
        ),),
      ]));
      parts.clear();
    }

    return Table(
      border:TableBorder.all(width: 1.0,color: Colors.grey),
      children: rows,
    );
  }
}

class Log extends StatefulWidget {
  final List<String> log;
  Log({this.log});
  @override
  _LogState createState() => _LogState();
}

class _LogState extends State<Log> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Entry Log", style: TextStyle(color: Colors.white),),
          centerTitle: true,
          backgroundColor: Color(0xFF0D47A1),
        ),
        body: (widget.log.length ==0  ) ? Center(child: Text("No users entered the room."),)
            : ListView(
          children: <Widget>[
            Padding(padding: EdgeInsets.all(5.0) , child: createTable(),)
          ],
        )
    );
  }

  Widget createTable() {
    List<TableRow> rows = [];
    List<String> parts =[];

    rows.add(TableRow(children: [
      TableCell(child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Text('ID',textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.pink, fontSize: 18),),
      ),),
      TableCell(child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Text('NAME',textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.w700, color: Colors.pink, fontSize: 18),),
      ),),
      TableCell(child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Text('PHONE',textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.w700, color: Colors.pink, fontSize: 18),),
      ),),
      TableCell(child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Text('ADDRESS',textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.pink, fontSize: 18),),
      ),),
      TableCell(child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Text('DATE', textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.w700, color: Colors.pink, fontSize: 18),),
      ),),
      TableCell(child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Text('ACCESS', textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.w700, color: Colors.pink, fontSize: 18),),
      ),),
    ]));

    for (int i=0; i< widget.log.length; i++) {
      parts.addAll(widget.log[i].split('|'));
      rows.add(TableRow(children: [
        TableCell(child: Padding(
          padding: EdgeInsets.all(2.0),
          child: Text('${parts[0]}'),
        ),),
        TableCell(child: Padding(
          padding: EdgeInsets.all(2.0),
          child: Text('${parts[1]}'),
        ),),
        TableCell(child: Padding(
          padding: EdgeInsets.all(2.0),
          child: Text('${parts[2]}'),
        ),),
        TableCell(child: Padding(
          padding: EdgeInsets.all(2.0),
          child: Text('${parts[3]}'),
        ),),
        TableCell(child: Padding(
          padding: EdgeInsets.all(2.0),
          child: Text('${parts[4]}'),
        ),),
        TableCell(child: Padding(
          padding: EdgeInsets.all(2.0),
          child: Text('${parts[5]}'),
        ),),
      ]));
      parts.clear();
    }

    return Table(
      border:TableBorder.all(width: 1.0,color: Colors.grey),
      children: rows,
    );
  }
}
