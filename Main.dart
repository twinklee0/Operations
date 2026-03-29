import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Control App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final VolumeController _volumeController = VolumeController();
  final Battery _battery = Battery();
  int _batteryLevel = 0;
  List<AssetEntity> _images = [];

  @override
  void initState() {
    super.initState();
    _getBatteryLevel();
    _loadGalleryImages();
  }

  Future<void> _getBatteryLevel() async {
    final level = await _battery.batteryLevel;
    setState(() {
      _batteryLevel = level;
    });
  }

  Future<void> _loadGalleryImages() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      final albums = await PhotoManager.getAssetPathList();
      final recentAlbum = albums.first;
      final recentAssets = await recentAlbum.getAssetListRange(start: 0, end: 20);
      setState(() {
        _images = recentAssets;
      });
    }
  }

  void _changeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  void _increaseVolume() {
    _volumeController.getVolume().then((vol) {
      _volumeController.setVolume((vol + 0.1).clamp(0.0, 1.0));
    });
  }

  void _decreaseVolume() {
    _volumeController.getVolume().then((vol) {
      _volumeController.setVolume((vol - 0.1).clamp(0.0, 1.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Device Control App")),
      body: Column(
        children: [
          Text("Battery Level: $_batteryLevel%"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: _changeOrientation, child: Text("Change Orientation")),
              ElevatedButton(onPressed: _increaseVolume, child: Text("Volume +")),
              ElevatedButton(onPressed: _decreaseVolume, child: Text("Volume -")),
            ],
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Card(
                  child: FutureBuilder<Uint8List?>(
                    future: _images[index].thumbnailData,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      }
                      return Center(child: CircularProgressIndicator());
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
