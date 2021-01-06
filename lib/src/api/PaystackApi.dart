import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

String _packageName = "flutter_paystack_webview";
class PaystackApi {
  static final Dio _dio = Dio(BaseOptions(baseUrl: "https://api.paystack.co"));

  /// Stores the [callbackUrl]
  static String _callbackUrl;

  /// Default [callbackUrl] if null
  static String _defaultCallbackUrl = "https://www.paystack.com";

  /// Returns a [callbackUrl]
  ///
  /// Used for [NavigationDelegate] in [WebView]
  static String get callbackUrl {
    return _callbackUrl ?? _defaultCallbackUrl;
  }

  /// Initialize [PaystackApi] with a callbackURL and [secretKey]
  static init({@required String callbackUrl, @required String secretKey}) {
    _appendSecretKey(secretKey);
    PaystackApi._callbackUrl = callbackUrl;
  }

  static void _assertSecretKey() {
    assert(_dio.options.headers.containsKey("Authorization"),
        "Paystack secret key not found");
  }

  /// Append [secretKey] to dio header
  static void _appendSecretKey(String secretKey) {
    _dio.options.headers["Authorization"] = "Bearer $secretKey";
  }

  /// Initializes a transaction
  ///
  /// Makes an api call with the customers email and amount
  /// Gets the [PaystackInitialize.authUrl] to be used in a [WebView]
  static Future initializeTransaction(
      {@required String customerEmail, @required double amount}) async {
    _assertSecretKey();

    // using raw dio.post for error to be handled in the future builder
    try {
      Response response = await _dio.post("/transaction/initialize", data: {
        "email": customerEmail,
        "amount": (amount * 100).toString(),
        "callback_url": callbackUrl
      });
      return response;
    } on DioError catch (e) {
      debugPrint("$_packageName: Error initializing transaction: ${e.response}");
      if (e.response.data.containsKey("message")) {
        if (e.response.data["message"]
            .toString()
            .toLowerCase()
            .contains("key")) {
          print("$_packageName: Please check your Paystack secret key");
        }
      }
      throw e;
    }
  }

  /// Verifies a transaction
  static Future verifyTransaction(
      {@required String transactionReference}) async {
    _assertSecretKey();
    assert(
        transactionReference != null, "Transaction reference must not be null");

    return _dio.get("/transaction/verify/$transactionReference");
  }
}
