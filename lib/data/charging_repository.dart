import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChargingRepository {
  static Future<List<Map<String, dynamic>>> fetchChargingStations() async {
    try {
      // Retrieve API key from environment variables
      final apiKey = dotenv.env['OPEN_CHARGE_MAP_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception(
          'OPEN_CHARGE_MAP_API_KEY non configurata nel file .env',
        );
      }

      final url = Uri.parse(
        'https://api.openchargemap.io/v3/poi/'
        '?output=json'
        '&countrycode=IT'
        '&maxresults=5000'
        '&operatorid=80', // Enel X operator ID
      );

      final response = await http.get(
        url,
        headers: {
          'X-API-Key': apiKey,
          'Accept': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://openchargemap.org/',
          'Origin': 'https://openchargemap.org',
        },
      );

      debugPrint("OCM status: ${response.statusCode}");

      if (response.statusCode != 200) {
        debugPrint("OCM body: ${response.body}");
        throw Exception('Errore OCM: codice ${response.statusCode}');
      }

      final List<dynamic> decoded = jsonDecode(response.body) as List<dynamic>;

      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint("Errore fetch ChargingStations (OCM): $e");
      rethrow;
    }
  }
}
