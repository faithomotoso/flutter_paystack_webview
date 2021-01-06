import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api/PaystackApi.dart';
import 'components/pkg_future_builder.dart';
import 'models/PaystackInitialize.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// This widget initializes a Paystack transaction using the
/// [customerEmail] and [amountInNaira] in Naira
/// The [authUrl] gotten from initialization is loaded in a [WebView].

class PaystackWebView extends StatefulWidget {
  /// Secret key gotten from Paystack
  final String secretKey;

  /// Email of the customer you're charging.
  final String customerEmail;

  /// Amount to charge, in Naira.
  ///
  /// Would be converted to Kobo automatically.
  final double amountInNaira;

  /// Callback after a transaction has been initialized.
  ///
  /// Returns a [PaystackInitialize] object.
  /// https://paystack.com/docs/api/#transaction-initialize
  final OnTransactionInitialize onTransactionInitialized;

  /// Callback after a transaction has been verified.
  ///
  /// WebView closes automatically if [usingEmbedded] is false
  /// Returns a [Map] object of the response, use this to confirm
  /// if a transaction was successful or not.
  /// Check the ["status"] for the status of the transaction
  /// https://paystack.com/docs/api/#transaction-verify
  final OnTransactionVerified onTransactionVerified;

  /// Callback URL appended to the initialization request body.
  /// Must start with https:// or https://
  ///
  ///
  /// This URL is used to detect when a transaction has been completed
  /// to trigger verification. If null, uses a default hardcoded URL.
  /// This URL would not be loaded or displayed.
  final String callbackURL;

  /// Set to true when embedding this Widget in a custom Widget
  /// e.g
  /// ``` dart
  /// Column(
  ///   children:[
  ///  Text("Some text by you"),
  ///  Expanded(
  ///  child: PaystackWebView(...)
  ///     )
  ///    ]
  ///   )
  /// ```
  /// This remove the back button and prevents popping the widget
  /// Check example folder...
  final bool usingEmbedded;

  PaystackWebView(
      {@required this.secretKey,
      @required this.customerEmail,
      @required this.amountInNaira,
      @required this.onTransactionVerified,
      @required this.callbackURL,
      this.usingEmbedded = false,
      this.onTransactionInitialized})
      : assert(secretKey != null, "Paystack secret key must not be null"),
        assert(customerEmail != null, "Customer email must not be null"),
        assert(amountInNaira != null, "Amount must not be null"),
        assert(amountInNaira > 0, "Amount can not be negative"),
        assert(onTransactionVerified != null,
            "onTransactionVerified must not be null"),
        assert(
            callbackURL.contains("https://") || callbackURL.contains("http://"),
            "Callback URL must begin with 'https:// or http://");

  @override
  _PaystackWebViewState createState() => _PaystackWebViewState();
}

class _PaystackWebViewState extends State<PaystackWebView> {
  Future initializingFuture;
  Future verifyingFuture;

  // When true, shows the webview
  // When false, shows the verifyingTransactionIndicator
  ValueNotifier<bool> showWebView = ValueNotifier<bool>(false);
  WebViewController webViewController;

  PaystackInitialize paystackInitialize;

  // Set to true when widget.usingEmbedded is true and transaction
  // has been verified
  bool showBlank = false;

  @override
  void initState() {
    super.initState();
    PaystackApi.init(
        callbackUrl: widget.callbackURL, secretKey: widget.secretKey);
    initializeTransaction();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: showBlank
            ? SizedBox()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.usingEmbedded) BackButton(),
                  Expanded(
                    child: PackageFutureBuilder(
                      future: initializingFuture,
                      onRefresh: () async {
                        setState(() {
                          initializeTransaction();
                        });
                      },
                      loadingWidget: _defaultInitializingIndicator(),
                      child: ValueListenableBuilder(
                        valueListenable: showWebView,
                        builder: (context, showWebView, child) {
                          // if (!showWebView) return _defaultVerifyingIndicator();
                          if (!showWebView) return verifyingWidget();

                          return WebView(
                            initialUrl: paystackInitialize?.authUrl ?? "",
                            onWebViewCreated: (controller) {
                              webViewController = controller;
                            },
                            javascriptMode: JavascriptMode.unrestricted,
                            navigationDelegate: navigationDelegate,
                          );
                        },
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Future initializeTransaction() async {
    initializingFuture = PaystackApi.initializeTransaction(
            customerEmail: widget.customerEmail, amount: widget.amountInNaira)
        .then((value) {
      // paystackInitialize = PaystackInitialize.fromJson(value.data["data"]);
      Map<String, dynamic> data = value.data["data"];
      paystackInitialize = PaystackInitialize(
          authUrl: data["authorization_url"],
          reference: data["reference"],
          accessCode: data["access_code"]);
      widget.onTransactionInitialized?.call(paystackInitialize);
      showWebView.value = true;
      return value;
    });
  }

  Future verifyTransaction() async {
    showWebView.value = false;
    verifyingFuture = PaystackApi.verifyTransaction(
            transactionReference: paystackInitialize?.reference)
        .then((value) {
      // Close webview
      // Only close the WebView when the widget is being used as a full screen
      // (by Navigation)
      if (!widget.usingEmbedded)
        Navigator.pop(context);
      else
        setState(() {
          showBlank = true;
        });

      widget.onTransactionVerified?.call(value.data["data"]);

      return value;
    });
  }

  Future<NavigationDecision> navigationDelegate(
      NavigationRequest request) async {
    if (request.url.contains("tel")) {
      // Handling event when a user taps on a USSD code
      if (await canLaunch(request.url)) launch(request.url);
    } else if (request.url.contains(PaystackApi.callbackUrl)) {
      // Transaction complete, verifyTransaction
      verifyTransaction();
    }

    return NavigationDecision.prevent;
  }

  Widget _defaultLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _colLoadingIndicator(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          SizedBox(
            height: 6,
          ),
          _defaultLoadingIndicator()
        ],
      ),
    );
  }

  Widget _defaultInitializingIndicator() {
    return _colLoadingIndicator("Initializing Transaction");
  }

  Widget _defaultVerifyingIndicator() {
    return _colLoadingIndicator("Verifying Transaction");
  }

  Widget verifyingWidget() {
    return PackageFutureBuilder(
        future: verifyingFuture,
        onRefresh: () async {
          setState(() {
            verifyTransaction();
          });
        },
        loadingWidget: _defaultVerifyingIndicator(),
        child: Container()
    );
  }
}

typedef OnTransactionInitialize(PaystackInitialize paystackInitialize);

typedef OnTransactionVerified(Map verificationMap);
