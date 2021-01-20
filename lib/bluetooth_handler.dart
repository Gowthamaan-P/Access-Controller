import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:qr/constants.dart';
import 'package:qr/main.dart';


class BluetoothHandler extends StatefulWidget {
  @override
  _BluetoothHandlerState createState() => _BluetoothHandlerState();
}

class _BluetoothHandlerState extends State<BluetoothHandler> {

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer _discoverableTimeoutTimer;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name;
      });
    });

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth Handler", style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Color(0xFF0D47A1),
      ),
      backgroundColor: Colors.white,
      body: Container(
        child: Column(
          children: <Widget>[
            SwitchListTile(
              title: key('Enable Bluetooth'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async {
                  // async lambda seems to not working
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }

                future().then((_) {
                  setState(() {});
                });
              },
            ),
            ListTile(
              title: key('Local adapter address'),
              subtitle: value(_address),
            ),
            ListTile(
              title: key('Local adapter name'),
              subtitle: value(_name),
              onLongPress: null,
            ),
            Divider(),
            ListTile(
              title: key('Devices discovery and connection'),
              subtitle: Text('Use this pin for pairing: 1234'),
            ),
            Expanded(
              child: ListTile(
                  title: RaisedButton(
                      color: Colors.blueAccent,
                      child: const Text('Connect to device'),
                      onPressed: () async {
                        final BluetoothDevice selectedDevice =
                        await Navigator.of(context).push(MaterialPageRoute(builder: (context) {return DiscoveryPage();},),
                        );

                        if (selectedDevice != null) {
                          print('Discovery -> selected ' + selectedDevice.address);
                        } else {
                          print('Discovery -> no device selected');
                        }
                      }),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Text key(String title){
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }

  Text value(String title){
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }
}

class DiscoveryPage extends StatefulWidget {
  /// If true, discovery starts on page start, otherwise user must press action button.
  final bool start;

  const DiscoveryPage({this.start = true});

  @override
  _DiscoveryPage createState() => new _DiscoveryPage();
}

class _DiscoveryPage extends State<DiscoveryPage> {
  StreamSubscription<BluetoothDiscoveryResult> _streamSubscription;
  List<BluetoothDiscoveryResult> results = List<BluetoothDiscoveryResult>();
  bool isDiscovering;

  _DiscoveryPage();

  @override
  void initState() {
    super.initState();

    isDiscovering = widget.start;
    if (isDiscovering) {
      _startDiscovery();
    }
  }

  void _restartDiscovery() {
    setState(() {
      results.clear();
      isDiscovering = true;
    });

    _startDiscovery();
  }

  void _startDiscovery() {
    _streamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
          setState(() {
            results.add(r);
          });
        });

    _streamSubscription.onDone(() {
      setState(() {
        isDiscovering = false;
      });
    });
  }

  // @TODO . One day there should be `_pairDevice` on long tap on something... ;)

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    _streamSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0D47A1),
        title: isDiscovering
            ? Text('Discovering devices')
            : Text('Discovered devices'),
        actions: <Widget>[
          isDiscovering
              ? FittedBox(
            child: Container(
              margin: new EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          )
              : IconButton(
            icon: Icon(Icons.replay),
            onPressed: _restartDiscovery,
          )
        ],
      ),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (BuildContext context, index) {
          BluetoothDiscoveryResult result = results[index];
          return BluetoothDeviceListEntry(
            device: result.device,
            rssi: result.rssi,
            onTap: () {
              Navigator.of(context).pop(result.device);
            },
            onLongPress: () async {
              try {
                bool bonded = false;
                if (result.device.isBonded) {
                  print('Unbonding from ${result.device.address}...');
                  await FlutterBluetoothSerial.instance
                      .removeDeviceBondWithAddress(result.device.address);
                  print('Unbonding from ${result.device.address} has succed');
                } else {
                  print('Bonding with ${result.device.address}...');
                  bonded = await FlutterBluetoothSerial.instance
                      .bondDeviceAtAddress(result.device.address);
                  print(
                      'Bonding with ${result.device.address} has ${bonded ? 'succed' : 'failed'}.');
                  if(bonded){
                    obj.server = result.device;
                    Navigator.of(context).push(MaterialPageRoute(builder: (context){return MyHomePage(title: 'Lobby');}));
                  }
                }
                setState(() {
                  results[results.indexOf(result)] = BluetoothDiscoveryResult(
                      device: BluetoothDevice(
                        name: result.device.name ?? '',
                        address: result.device.address,
                        type: result.device.type,
                        bondState: bonded
                            ? BluetoothBondState.bonded
                            : BluetoothBondState.none,
                      ),
                      rssi: result.rssi);
                });
              } catch (ex) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Error occured while bonding'),
                      content: Text("${ex.toString()}"),
                      actions: <Widget>[
                        new FlatButton(
                          child: new Text("Close"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }
}

class BluetoothDeviceListEntry extends ListTile {
  BluetoothDeviceListEntry({
    @required BluetoothDevice device,
    int rssi,
    GestureTapCallback onTap,
    GestureLongPressCallback onLongPress,
    bool enabled = true,
  }) : super(
    onTap: onTap,
    onLongPress: onLongPress,
    enabled: enabled,
    leading:
    Icon(Icons.devices), // @TODO . !BluetoothClass! class aware icon
    title: Text(device.name ?? "Unknown device"),
    subtitle: Text(device.address.toString()),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        rssi != null
            ? Container(
          margin: new EdgeInsets.all(8.0),
          child: DefaultTextStyle(
            style: _computeTextStyle(rssi),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(rssi.toString()),
                Text('dBm'),
              ],
            ),
          ),
        )
            : Container(width: 0, height: 0),
        device.isConnected
            ? Icon(Icons.import_export)
            : Container(width: 0, height: 0),
        device.isBonded
            ? Icon(Icons.link)
            : Container(width: 0, height: 0),
      ],
    ),
  );

  static TextStyle _computeTextStyle(int rssi) {
    /**/ if (rssi >= -35)
      return TextStyle(color: Colors.greenAccent[700]);
    else if (rssi >= -45)
      return TextStyle(
          color: Color.lerp(
              Colors.greenAccent[700], Colors.lightGreen, -(rssi + 35) / 10));
    else if (rssi >= -55)
      return TextStyle(
          color: Color.lerp(
              Colors.lightGreen, Colors.lime[600], -(rssi + 45) / 10));
    else if (rssi >= -65)
      return TextStyle(
          color: Color.lerp(Colors.lime[600], Colors.amber, -(rssi + 55) / 10));
    else if (rssi >= -75)
      return TextStyle(
          color: Color.lerp(
              Colors.amber, Colors.deepOrangeAccent, -(rssi + 65) / 10));
    else if (rssi >= -85)
      return TextStyle(
          color: Color.lerp(
              Colors.deepOrangeAccent, Colors.redAccent, -(rssi + 75) / 10));
    else
      /*code symetry*/
      return TextStyle(color: Colors.redAccent);
  }
}