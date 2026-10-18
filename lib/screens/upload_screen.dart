// The University of Texas at El Paso: Bryan Perez
// Enhanced with ATS Job Description Input & Multi-Stage Section Scanner

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/resume.dart';
import '../providers/resume_provider.dart';
import '../services/ollama_service.dart';
import '../services/pdf_parser.dart';
import '../services/ocr_services.dart';
import '../services/scoring_service.dart';
import '../widgets/ats_section_scanner.dart';
import '../widgets/scanning_animation.dart';
import 'analysis_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  File? _pickedFile;
  String? _sourceType; // 'pdf' or 'camera'
  bool _isScanning = false;
  bool _isAnalyzing = false;
  bool _cancelRequested = false;

  final TextEditingController _jdController = TextEditingController();
  bool _isJdExpanded = false;

  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _jdController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final messenger = ScaffoldMessenger.of(context);
    if (kIsWeb) {
      await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Web PDF upload not implemented.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result?.files.single.path == null) return;

    final file = File(result!.files.single.path!);
    if (await file.length() > 5 * 1024 * 1024) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('PDF exceeds 5 MB limit.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    setState(() {
      _pickedFile = file;
      _sourceType = 'pdf';
    });
  }

  Future<void> _scanWithCamera() async {
    final messenger = ScaffoldMessenger.of(context);
    if (kIsWeb) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Camera not supported on web.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Camera permission required to scan resumes.'),
          backgroundColor: Colors.grey,
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
            textColor: Colors.black87,
          ),
        ),
      );
      return;
    }

    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null) return;

    final file = File(photo.path);
    if (await file.length() > 5 * 1024 * 1024) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Image exceeds 5 MB limit.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    setState(() {
      _pickedFile = file;
      _sourceType = 'camera';
    });
  }

  Future<void> _startScanThenAnalyze() async {
    if (_pickedFile == null || _isScanning || _isAnalyzing) return;

    setState(() => _isScanning = true);
    _cancelRequested = false;

    try {
      await _scanController.forward(from: 0).orCancel;
    } catch (_) {
      // cancelled
    }
    if (_cancelRequested) {
      setState(() => _isScanning = false);
      return;
    }
    setState(() => _isScanning = false);

    setState(() => _isAnalyzing = true);
    try {
      final text = (_sourceType == 'pdf')
          ? await PdfParserService.extractText(_pickedFile!)
          : await OcrService.extractText(_pickedFile!);

      if (_cancelRequested) throw Exception('Cancelled');

      final targetJd = _jdController.text.trim();
      final resume = Resume(
        fileName: _pickedFile!.path.split(Platform.pathSeparator).last,
        fullText: text,
        file: _pickedFile,
        jobDescription: targetJd.isNotEmpty ? targetJd : null,
      );

      final scored = await ScoringService.analyze(
        resume,
        jobDescription: targetJd.isNotEmpty ? targetJd : null,
        enableLogging: true,
      );

      if (!mounted) return;
      context.read<ResumeViewModel>().updateResume(scored);
      if (targetJd.isNotEmpty) {
        context.read<ResumeViewModel>().setJobDescription(targetJd);
      }

      if (_cancelRequested) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AnalysisScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('Cancelled')
              ? 'Analysis cancelled.'
              : 'Failed to analyze resume: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: OllamaService.baseUrl);
    String statusMsg = '';
    bool testing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.cloud_sync_rounded, color: Color(0xFF7C3AED)),
              SizedBox(width: 10),
              Text(
                'AI Backend Server',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2E1065),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect to your hosted Render backend (e.g. https://your-backend.onrender.com) or local PC Ollama.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Backend URL',
                  labelStyle: const TextStyle(color: Color(0xFF7C3AED), fontSize: 13),
                  hintText: 'https://your-app.onrender.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                  ),
                  prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF7C3AED)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.content_paste, size: 14, color: Color(0xFF7C3AED)),
                    label: const Text('Paste from Clipboard', style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED))),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        setDialogState(() {
                          controller.text = data!.text!.trim();
                        });
                      }
                    },
                  ),
                ],
              ),
              if (testing)
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                    ),
                    SizedBox(width: 10),
                    Text('Testing connection...', style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED))),
                  ],
                )
              else if (statusMsg.isNotEmpty)
                Text(
                  statusMsg,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusMsg.startsWith('✅') ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                setDialogState(() {
                  testing = true;
                  statusMsg = '';
                });
                OllamaService.setBaseUrl(controller.text);
                final ok = await OllamaService.isOllamaRunning();
                setDialogState(() {
                  testing = false;
                  statusMsg = ok
                      ? '✅ Connected! Backend ready for analysis.'
                      : '❌ Unable to reach backend URL.';
                });
              },
              child: const Text('Test Connection', style: TextStyle(color: Color(0xFF7C3AED))),
            ),
            ElevatedButton(
              onPressed: () {
                OllamaService.setBaseUrl(controller.text);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !(_isScanning || _isAnalyzing),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && (_isScanning || _isAnalyzing)) {
          setState(() => _cancelRequested = true);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF5FF),
        appBar: AppBar(
          title: Text(
            'Smart Resume Analyzer',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF2E1065),
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: Color(0xFF7C3AED)),
              tooltip: 'AI Server Settings',
              onPressed: _showServerConfigDialog,
            ),
          ],
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2E1065),
          elevation: 0,
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Pick Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickPdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Upload PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _scanWithCamera,
                          icon: const Icon(Icons.camera_alt, color: Color(0xFF7C3AED)),
                          label: const Text('Scan Camera', style: TextStyle(color: Color(0xFF7C3AED))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF7C3AED)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Job Description Input (Expandable)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEDE9FE)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: const Icon(
                            Icons.work_history_outlined,
                            color: Color(0xFF7C3AED),
                          ),
                          title: const Text(
                            'Target Job Description',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF2E1065),
                            ),
                          ),
                          subtitle: Text(
                            _jdController.text.trim().isNotEmpty
                                ? 'Target JD provided (${_jdController.text.trim().length} chars)'
                                : 'Optional • Match keywords & role fit',
                            style: TextStyle(
                              fontSize: 11,
                              color: _jdController.text.trim().isNotEmpty
                                  ? const Color(0xFF7C3AED)
                                  : Colors.black54,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_jdController.text.trim().isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _jdController.clear();
                                    });
                                  },
                                ),
                              Icon(
                                _isJdExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: const Color(0xFF7C3AED),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _isJdExpanded = !_isJdExpanded;
                            });
                          },
                        ),
                        if (_isJdExpanded)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _jdController,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Paste job description or requirements here to analyze ATS match rate, find missing keywords, and tailor bullet points...',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    fillColor: const Color(0xFFFAF5FF),
                                    filled: true,
                                    contentPadding: const EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE9D5FF),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE9D5FF),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF7C3AED),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.content_paste, size: 16, color: Color(0xFF7C3AED)),
                                      label: const Text('Paste from Clipboard', style: TextStyle(color: Color(0xFF7C3AED))),
                                      onPressed: () async {
                                        final data =
                                            await Clipboard.getData('text/plain');
                                        if (data?.text != null) {
                                          setState(() {
                                            _jdController.text = data!.text!;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Preview area
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE9D5FF),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickedFile == null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF3E8FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 40,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No Resume Loaded Yet',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF2E1065),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select a PDF or scan via camera to evaluate',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF6B7280),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                Positioned.fill(
                                  child: _sourceType == 'pdf'
                                      ? PDFView(filePath: _pickedFile!.path)
                                      : Image.file(
                                          _pickedFile!,
                                          fit: BoxFit.contain,
                                        ),
                                ),
                                if (_isScanning)
                                  Positioned.fill(
                                    child: ScanningAnimation(
                                      duration: const Duration(seconds: 3),
                                      beamHeight: 30.0,
                                      beamColor: const Color(0xFFC084FC),
                                      dimBackground: true,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Start button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: (_pickedFile != null && !_isScanning && !_isAnalyzing)
                            ? const LinearGradient(
                                colors: [Color(0xFF9333EA), Color(0xFF7C3AED), Color(0xFF6D28D9)],
                              )
                            : null,
                        color: (_pickedFile == null || _isScanning || _isAnalyzing)
                            ? const Color(0xFFDDD6FE)
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: (_pickedFile != null && !_isScanning && !_isAnalyzing)
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed: (_pickedFile != null &&
                                !_isScanning &&
                                !_isAnalyzing)
                            ? _startScanThenAnalyze
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white70,
                          disabledBackgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _isScanning
                              ? 'Scanning…'
                              : _isAnalyzing
                                  ? 'Analyzing Sections…'
                                  : 'Start ATS Analysis',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ATS Multi-Stage Section Scanner Overlay
            if (_isAnalyzing)
              Positioned.fill(
                child: AtsSectionScanner(
                  onCancel: () {
                    setState(() {
                      _cancelRequested = true;
                      _isAnalyzing = false;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}