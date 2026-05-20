import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:umira/features/intervention/views/ocr_scan_view.dart';
import 'package:umira/features/intervention/data/intervention_repository.dart';
import 'package:umira/core/network/api_client.dart';
import 'package:umira/core/storage/secure_storage.dart';

// ── Mock infrastructure ────────────────────────────────────────

class _MockSecureStorage extends SecureStorage {
  @override
  Future<String?> readToken() async => null;
  @override
  Future<void> writeToken(String token) async {}
  @override
  Future<void> deleteToken() async {}
}

class _MockApiClient extends ApiClient {
  _MockApiClient() : super(_MockSecureStorage(), baseUrl: 'http://test');
}

/// Repository whose `performOcr` returns a value you control via a `Completer`.
class _ControllableInterventionRepository extends InterventionRepository {
  Completer<String>? _completer;

  _ControllableInterventionRepository() : super(_MockApiClient());

  void complete(String result) => _completer?.complete(result);
  void completeError(Object error) => _completer?.completeError(error);

  @override
  Future<String> performOcr(String imagePath) {
    _completer = Completer<String>();
    return _completer!.future;
  }
}

/// Repository whose `performOcr` returns immediately (no Completer needed).
class _ImmediateInterventionRepository extends InterventionRepository {
  final String result;
  _ImmediateInterventionRepository(this.result) : super(_MockApiClient());

  @override
  Future<String> performOcr(String imagePath) async => result;
}

class _MockImagePicker extends ImagePicker {
  final XFile? xFile;
  _MockImagePicker(this.xFile);

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return xFile;
  }
}

// ── Temp image helper ──────────────────────────────────────────

late File _tempImage;

/// Creates a minimal valid 1×1 red PNG file for widget tests.
Future<File> _createTempImage() async {
  final pngBytes = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
    0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
    0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
    0x00, 0x00, 0x03, 0x00, 0x01, 0x37, 0x8B, 0x39,
    0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
    0xAE, 0x42, 0x60, 0x82,
  ];
  final dir = await Directory.systemTemp.createTemp('ocr_test_');
  final file = File('${dir.path}/test_image.png');
  await file.writeAsBytes(pngBytes);
  return file;
}

// ── Test helpers ───────────────────────────────────────────────

Widget _createTestApp({
  InterventionRepository? repo,
  ImagePicker? imagePicker,
}) {
  return ProviderScope(
    overrides: [
      interventionRepoProvider.overrideWithValue(
        repo ?? _ControllableInterventionRepository(),
      ),
    ],
    child: MaterialApp(
      home: OcrScanView(imagePicker: imagePicker),
    ),
  );
}

Future<void> _selectImage(WidgetTester tester, ImagePicker mockPicker) async {
  await tester.tap(find.text('Tap to select an image'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Camera'));
  await tester.pumpAndSettle();
}

Future<void> _tapScan(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
}

// ── Tests ──────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    _tempImage = await _createTempImage();
  });

  tearDown(() {
    _tempImage.parent.deleteSync(recursive: true);
  });

  group('initial empty state', () {
    testWidgets('renders title and description', (tester) async {
      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Text Scanner'), findsOneWidget);
      expect(find.text('Scan text from images or your camera'), findsOneWidget);
    });

    testWidgets('shows empty state prompt with icon', (tester) async {
      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Tap to select an image'), findsOneWidget);
      expect(find.text('Take a photo or pick from gallery'), findsOneWidget);
      expect(find.byIcon(Icons.text_snippet_outlined), findsOneWidget);
    });

    testWidgets('shows app bar with back button', (tester) async {
      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('does not show scan action or results initially',
        (tester) async {
      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Tap to select an image'), findsOneWidget);
      expect(find.text('Scan Again'), findsNothing);
      expect(find.text('Copy Text'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });
  });

  group('source picker bottom sheet', () {
    testWidgets('opens on tap of empty state card', (tester) async {
      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap to select an image'));
      await tester.pumpAndSettle();

      expect(find.text('Select Image Source'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('can be dismissed by tapping scrim', (tester) async {
      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap to select an image'));
      await tester.pumpAndSettle();
      expect(find.text('Select Image Source'), findsOneWidget);

      await tester.tapAt(const Offset(0, 0));
      await tester.pumpAndSettle();

      expect(find.text('Select Image Source'), findsNothing);
    });
  });

  group('image selection and scanning', () {
    testWidgets('selecting an image shows preview and scan button',
        (tester) async {
      final mockPicker = _MockImagePicker(XFile(_tempImage.path));
      await tester.pumpWidget(_createTestApp(imagePicker: mockPicker));
      await tester.pumpAndSettle();

      await _selectImage(tester, mockPicker);

      expect(find.text('Choose another'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.byIcon(Icons.document_scanner), findsOneWidget);
    });

    testWidgets('shows scanning state while text is being extracted',
        (tester) async {
      final repo = _ControllableInterventionRepository();
      final mockPicker = _MockImagePicker(XFile(_tempImage.path));
      await tester.pumpWidget(
        _createTestApp(repo: repo, imagePicker: mockPicker),
      );
      await tester.pumpAndSettle();

      await _selectImage(tester, mockPicker);
      await _tapScan(tester);
      await tester.pump();

      // Loading UI while Completer is pending
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Extracting text from image...'), findsOneWidget);
      expect(find.text('Scanning...'), findsOneWidget);
      expect(find.text('Clear'), findsNothing);

      // Resolve and check result
      repo.complete('Result after delay');
      await tester.pump();
      await tester.pump();

      expect(find.text('Result after delay'), findsOneWidget);
    });

    testWidgets('displays extracted text and result actions after scan',
        (tester) async {
      final repo = _ImmediateInterventionRepository('Extracted text from test');
      final mockPicker = _MockImagePicker(XFile(_tempImage.path));
      await tester.pumpWidget(
        _createTestApp(repo: repo, imagePicker: mockPicker),
      );
      await tester.pumpAndSettle();

      await _selectImage(tester, mockPicker);
      await _tapScan(tester);
      await tester.pump();
      await tester.pump();

      // Result UI
      expect(find.text('Text extracted successfully'), findsOneWidget);
      expect(find.text('Extracted text from test'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Scan Again'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);
    });

    testWidgets('tapping Scan Again resets back to empty state',
        (tester) async {
      final repo = _ImmediateInterventionRepository('Some text');
      final mockPicker = _MockImagePicker(XFile(_tempImage.path));
      await tester.pumpWidget(
        _createTestApp(repo: repo, imagePicker: mockPicker),
      );
      await tester.pumpAndSettle();

      await _selectImage(tester, mockPicker);
      await _tapScan(tester);
      await tester.pump();
      await tester.pump();

      expect(find.text('Scan Again'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);

      // Ensure visible and tap Scan Again
      await tester.ensureVisible(find.text('Scan Again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scan Again'));
      await tester.pump();
      await tester.pump();

      // Back to empty state
      expect(find.text('Tap to select an image'), findsOneWidget);
      expect(find.text('Scan Again'), findsNothing);
      expect(find.text('Copy Text'), findsNothing);
    });
  });

  group('error handling', () {
    testWidgets('shows error message when OCR service fails', (tester) async {
      final repo = _ControllableInterventionRepository();
      final mockPicker = _MockImagePicker(XFile(_tempImage.path));
      await tester.pumpWidget(
        _createTestApp(repo: repo, imagePicker: mockPicker),
      );
      await tester.pumpAndSettle();

      await _selectImage(tester, mockPicker);
      await _tapScan(tester);
      repo.completeError(Exception('Simulated OCR failure'));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Simulated OCR failure'), findsOneWidget);
    });
  });
}
