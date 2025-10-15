import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/hig_screen.dart';

final FlutterLocalNotificationsPlugin localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Mensagem recebida em segundo plano: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await localNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localiza Agendamentos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
  '/': (context) => const LoginScreen(),
  '/home': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return HomeScreen(
      nomeVendedor: args['nome'],
      deviceToken: args['deviceToken'],
    );
  },
  '/hig_screen': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return HigScreen( // ✅ aqui deve ser HigScreen, não HomeScreen
      nome: args['nome'],
      deviceToken: args['deviceToken'],
    );
  },
},

    );
  }
}
