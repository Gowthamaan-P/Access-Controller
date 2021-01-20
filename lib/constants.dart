import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class Constants{
  BluetoothDevice _server;
  String _message;

  Constants(this._message, this._server);

  set server (BluetoothDevice newServer){
    this._server = newServer;
  }

  set message (String data){
    this._message = data;
  }

  BluetoothDevice get server => this._server;
  String get message => this._message;
}

Constants obj = Constants("a", null);