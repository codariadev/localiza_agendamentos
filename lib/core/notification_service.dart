import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  // Notificação local
  static Future<void> show(String titulo, String corpo) async {
    const androidDetails = AndroidNotificationDetails(
      'agendamento_channel',
      'Agendamentos',
      channelDescription: 'Notificações de agendamentos',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(0, titulo, corpo, details);
  }

  // Notificação remota via FCM
  static const String serverKey = 'c2d76123d244a591f77c76e8ae71102d2f8ab4cf';

  static Future<void> sendToDevice(
      String deviceToken, String title, String body) async {
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    final payload = jsonEncode({
      'to': deviceToken,
      'notification': {
        'title': title,
        'body': body,
        'sound': 'default',
      },
      'priority': 'high',
    });

    final response = await http.post(url, headers: headers, body: payload);

    if (response.statusCode == 200) {
      print('Notificação enviada com sucesso!');
    } else {
      print('Erro ao enviar notificação: ${response.body}');
    }
  }
}
