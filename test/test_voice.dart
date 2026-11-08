import '../lib/services/kisan_voice_service.dart';

void main() {
  final cases = [
    'Add 50 kg tomato at 30 rupees per kg from Udumalpet',
    'ஐம்பது கிலோ தக்காளி பொள்ளாச்சி 35 ரூபாய்',
    'पचास किलो टमाटर पोलाची तीस रुपये',
    '1200 kg Onion Nashik at 24 rupees',
    'நூறு கிலோ உருளைக்கிழங்கு',
    'open orders',
    'சந்தையை திற'
  ];

  print('=== EVALUATING KISANVOICE SERVICE INPUT-DRIVEN RESULTS ===\n');
  for (final c in cases) {
    final res = KisanVoiceService.parseVoiceListing(c);
    print('INPUT: $c');
    print('  Lang: ${res.language}');
    print('  Crop: ${res.crop ?? "NULL"}');
    print('  Qty: ${res.quantityKg ?? "NULL"} kg');
    print('  Price: ₹${res.price ?? "NULL"}');
    print('  Location: ${res.location ?? "NULL"}');
    print('  Command: ${res.command ?? "NONE"}');
    if (res.missingFields.isNotEmpty) {
      print('  Missing: ${res.missingFields.join(", ")}');
      print('  Follow-up: ${res.followUpQuestion}');
    }
    print('-----------------------------------------');
  }
}
