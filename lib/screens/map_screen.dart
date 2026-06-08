import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/map_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapService _mapService = MapService();
  final Completer<GoogleMapController> _mapController = Completer();

  // الموقع الحالي
  LatLng? _currentLocation;

  // الـ Markers على الخريطة
  final Set<Marker> _markers = {};

  // قائمة الأماكن
  List<PlaceModel> _places = [];

  // نوع الفلتر الحالي: 'all' أو 'gas_station' أو 'car_repair'
  String _selectedFilter = 'all';

  bool _isLoading = true;
  String? _errorMessage;

  // BitmapDescriptor للـ Markers
  BitmapDescriptor _gasIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueOrange,
  );
  BitmapDescriptor _repairIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueBlue,
  );

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final position = await _mapService.getCurrentLocation();

    if (position == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذّر الحصول على موقعك\nتأكد من تفعيل خدمة الموقع';
      });
      return;
    }

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    // تحريك الخريطة للموقع الحالي
    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 14),
        ),
      );
    }

    await _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    if (_currentLocation == null) return;

    setState(() => _isLoading = true);

    List<PlaceModel> places;
    if (_selectedFilter == 'all') {
      places = await _mapService.searchAll(
        lat: _currentLocation!.latitude,
        lng: _currentLocation!.longitude,
      );
    } else {
      places = await _mapService.searchNearby(
        lat: _currentLocation!.latitude,
        lng: _currentLocation!.longitude,
        type: _selectedFilter,
      );
    }

    _buildMarkers(places);
    setState(() {
      _places = places;
      _isLoading = false;
    });
  }

  void _buildMarkers(List<PlaceModel> places) {
    _markers.clear();

    // Marker للموقع الحالي
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'موقعك الحالي'),
        ),
      );
    }

    // Markers للأماكن
    for (final place in places) {
      _markers.add(
        Marker(
          markerId: MarkerId(place.placeId),
          position: place.latLng,
          icon: place.type == 'gas_station' ? _gasIcon : _repairIcon,
          onTap: () => _showPlaceBottomSheet(place),
        ),
      );
    }
  }

  void _showPlaceBottomSheet(PlaceModel place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlaceBottomSheet(place: place),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── الخريطة ──────────────────────────────────────────
          _currentLocation == null && !_isLoading
              ? _buildErrorState()
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation ?? const LatLng(30.0444, 31.2357),
                    zoom: 14,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  onMapCreated: (controller) {
                    _mapController.complete(controller);
                    if (_currentLocation != null) {
                      controller.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                              target: _currentLocation!, zoom: 14),
                        ),
                      );
                    }
                  },
                ),

          // ── AppBar مخصص ────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // شريط العنوان
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // زرار الرجوع
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                size: 18, color: Color(0xFF1E88E5)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'محطات الوقود والورش 🗺️',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        // زرار تحديث
                        GestureDetector(
                          onTap: _initMap,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5).withAlpha(26),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.refresh,
                                size: 20, color: Color(0xFF1E88E5)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // فلاتر النوع
                  _buildFilterChips(),
                ],
              ),
            ),
          ),

          // ── مؤشر التحميل ──────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(51),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                          color: Color(0xFF1E88E5)),
                      const SizedBox(height: 12),
                      Text(
                        'جاري البحث في محيطك...',
                        style: GoogleFonts.cairo(
                            color: const Color(0xFF1E88E5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── عدد النتائج ───────────────────────────────────
          if (!_isLoading && _places.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'وُجد ${_places.length} مكان قريب',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF1E88E5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on,
                          color: Color(0xFF1E88E5), size: 16),
                    ],
                  ),
                ),
              ),
            ),

          // ── Legend ──────────────────────────────────────────
          if (!_isLoading && _places.isNotEmpty)
            Positioned(
              bottom: 70,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildLegendItem('محطة وقود', Colors.orange),
                    const SizedBox(height: 6),
                    _buildLegendItem('ورشة سيارات', Colors.blue),
                    const SizedBox(height: 6),
                    _buildLegendItem('موقعك', Colors.red),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'value': 'all', 'label': 'الكل', 'icon': Icons.map},
      {
        'value': 'gas_station',
        'label': 'محطات وقود',
        'icon': Icons.local_gas_station
      },
      {'value': 'car_repair', 'label': 'ورش سيارات', 'icon': Icons.build},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['value'];
          return GestureDetector(
            onTap: () {
              if (_selectedFilter != filter['value']) {
                setState(() => _selectedFilter = filter['value'] as String);
                _loadPlaces();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1E88E5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    filter['label'] as String,
                    style: GoogleFonts.cairo(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[700])),
        const SizedBox(width: 6),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.location_off, color: Colors.red, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'حدث خطأ',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initMap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text('حاول مرة أخرى',
                  style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet Widget
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceBottomSheet extends StatelessWidget {
  final PlaceModel place;

  const _PlaceBottomSheet({required this.place});

  Future<void> _openInGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${place.lat},${place.lng}'
      '&query_place_id=${place.placeId}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGasStation = place.type == 'gas_station';
    final themeColor =
        isGasStation ? const Color(0xFFFB8C00) : const Color(0xFF1E88E5);
    final typeLabel = isGasStation ? 'محطة وقود ⛽' : 'ورشة سيارات 🔧';
    final typeIcon =
        isGasStation ? Icons.local_gas_station : Icons.car_repair;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // النوع badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // badge الحالة
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: place.isOpen
                            ? Colors.green.withAlpha(26)
                            : Colors.red.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        place.isOpen ? '🟢 مفتوح' : '🔴 مغلق',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: place.isOpen ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // النوع
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: themeColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            typeLabel,
                            style: GoogleFonts.cairo(
                              color: themeColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(typeIcon, color: themeColor, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // الاسم
                Text(
                  place.name,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                  ),
                  textAlign: TextAlign.right,
                ),

                const SizedBox(height: 6),

                // العنوان
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        place.address,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.location_on,
                        color: Colors.grey[500], size: 16),
                  ],
                ),

                const SizedBox(height: 12),

                // التقييم
                if (place.rating != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (place.userRatingsTotal != null)
                        Text(
                          '(${place.userRatingsTotal} تقييم)',
                          style: GoogleFonts.cairo(
                              fontSize: 12, color: Colors.grey),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        place.rating!.toStringAsFixed(1),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ...List.generate(5, (i) {
                        final full = i < place.rating!.floor();
                        final half = !full &&
                            i < place.rating! &&
                            place.rating! % 1 >= 0.5;
                        return Icon(
                          full
                              ? Icons.star
                              : half
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: Colors.orange,
                          size: 18,
                        );
                      }).reversed.toList(),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                const Divider(),
                const SizedBox(height: 12),

                // زرار الاتجاهات
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _openInGoogleMaps,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    icon: const Icon(Icons.directions,
                        color: Colors.white, size: 20),
                    label: Text(
                      'الاتجاهات في Google Maps',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}