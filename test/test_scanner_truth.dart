import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sem7_project/services/quality_scanner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PROMPT 1 Acceptance Tests - AI Quality Scanner Truth Verification', () {
    test('1. Blank image must be rejected as Non-Produce, never Grade A', () async {
      final cert = await QualityScannerService.analyzeProduce(
        cropName: 'Tomato',
        imagePath: 'test/test_images/blank_white.png',
      );
      print('TEST 1 Blank Image Result:');
      print('  isProduce: ${cert.isProduce}');
      print('  detectedCrop: ${cert.detectedCrop}');
      print('  grade: ${cert.grade}');
      print('  defectPercentage: ${cert.defectPercentage}%');

      expect(cert.isProduce, isFalse);
      expect(cert.grade.contains('Reject'), isTrue);
      expect(cert.grade.contains('Grade A'), isFalse);
    });

    test('2. Shoe / non-produce must be rejected as Non-Produce, never Grade A', () async {
      final cert = await QualityScannerService.analyzeProduce(
        cropName: 'Tomato',
        imagePath: 'test/test_images/shoe_non_produce.png',
      );
      print('TEST 2 Leather Shoe Result:');
      print('  isProduce: ${cert.isProduce}');
      print('  detectedCrop: ${cert.detectedCrop}');
      print('  grade: ${cert.grade}');
      print('  defectPercentage: ${cert.defectPercentage}%');

      expect(cert.isProduce, isFalse);
      expect(cert.grade.contains('Reject'), isTrue);
      expect(cert.grade.contains('Grade A'), isFalse);
    });

    test('3. Fresh Tomato must achieve Grade A', () async {
      final cert = await QualityScannerService.analyzeProduce(
        cropName: 'Tomato',
        imagePath: 'test/test_images/fresh_tomato.png',
      );
      print('TEST 3 Fresh Tomato Result:');
      print('  isProduce: ${cert.isProduce}');
      print('  detectedCrop: ${cert.detectedCrop}');
      print('  selectedCropMatches: ${cert.selectedCropMatches}');
      print('  grade: ${cert.grade}');
      print('  defectPercentage: ${cert.defectPercentage}%');

      expect(cert.isProduce, isTrue);
      expect(cert.selectedCropMatches, isTrue);
      expect(cert.grade.contains('Grade A'), isTrue);
      expect(cert.defectPercentage, lessThanOrEqualTo(2.5));
    });

    test('4. Rotten Tomato must be Reject / Substandard, NEVER Grade A', () async {
      final cert = await QualityScannerService.analyzeProduce(
        cropName: 'Tomato',
        imagePath: 'test/test_images/rotten_tomato.png',
      );
      print('TEST 4 Rotten Tomato Result:');
      print('  isProduce: ${cert.isProduce}');
      print('  detectedCrop: ${cert.detectedCrop}');
      print('  condition: ${cert.condition}');
      print('  grade: ${cert.grade}');
      print('  defectPercentage: ${cert.defectPercentage}%');

      expect(cert.isProduce, isTrue);
      expect(cert.grade.contains('Reject'), isTrue);
      expect(cert.grade.contains('Grade A'), isFalse);
      expect(cert.defectPercentage, greaterThanOrEqualTo(15.0));
    });

    test('5. Onion image with "Tomato" target must flag Crop Mismatch and block grading', () async {
      final cert = await QualityScannerService.analyzeProduce(
        cropName: 'Tomato',
        imagePath: 'test/test_images/fresh_onion.png',
      );
      print('TEST 5 Onion vs Tomato Mismatch Result:');
      print('  isProduce: ${cert.isProduce}');
      print('  target: ${cert.cropName}');
      print('  detectedCrop: ${cert.detectedCrop}');
      print('  selectedCropMatches: ${cert.selectedCropMatches}');
      print('  grade: ${cert.grade}');

      expect(cert.isProduce, isTrue);
      expect(cert.selectedCropMatches, isFalse);
      expect(cert.detectedCrop, contains('Onion'));
      expect(cert.grade, contains('Crop Mismatch'));
    });
  });
}
