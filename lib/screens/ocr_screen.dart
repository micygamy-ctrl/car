import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class OcrScreen extends StatefulWidget {
  final Function(double) onOdometerDetected;

  const OcrScreen({super.key, required this.onOdometerDetected});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  File? _image;
  bool _isProcessing = false;
  String? _detectedText;
  double? _detectedOdometer;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (photo == null) return;

      setState(() {
        _image = File(photo.path);
        _isProcessing = true;
        _detectedText = null;
        _detectedOdometer = null;
      });

      await _processImage(File(photo.path));
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      await textRecognizer.close();

      String fullText = recognizedText.text;
      setState(() => _detectedText = fullText);

      // استخراج الأرقام من النص
      double? odometer = _extractOdometer(fullText);

      setState(() {
        _detectedOdometer = odometer;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  double? _extractOdometer(String text) {
    // البحث عن أرقام تشبه قراءة العداد (3-6 أرقام)
    final RegExp regExp = RegExp(r'\b\d{3,6}\b');
    final matches = regExp.allMatches(text.replaceAll(',', '').replaceAll('.', ''));

    List<double> candidates = [];
    for (var match in matches) {
      final value = double.tryParse(match.group(0)!);
      if (value != null && value >= 100 && value <= 999999) {
        candidates.add(value);
      }
    }

    if (candidates.isEmpty) return null;

    // إرجاع أكبر رقم كمحاولة لقراءة العداد
    candidates.sort((a, b) => b.compareTo(a));
    return candidates.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'قراءة العداد بالكاميرا 📷',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // إرشادات
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withAlpha(26),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'كيفية الاستخدام',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E88E5),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.info, color: Color(0xFF1E88E5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTip('📸 التقط صورة واضحة للعداد'),
                  _buildTip('💡 تأكد من الإضاءة الجيدة'),
                  _buildTip('🎯 قرّب الكاميرا من الأرقام'),
                  _buildTip('✅ راجع الرقم قبل التأكيد'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // أزرار الكاميرا
            Row(
              children: [
                Expanded(
                  child: _buildImageButton(
                    icon: Icons.camera_alt,
                    label: 'التقاط صورة',
                    color: const Color(0xFF1E88E5),
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImageButton(
                    icon: Icons.photo_library,
                    label: 'من المعرض',
                    color: const Color(0xFF43A047),
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // الصورة الملتقطة
            if (_image != null) ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _image!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // جاري المعالجة
            if (_isProcessing) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF1E88E5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'جاري قراءة العداد...',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: const Color(0xFF1E88E5),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // النتيجة
            if (!_isProcessing && _image != null) ...[
              if (_detectedOdometer != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withAlpha(51),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'تم اكتشاف قراءة العداد! ✅',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ),
                      const Divider(height: 20),
                      Center(
                        child: Text(
                          '${_detectedOdometer!.toStringAsFixed(0)} كم',
                          style: GoogleFonts.cairo(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E88E5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _image = null;
                                  _detectedOdometer = null;
                                  _detectedText = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'إعادة المحاولة',
                                style: GoogleFonts.cairo(color: Colors.red),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                widget.onOdometerDetected(_detectedOdometer!);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'استخدام الرقم',
                                style: GoogleFonts.cairo(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.orange, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'لم يتم اكتشاف قراءة العداد',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'جرب صورة أوضح مع إضاءة أفضل',
                        style: GoogleFonts.cairo(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _image = null;
                            _detectedText = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'إعادة المحاولة',
                          style: GoogleFonts.cairo(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        tip,
        style: GoogleFonts.cairo(
          color: const Color(0xFF1E88E5),
          fontSize: 13,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(51),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}