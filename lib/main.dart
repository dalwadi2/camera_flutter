import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:simple_permissions/simple_permissions.dart';

List<CameraDescription> cameras;

Permission permissionFromString(String value) {
  Permission permission;
  for (Permission item in Permission.values) {
    if (item.toString() == value) {
      permission = item;
      break;
    }
  }
  return permission;
}

void main() async {
  await SimplePermissions.requestPermission(
      permissionFromString("Permission.Camera"));
  await SimplePermissions.requestPermission(
      permissionFromString("Permission.WriteExternalStorage"));

  cameras = await availableCameras();

  runApp(new MaterialApp(
    home: new MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _state createState() => new _state();
}

class _state extends State<MyApp> {
  CameraController cameraController;
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Permission _permissionCamera;
  Permission _permissionStorage;

  @override
  void initState() {
    super.initState();
    cameraController =
        new CameraController(cameras[1], ResolutionPreset.medium);
    cameraController.initialize().then((_state) {
      if (!mounted) return;
      setState(() {});
    });

    _permissionCamera = permissionFromString("Permission.Camera");
    _permissionStorage =
        permissionFromString("Permission.WriteExternalStorage");
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  Future<String> saveImage() async {
    String timestamp = new DateTime.now().millisecondsSinceEpoch.toString();
    String filePath = '/storage/emulated/0/Pictures/${timestamp}.jpg';

    if (cameraController.value.isTakingPicture) return null;
    try {
      await cameraController.takePicture(filePath);
    } on CameraException catch (e) {
      showInSnackbar(e.toString());
    }
    return filePath;
  }

  void takePicture() async {
    bool hasCamera = await SimplePermissions.checkPermission(_permissionCamera);
    bool hasStorage =
    await SimplePermissions.checkPermission(_permissionStorage);

    if (!hasCamera || !hasStorage) {
      showInSnackbar("Go to settings and allow permissions");
      return;
    }

    saveImage().then((String filePath) {
      if (mounted && filePath != null)
        showInSnackbar("Picture Saved $filePath");
    });
  }

  void showInSnackbar(String message) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text('My Title'),
      ),
      body: new Container(
        padding: new EdgeInsets.all(32.0),
        child: new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new IconButton(
                    onPressed: takePicture,
                    icon: new Icon(Icons.camera),
                  ),
                  new RaisedButton(
                    onPressed: SimplePermissions.openSettings,
                    child: new Text('Settings'),
                  ),
                ],
              ),
              new AspectRatio(
                aspectRatio: 1.0,
                child: new CameraPreview(cameraController),
              )
            ],
          ),
        ),
      ),
    );
  }
}
