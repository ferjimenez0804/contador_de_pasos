import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';

const LatLng kDefaultCenter = LatLng(20.2394, -99.0944);
const String kTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String kUserAgent = 'com.example.contador_de_pasos';

Polyline _routeLine(List<LatLng> pts) => Polyline(
      points: pts,
      strokeWidth: 6,
      color: AppColors.cobalt,
      borderStrokeWidth: 2.5,
      borderColor: AppColors.ink,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );

Widget _startMarker() => Container(
      decoration: BoxDecoration(
        color: AppColors.lime,
        border: Border.all(color: AppColors.ink, width: 2.5),
        borderRadius: BorderRadius.circular(3),
      ),
    );

/// Mapa en vivo que sigue al usuario y dibuja el trazado de la ruta.
class LiveMap extends StatefulWidget {
  final List<LatLng> route;
  final LatLng? current;
  const LiveMap({super.key, required this.route, required this.current});

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  final MapController _ctrl = MapController();
  bool _ready = false;

  @override
  void didUpdateWidget(covariant LiveMap old) {
    super.didUpdateWidget(old);
    final c = widget.current;
    if (_ready && c != null && c != old.current) {
      _ctrl.move(c, _ctrl.camera.zoom);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _ctrl,
      options: MapOptions(
        initialCenter: widget.current ?? kDefaultCenter,
        initialZoom: 17,
        onMapReady: () {
          _ready = true;
          final c = widget.current;
          if (c != null) _ctrl.move(c, 17);
        },
      ),
      children: [
        TileLayer(urlTemplate: kTileUrl, userAgentPackageName: kUserAgent),
        if (widget.route.length >= 2) PolylineLayer(polylines: [_routeLine(widget.route)]),
        MarkerLayer(
          markers: [
            if (widget.route.isNotEmpty)
              Marker(point: widget.route.first, width: 20, height: 20, child: _startMarker()),
            if (widget.current != null)
              Marker(
                point: widget.current!,
                width: 26,
                height: 26,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ink, width: 3),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Mapa estático de una ruta guardada (ajusta el encuadre a todo el recorrido).
class StaticRouteMap extends StatelessWidget {
  final List<LatLng> route;
  const StaticRouteMap({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final hasRoute = route.length >= 2;
    return FlutterMap(
      options: MapOptions(
        initialCenter: route.isNotEmpty ? route.first : kDefaultCenter,
        initialZoom: 16,
        initialCameraFit: hasRoute
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(route),
                padding: const EdgeInsets.all(48),
                maxZoom: 18,
              )
            : null,
      ),
      children: [
        TileLayer(urlTemplate: kTileUrl, userAgentPackageName: kUserAgent),
        if (hasRoute) PolylineLayer(polylines: [_routeLine(route)]),
        if (route.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(point: route.first, width: 20, height: 20, child: _startMarker()),
              Marker(
                point: route.last,
                width: 32,
                height: 32,
                child: const Icon(Icons.sports_score_rounded, color: AppColors.ink, size: 32),
              ),
            ],
          ),
      ],
    );
  }
}
