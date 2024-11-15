import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectapp/screen/home.dart';
import 'package:projectapp/screen/login.dart';

// Top-level function สำหรับ background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background messages here
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static NotificationService? _instance;
  NotificationService._();
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Configure local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'pickup_channel',
            'Pickup Notifications',
            description: 'Notifications for pickup reminders',
            importance: Importance.high,
          ),
        );

    // Listen to Firebase messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen to auth state changes to update token
    _auth.authStateChanges().listen((User? user) {
      if (user != null && user.emailVerified) {
        _updateFCMToken();
      }
    });
  }

  Future<void> _updateFCMToken() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.emailVerified) {
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _firestore.collection('users').doc(currentUser.uid).update({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
          print('FCM Token updated successfully');
        }
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'pickup_channel',
            'Pickup Notifications',
            channelDescription: 'Notifications for pickup reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['pickupId'],
      );
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Notification clicked in background: ${message.messageId}');
    if (message.data['pickupId'] != null) {
      // TODO: Implement navigation to pickup details
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      // TODO: Implement navigation to pickup details
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.anuphanTextTheme(),
      ),
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          User? user = snapshot.data;
          if (user != null && user.emailVerified) {
            return HomeScreen();
          } else {
            return LoginScreen();
          }
        }

        return LoginScreen();
      },
    );
  }
}
