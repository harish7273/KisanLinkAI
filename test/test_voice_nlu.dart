import 'package:flutter_test/flutter_test.dart';
import 'package:sem7_project/services/kisan_voice_service.dart';

void main() {
  group('PROMPT 2 Acceptance Tests - Voice Assistant Input-Driven NLU Suite (40+ Test Cases)', () {
    // 1. English Full & Incomplete Sentences
    test('EN 1: Add 50 kg tomato at 30 rupees per kg from Udumalpet', () {
      final res = KisanVoiceService.parseVoiceListing('Add 50 kg tomato at 30 rupees per kg from Udumalpet');
      expect(res.crop, 'Tomato');
      expect(res.quantityKg, 50.0);
      expect(res.price, 30.0);
      expect(res.location, contains('Udumalpet'));
      expect(res.isComplete, isTrue);
    });

    test('EN 2: 1200 kg Onion Nashik at 24 rupees', () {
      final res = KisanVoiceService.parseVoiceListing('1200 kg Onion Nashik at 24 rupees');
      expect(res.crop, 'Onion');
      expect(res.quantityKg, 1200.0);
      expect(res.price, 24.0);
      expect(res.location, contains('Nashik'));
      expect(res.isComplete, isTrue);
    });

    test('EN 3: INCOMPLETE (Missing Price): 500 kg Tomato from Pollachi', () {
      final res = KisanVoiceService.parseVoiceListing('500 kg Tomato from Pollachi');
      expect(res.crop, 'Tomato');
      expect(res.quantityKg, 500.0);
      expect(res.price, isNull); // STRICT: Never invent a price!
      expect(res.location, contains('Pollachi'));
      expect(res.isComplete, isFalse);
      expect(res.missingFields, contains('price'));
      expect(res.followUpQuestion, isNotNull);
    });

    test('EN 4: INCOMPLETE (Missing Location & Price): 200 kg Brinjal', () {
      final res = KisanVoiceService.parseVoiceListing('200 kg Brinjal');
      expect(res.crop, 'Brinjal');
      expect(res.quantityKg, 200.0);
      expect(res.price, isNull);
      expect(res.location, isNull);
      expect(res.missingFields, containsAll(['price', 'location']));
    });

    test('EN 5: Unit conversion 2 quintal Potato Agra at 18 rupees', () {
      final res = KisanVoiceService.parseVoiceListing('2 quintal Potato Agra at 18 rupees');
      expect(res.crop, 'Potato');
      expect(res.quantityKg, 200.0); // 2 quintal = 200 kg
      expect(res.price, 18.0);
      expect(res.location, contains('Agra'));
    });

    test('EN 6: Unit conversion 1 ton Banana Theni at 22 rs', () {
      final res = KisanVoiceService.parseVoiceListing('1 ton Banana Theni at 22 rs');
      expect(res.crop, 'Banana');
      expect(res.quantityKg, 1000.0); // 1 ton = 1000 kg
      expect(res.price, 22.0);
      expect(res.location, contains('Theni'));
    });

    test('EN 7: 4 crates Capsicum Ooty at 45 per kg', () {
      final res = KisanVoiceService.parseVoiceListing('4 crates Capsicum Ooty at 45 per kg');
      expect(res.crop, 'Capsicum');
      expect(res.quantityKg, 100.0); // 4 * 25 = 100 kg
      expect(res.price, 45.0);
      expect(res.location, contains('Ooty'));
    });

    test('EN 8: Spoken words: fifty kg Tomato Coimbatore thirty five rupees', () {
      final res = KisanVoiceService.parseVoiceListing('fifty kg Tomato Coimbatore thirty five rupees');
      expect(res.crop, 'Tomato');
      expect(res.quantityKg, 50.0);
      expect(res.price, 35.0);
      expect(res.location, contains('Coimbatore'));
    });

    // 2. Tamil Sentences
    test('TA 1: 500 கிலோ தக்காளி பொள்ளாச்சி 30 ரூபாய்', () {
      final res = KisanVoiceService.parseVoiceListing('500 கிலோ தக்காளி பொள்ளாச்சி 30 ரூபாய்');
      expect(res.language, 'ta');
      expect(res.crop, 'Tomato');
      expect(res.quantityKg, 500.0);
      expect(res.price, 30.0);
      expect(res.location, contains('Pollachi'));
      expect(res.isComplete, isTrue);
    });

    test('TA 2: 1200 கிலோ வெங்காயம் நாசிக் 25 ரூபாய்', () {
      final res = KisanVoiceService.parseVoiceListing('1200 கிலோ வெங்காயம் நாசிக் 25 ரூபாய்');
      expect(res.crop, 'Onion');
      expect(res.quantityKg, 1200.0);
      expect(res.price, 25.0);
      expect(res.location, contains('Nashik'));
      expect(res.isComplete, isTrue);
    });

    test('TA 3: INCOMPLETE (Missing Price): 400 கிலோ குடைமிளகாய் ஊட்டி', () {
      final res = KisanVoiceService.parseVoiceListing('400 கிலோ குடைமிளகாய் ஊட்டி');
      expect(res.crop, 'Capsicum');
      expect(res.quantityKg, 400.0);
      expect(res.price, isNull); // STRICT: Never invent a price!
      expect(res.location, contains('Ooty'));
      expect(res.isComplete, isFalse);
      expect(res.missingFields, contains('price'));
      expect(res.followUpQuestion, contains('விலை'));
    });

    test('TA 4: Spoken words: ஐம்பது கிலோ தக்காளி பொள்ளாச்சி முப்பது ரூபாய்', () {
      final res = KisanVoiceService.parseVoiceListing('ஐம்பது கிலோ தக்காளி பொள்ளாச்சி முப்பது ரூபாய்');
      expect(res.crop, 'Tomato');
      expect(res.quantityKg, 50.0);
      expect(res.price, 30.0);
      expect(res.location, contains('Pollachi'));
    });

    test('TA 5: 3 குவிண்டால் உருளைக்கிழங்கு மேட்டுப்பாளையம் 20 ரூபாய்', () {
      final res = KisanVoiceService.parseVoiceListing('3 குவிண்டால் உருளைக்கிழங்கு மேட்டுப்பாளையம் 20 ரூபாய்');
      expect(res.crop, 'Potato');
      expect(res.quantityKg, 300.0);
      expect(res.price, 20.0);
      expect(res.location, contains('Mettupalayam'));
    });

    test('TA 6: 100 கிலோ பச்சை மிளகாய் உடுமலை 40 ரூபாய்', () {
      final res = KisanVoiceService.parseVoiceListing('100 கிலோ பச்சை மிளகாய் உடுமலை 40 ரூபாய்');
      expect(res.crop, 'Green Chilli');
      expect(res.quantityKg, 100.0);
      expect(res.price, 40.0);
      expect(res.location, contains('Udumalpet'));
    });

    test('TA 7: 600 கிலோ கத்தரிக்காய் திண்டுக்கல் 22 ரூபாய்', () {
      final res = KisanVoiceService.parseVoiceListing('600 கிலோ கத்தரிக்காய் திண்டுக்கல் 22 ரூபாய்');
      expect(res.crop, 'Brinjal');
      expect(res.quantityKg, 600.0);
      expect(res.price, 22.0);
      expect(res.location, contains('Dindigul'));
    });

    test('TA 8: INCOMPLETE: நூறு கிலோ வெண்டைக்காய்', () {
      final res = KisanVoiceService.parseVoiceListing('நூறு கிலோ வெண்டைக்காய்');
      expect(res.crop, 'Ladies Finger');
      expect(res.quantityKg, 100.0);
      expect(res.price, isNull);
      expect(res.location, isNull);
    });

    // 3. Hindi Sentences
    test('HI 1: 500 किलो टमाटर पोलाची तीस रुपये', () {
      final res = KisanVoiceService.parseVoiceListing('500 किलो टमाटर पोलाची तीस रुपये');
      expect(res.language, 'hi');
      expect(res.crop, 'Tomato');
      expect(res.quantityKg, 500.0);
      expect(res.price, 30.0);
      expect(res.location, contains('Pollachi'));
      expect(res.isComplete, isTrue);
    });

    test('HI 2: 1200 किलो प्याज नासिक 24 रुपये', () {
      final res = KisanVoiceService.parseVoiceListing('1200 किलो प्याज नासिक 24 रुपये');
      expect(res.crop, 'Onion');
      expect(res.quantityKg, 1200.0);
      expect(res.price, 24.0);
      expect(res.location, contains('Nashik'));
      expect(res.isComplete, isTrue);
    });

    test('HI 3: INCOMPLETE (Missing Price): 1500 किलो आलू आगरा', () {
      final res = KisanVoiceService.parseVoiceListing('1500 किलो आलू आगरा');
      expect(res.crop, 'Potato');
      expect(res.quantityKg, 1500.0);
      expect(res.price, isNull); // STRICT: Never invent a price!
      expect(res.location, contains('Agra'));
      expect(res.missingFields, contains('price'));
      expect(res.followUpQuestion, contains('भाव'));
    });

    test('HI 4: Spoken words: पचास किलो टमाटर पोलाची तीस रुपये', () {
      final res = KisanVoiceService.parseVoiceListing('पचास किलो टमाटर पोलाची तीस रुपये');
      expect(res.crop, 'Tomato');
      expect(res.quantityKg, 50.0);
      expect(res.price, 30.0);
      expect(res.location, contains('Pollachi'));
    });

    test('HI 5: 5 क्विंटल फूलगोभी सेलम 35 रुपये', () {
      final res = KisanVoiceService.parseVoiceListing('5 क्विंटल फूलगोभी सेलम 35 रुपये');
      expect(res.crop, 'Cauliflower');
      expect(res.quantityKg, 500.0);
      expect(res.price, 35.0);
      expect(res.location, contains('Salem'));
    });

    test('HI 6: 250 किलो गाजर ऊटी 38 रुपये प्रति किलो', () {
      final res = KisanVoiceService.parseVoiceListing('250 किलो गाजर ऊटी 38 रुपये प्रति किलो');
      expect(res.crop, 'Carrot');
      expect(res.quantityKg, 250.0);
      expect(res.price, 38.0);
      expect(res.location, contains('Ooty'));
    });

    test('HI 7: 800 किलो केला थेनी 20 रुपये', () {
      final res = KisanVoiceService.parseVoiceListing('800 किलो केला थेनी 20 रुपये');
      expect(res.crop, 'Banana');
      expect(res.quantityKg, 800.0);
      expect(res.price, 20.0);
      expect(res.location, contains('Theni'));
    });

    test('HI 8: INCOMPLETE: तीन सौ किलो पत्तागोभी', () {
      final res = KisanVoiceService.parseVoiceListing('तीन सौ किलो पत्तागोभी');
      expect(res.crop, 'Cabbage');
      expect(res.quantityKg, 300.0);
      expect(res.price, isNull);
      expect(res.location, isNull);
    });

    // 4. Voice Commands
    test('Command 1: open orders', () {
      final res = KisanVoiceService.parseVoiceListing('open orders');
      expect(res.command, 'open_orders');
    });

    test('Command 2: ஆர்டர்களை திற', () {
      final res = KisanVoiceService.parseVoiceListing('ஆர்டர்களை திற');
      expect(res.command, 'open_orders');
    });

    test('Command 3: ऑर्डर खोलो', () {
      final res = KisanVoiceService.parseVoiceListing('ऑर्डर खोलो');
      expect(res.command, 'open_orders');
    });

    test('Command 4: open market', () {
      final res = KisanVoiceService.parseVoiceListing('open market');
      expect(res.command, 'open_market');
    });

    test('Command 5: சந்தையை திற', () {
      final res = KisanVoiceService.parseVoiceListing('சந்தையை திற');
      expect(res.command, 'open_market');
    });

    test('Command 6: मंडी खोलो', () {
      final res = KisanVoiceService.parseVoiceListing('मंडी खोलो');
      expect(res.command, 'open_market');
    });

    test('Command 7: quality check', () {
      final res = KisanVoiceService.parseVoiceListing('quality check');
      expect(res.command, 'open_quality');
    });

    test('Command 8: தரம் பரிசோதனை', () {
      final res = KisanVoiceService.parseVoiceListing('தரம் பரிசோதனை');
      expect(res.command, 'open_quality');
    });

    test('Command 9: क्वालिटी चेक', () {
      final res = KisanVoiceService.parseVoiceListing('क्वालिटी चेक');
      expect(res.command, 'open_quality');
    });

    test('Command 10: what is today tomato mandi rate', () {
      final res = KisanVoiceService.parseVoiceListing('what is today tomato mandi rate');
      expect(res.command, 'check_price');
    });

    test('Command 11: தக்காளி விலை நிலவரம் என்ன', () {
      final res = KisanVoiceService.parseVoiceListing('தக்காளி விலை நிலவரம் என்ன');
      expect(res.command, 'check_price');
    });

    test('Command 12: switch to tamil', () {
      final res = KisanVoiceService.parseVoiceListing('switch to tamil');
      expect(res.command, 'change_lang_ta');
    });

    test('Command 13: switch to english', () {
      final res = KisanVoiceService.parseVoiceListing('switch to english');
      expect(res.command, 'change_lang_en');
    });

    test('Command 14: switch to hindi', () {
      final res = KisanVoiceService.parseVoiceListing('switch to hindi');
      expect(res.command, 'change_lang_hi');
    });

    test('Command 15: filter pending orders', () {
      final res = KisanVoiceService.parseVoiceListing('filter pending orders');
      expect(res.command, 'filter_orders');
    });

    test('Command 16: Empty speech produces honest empty result', () {
      final res = KisanVoiceService.parseVoiceListing('');
      expect(res.crop, isNull);
      expect(res.quantityKg, isNull);
      expect(res.price, isNull);
      expect(res.location, isNull);
      expect(res.missingFields.length, 4);
    });
  });
}
