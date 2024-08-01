import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(App(args.firstOrNull));
}

class App extends StatelessWidget {
  final String? filepath;

  const App(this.filepath, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Material(child: MainWidget(filepath)),
    );
  }
}

class MainWidget extends StatefulWidget {
  final String? filepath;

  const MainWidget(this.filepath, {super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

enum BackgroundType {
  white,
  black,
  costom,
}

class _MainWidgetState extends State<MainWidget> {
  BackgroundType _backgroundType = BackgroundType.black;
  Color _customColor = Colors.blue;

  @override
  void initState() {
    super.initState();

    loadColor();
  }

  Future loadColor() async {
    var shared = await SharedPreferences.getInstance();
    var r = shared.getDouble('customColorR');
    var g = shared.getDouble('customColorG');
    var b = shared.getDouble('customColorB');
    if (r != null && g != null && b != null) {
      setState(() {
        _customColor = Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), 1);
      });
    }
  }

  Future storeColor() async {
    var shared = await SharedPreferences.getInstance();
    shared.setDouble('customColorR', _customColor.red.toDouble());
    shared.setDouble('customColorG', _customColor.green.toDouble());
    shared.setDouble('customColorB', _customColor.blue.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        RadioRowItem(
          value: BackgroundType.white,
          groupValue: _backgroundType,
          onChanged: onColorChanged,
          title: 'White',
        ),
        RadioRowItem(
          value: BackgroundType.black,
          groupValue: _backgroundType,
          onChanged: onColorChanged,
          title: 'Black',
        ),
        RadioRowItem(
          value: BackgroundType.costom,
          groupValue: _backgroundType,
          onChanged: onColorChanged,
          title: 'Costom',
        ),
        TextButton(
            onPressed: colorPickerOverlay, child: const Text('Pick color'))
      ]),
      Container(
        alignment: Alignment.center,
        color: switch (_backgroundType) {
          BackgroundType.white => Colors.white,
          BackgroundType.black => Colors.black,
          BackgroundType.costom => _customColor,
        },
        child: FutureBuilder<Widget>(
          future: loadImage(widget.filepath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return FittedBox(
                fit: BoxFit.contain,
                child: snapshot.data!,
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      )
    ]);
  }

  void onColorChanged(BackgroundType? value) {
    setState(() {
      _backgroundType = value!;
    });
  }

  Future<Widget> loadImage(String? filepath) async {
    if (filepath == null) {
      return const Text('No file selected');
    }

    var file = File(filepath);
    if (!(await file.exists())) {
      return const Text('File not found');
    }

    //switch  file extension
    switch (file.path.split('.').last) {
      case 'svg':
        return ScalableImageWidget(
            si: ScalableImage.fromSvgString(await file.readAsString()));
      case 'png':
        return Image.file(file);
      case 'jpg':
        return Image.file(file);
      case 'jpeg':
        return Image.file(file);
      default:
        return const Text('Unsupported file type');
    }
  }

  Future colorPickerOverlay() async {
    var color = await showDialog<Color>(
      context: context,
      builder: (context) {
        var newcolor = _customColor;
        return AlertDialog(
          title: const Text(
            'Select a color',
            style: TextStyle(fontSize: 10),
          ),
          content: SingleChildScrollView(
            child: FittedBox(
              child: ColorPicker(
                pickerColor: _customColor,
                onColorChanged: (color) {
                  newcolor = color;
                },
                pickerAreaHeightPercent: 0.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(newcolor);
              },
              child: const Text('OK', style: TextStyle(fontSize: 10)),
            ),
          ],
        );
      },
    );
    if (color != null) {
      setState(() {
        _customColor = color;
      });
      await storeColor();
    }
  }
}

class RadioRowItem<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final void Function(T?) onChanged;
  final String title;

  const RadioRowItem({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Radio(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
      ),
      Text(title),
    ]);
  }
}
