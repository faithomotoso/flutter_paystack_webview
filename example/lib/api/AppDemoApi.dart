import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// For demo purposes

class AppDemoApi {
  static String callbackUrl = "https://some.callback.url";

  static Dio _dio = Dio(BaseOptions(
      baseUrl: "https://api.paystack.co",
      headers: {
        "Authorization": "Bearer sk_test_18f150552de869ce7f9030d5621242af78ef41d2"
      }));

  static Future initializeTransaction(
      {@required String customerEmail, @required double amount}) async {
    try {
      Response response = await _dio.post("/transaction/initialize", data: {
        "email": customerEmail,
        "amount": (amount * 100).toString(),
        "callback_url": callbackUrl
      });

      // Return the auth url -> paymentURL
      return response.data["data"]["authorization_url"];
    } on DioError catch (e) {
      log(e.message);
      log(e.toString());
      log(e.response.toString());
      return false;
    }
  }
}
