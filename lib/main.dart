import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:notification_test/red_page.dart';
import 'package:notification_test/services/local_notification_service.dart';

import 'green_page.dart';

/// Receive message when app is background solution for on message
Future<void> backgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print('Handling a background message ${message.messageId}');

  try {
    await Firebase.initializeApp();
    LocalNotificationService.initialize();

    await LocalNotificationService.display(message);
  } catch (e) {
    print(e);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (Platform.isAndroid) {
    FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        "red": (_) => const RedPage(),
        "green": (_) => const GreenPage(),
      },
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    LocalNotificationService.initialize();
    LocalNotificationService.requestPermissions();

    // FirebaseMessaging.instance.requestPermission().then((value) {
    //   print(value);
    // });

    FirebaseMessaging.instance.getToken().then((token) {
      print('token : $token');
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print('getInitialMessage : $message');
      if (message != null) {
        final routeFromMessage = message.data['route'];
        Navigator.of(context).pushNamed(routeFromMessage);
      }
    });

    //  if (!kIsWeb) {
    //   await FirebaseMessaging.instance
    //       .setForegroundNotificationPresentationOptions(
    //     alert: true,
    //     badge: true,
    //     sound: true,
    //   );
    // }

    /// only foreground work
    FirebaseMessaging.onMessage.listen((message) {
      print('onMessage : $message');
      if (message.notification != null) {
        print(message.notification!.body);
        print(message.notification!.title);
        print('data : ${message.data['bigPicture']}');
      }
      LocalNotificationService.display(message);
    });

    ///when the app is in background but opened and user taps
    ///on the notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('onMessageOpenedApp : $message');
      final routeFromMessage = message.data['route'];
      if (routeFromMessage != null) {
        Navigator.of(context).pushNamed(routeFromMessage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Notification Test',
              style: TextStyle(fontSize: 30),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseMessaging.instance.subscribeToTopic('myTopic');
              },
              child: Text('Subscribe To Topic'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseMessaging.instance
                    .unsubscribeFromTopic('myTopic');
              },
              child: Text('un Subscribe To Topic'),
            ),
          ],
        ),
      ),
    );
  }
}
