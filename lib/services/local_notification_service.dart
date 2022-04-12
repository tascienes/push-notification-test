import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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

    String? token = await FirebaseMessaging.instance.getToken();
    print('Token : : : ' + token.toString());
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
      var directory = await getTemporaryDirectory();
      var filePath = '${directory.path}/$fileName';
      var file = File(filePath);
      Response<List<int>> response = await Dio()
          .get<List<int>>(url,
              options: Options(responseType: ResponseType.bytes))
          .catchError((onError) {
        print(onError);
      });

      if (response.statusCode == HttpStatus.ok) {
        if (response.data != null) await file.writeAsBytes(response.data!);
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
