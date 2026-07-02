import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rafiq/core/utils/secure_storage.dart';

class NotificationService {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  final Dio dio = Dio(); 


  Future<void> initNotifications() async {

const AndroidInitializationSettings initializationSettingsAndroid =
AndroidInitializationSettings('@drawable/splash');

const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

await _localNotificationsPlugin.initialize(initializationSettings);
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      developer.log("================== FCM TOKEN ==================", name: "RAFIQ_DEBUG");
      developer.log(token ?? "التوكن طالع بـ Null!", name: "RAFIQ_TOKEN");
      developer.log("===============================================", name: "RAFIQ_DEBUG");
      
      if (token != null) {
        print("🔑 [FCM Token]: $token");

        await saveTokenToFirestore(token);

        await sendTokenToBackend(token);
      }
    }

    messaging.onTokenRefresh.listen((newToken) async {
      print("🔄 FCM Token refreshed: $newToken");
      await saveTokenToFirestore(newToken);
      await sendTokenToBackend(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 [FCM] وصل إشعار جديد حالا!");
      showLocalNotification(message);
      if (message.notification != null) {
        print("📌 العنوان (Title): ${message.notification!.title}");
        print("📝 النص (Body): ${message.notification!.body}");
      }
      
      if (message.data.isNotEmpty) {
        print("📦 الداتا الإضافية المرفقة (Payload): ${message.data}");
      }
    });
  }





  Future<void> saveTokenToFirestore(String token) async {
    try {
      await firestore.collection('user_tokens').doc(token).set({
        'fcm_token': token,
        'last_updated': FieldValue.serverTimestamp(),
      });
      print("🎉 تم حفظ التوكن ديناميكياً في الفايربيز!");
    } catch (e) {
      print("❌ خطأ أثناء حفظ التوكن في الفايربيز: $e");
    }
  }





  //   Future<void> sendTokenToBackend(String token) async {
  //   try {
  //     final response = await dio.post(
  //       'https://ribatbackend-production.up.railway.app/register-token',
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //         },
  //       ),
  //       data: {
  //         'user_id': currentUserId,
  //         'fcm_token': token,
  //       },
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       print("🚀 [Dio] تم إرسال التوكن بنجاح للباك إند الـ Railway!");
  //     } else {
  //       print("⚠️ [Dio] الباك إند رجع ستايتس كود غريب: ${response.statusCode}");
  //     }
  //   } on DioException catch (e) {
  //     print("❌ [Dio Exception] فشل إرسال التوكن: ${e.message}");
  //     if (e.response != null) {
  //       print("💬 داتا الخطأ من السيرفر: ${e.response?.data}");
  //     }
  //   } catch (e) {
  //     print("❌ خطأ غير متوقع: $e");
  //   }
  // }


  Future<void> sendTokenToBackend(String token) async {
    try {
      final jwtToken = await SecureStorage.getToken();
      if (jwtToken == null) {
        print("⚠️ [FCM] No JWT token found in storage. Postponing token registration.");
        return;
      }


      final String? currentUserId = await SecureStorage.getUserId();
    if (currentUserId == null) {
      print("⚠️ [FCM] No User ID found. Cannot register token.");
      return;
    }

      final response = await dio.post(
        'https://ribatbackend-production.up.railway.app/register-token',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'user_id': currentUserId,
          'fcm_token': token,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("🚀 [Dio] FCM Token registered successfully on local backend!");
      } else {
        print("⚠️ [Dio] Local backend returned status code: ${response.statusCode}");
      }
    } on DioException catch (e) {
      print("❌ [Dio Exception] FCM registration failed: ${e.message}");
      if (e.response != null) {
        print("💬 Error from server: ${e.response?.data}");
      }
    } catch (e) {
      print("❌ Unexpected error during FCM registration: $e");
    }
  }


  Future<void> showLocalNotification(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
  'rafiq_channel_id',
  'Rafiq Notifications',
  icon: '@drawable/splash', // أو ic_notification
  importance: Importance.max,
  priority: Priority.high,
  ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _localNotificationsPlugin.show(
      notification.hashCode, 
      notification.title,    
      notification.body,     
      notificationDetails,
    );
  }
}

  Future<void> showTextNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
  'rafiq_chat_channel',
  'Rafiq Chat',
  icon: '@drawable/splash', // أو ic_notification
  importance: Importance.max,
  priority: Priority.high,
  ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _localNotificationsPlugin.show(
      title.hashCode ^ body.hashCode, 
      title,    
      body,     
      notificationDetails,
    );
  }
}