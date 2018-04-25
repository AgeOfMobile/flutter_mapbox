import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mapbox/mapbox_map.dart';

class MapView extends StatefulWidget {
  MapView({Key key, this.map, this.options}) : super(key: key);

  final MapboxMap map;
  final MapboxMapOptions options;

  @override
  State<StatefulWidget> createState() => new MapViewState();
}

class MapViewState extends State<MapView> {
  bool _initialized = false;
  int _textureId = -1;
  Offset _scaleStartFocal;
  double _zoom;

  Future<Null> _createMapView(Size size, MapboxMapOptions options) async {
    try {
      int textureId = await widget.map
          .create(width: size.width, height: size.height, options: options);

      if (!mounted) {
        return;
      }
      setState(() {
        _textureId = textureId;
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constrains) {
      if (constrains.biggest.isEmpty) {
        return new Container();
      }

      if (!_initialized) {
        _createMapView(constrains.biggest, widget.options);

        _initialized = true;
        return new Container();
      }

      return new GestureDetector(
        onDoubleTap: _onDoubleTap,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        child: new Texture(textureId: _textureId),
      );
    });
  }

  void _onDoubleTap() {}

  void _onScaleStart(ScaleStartDetails details) {
    _scaleStartFocal = details.focalPoint;
    _zoom = 0.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final Offset delta = details.focalPoint - _scaleStartFocal;
    widget.map.moveBy(_textureId, delta.dx, delta.dy, 0);

    if (details.scale != 1.0) {
      RenderBox renderBox = context.findRenderObject();
      Offset focalPoint = renderBox.globalToLocal(details.focalPoint);

      double newZoom = _zoomLevel(details.scale);
      double _zoomBy = newZoom - _zoom;
      widget.map.zoomBy(_textureId, _zoomBy, focalPoint.dx, focalPoint.dy, 0);

      _zoom = newZoom;
    }

    _scaleStartFocal = details.focalPoint;
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _scaleStartFocal = null;
    _zoom = null;
  }

  double _zoomLevel(double scale) {
    return log(scale) / log(pi / 2);
  }
}
