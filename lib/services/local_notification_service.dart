import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize(/* BuildContext context */) async {
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: IOSInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
      ),
    );

    _notificationPlugin.initialize(
      initializationSettings,
      onSelectNotification: (route) async {
        if (route != null) {
          // Navigator.of(context).pushNamed(route);
          print('NAVIGATING @@@@ ::: $route');
        }
      },
    );
  }

  static void requestPermissions() {
    _notificationPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<void> display(RemoteMessage message) async {
    try {
      List<IOSNotificationAttachment> iosAttachment = [];
      String? bigPicturePath;
      var bigPicture = message.data['bigPicture'];
      if (bigPicture != null && bigPicture.isNotEmpty) {
        String bigPictureName = Uuid().v4();
        bigPicturePath =
            await _downloadAndSaveFile(bigPicture, '$bigPictureName.jpg');
      }
      iosAttachment.add(IOSNotificationAttachment(bigPicturePath!));

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigPictureStyleInformation(
            FilePathAndroidBitmap(bigPicturePath),
            contentTitle: message.notification?.title,
            summaryText: message.notification?.body,
            htmlFormatTitle: true,
            htmlFormatContent: true,
            htmlFormatContentTitle: true,
            htmlFormatSummaryText: true,
          ),
        ),
        iOS: IOSNotificationDetails(
          presentAlert: true,
          presentSound: true,
          attachments: iosAttachment,
        ),
      );
      _notificationPlugin.show(
        id,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
        payload: message.data['route'],
      );
    } catch (e) {
      print('Error : : : $e');
    }
  }

  static Future<String?> _downloadAndSaveFile(
      String url, String? fileName) async {
    try {
      final Directory directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/$fileName';
      final File file = File(filePath);
      final http.Response response =
          await http.get(Uri.parse(url)).catchError((onError) {
        print(onError);
      });
      if (response.statusCode == HttpStatus.ok) {
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }
      print("File path : $filePath");
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
