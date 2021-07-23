import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_paystack_webview/src/components/error_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'api/PaystackApi.dart';
import 'components/pkg_future_builder.dart';
import 'models/PaystackInitialize.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'models/WebviewError.dart';

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

  /// Extra data to pass to the initialize api
  /// https://paystack.com/docs/api/#transaction
  final Map<String, dynamic> extraInitData;

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
  /// Must start with https:// or http://
  ///
  ///
  /// This URL is used to detect when a transaction has been completed
  /// to trigger verification. If null, uses a default hardcoded URL.
  /// This URL would not be loaded or displayed.
  final String callbackURL;

  /// Set to true when embedding this Widget as a child of another widget
  /// e.g
  /// ``` dart
  /// Column(
  ///   children:[
  ///  Text(""),
  ///  .
  ///  .
  ///  .
  ///  Expanded(
  ///  child: PaystackWebView(...)
  ///     )
  ///    ]
  ///   )
  /// ```
  /// This removes the back button and prevents popping the widget when the transaction is complete
  /// Check example folder...
  final bool usingEmbedded;

  PaystackWebView(
      {@required this.secretKey,
      @required this.customerEmail,
      @required this.amountInNaira,
      @required this.onTransactionVerified,
      @required this.callbackURL,
      this.extraInitData,
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

  // When true, shows the webView
  // When false, shows the verifyingTransactionIndicator
  ValueNotifier<bool> showWebView = ValueNotifier<bool>(false);
  ValueNotifier<bool> showVerification = ValueNotifier<bool>(false);
  ValueNotifier<bool> webViewError = ValueNotifier<bool>(false);
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
  void dispose() {
    showWebView.dispose();
    showVerification.dispose();
    webViewError.dispose();

    super.dispose();
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

                          return ValueListenableBuilder(
                              valueListenable: webViewError,
                              builder: (context, webViewHasError, child) {
                                if (webViewHasError)
                                  return PkgErrorWidget(
                                      errorMessage:
                                          "An error occurred while loading. Tap to reload.",
                                      onRefresh: () {
                                        webViewError.value = false;
                                        // webViewController.reload();
                                      });

                                return WebView(
                                  initialUrl: paystackInitialize?.authUrl ?? "",
                                  onWebViewCreated: (controller) {
                                    webViewController = controller;
                                  },
                                  javascriptMode: JavascriptMode.unrestricted,
                                  navigationDelegate: navigationDelegate,
                                  onWebResourceError: handleWebResourceError,
                                );
                              });
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
            customerEmail: widget.customerEmail,
            amount: widget.amountInNaira,
            extraData: widget.extraInitData ?? {})
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
    showVerification.value = true;
    verifyingFuture = PaystackApi.verifyTransaction(
            transactionReference: paystackInitialize?.reference)
        .then((value) {
      showVerification.value = false;
      // Close web-view
      // Only close the WebView when the widget is being used as a full screen
      // (by Navigation)
      if (!widget.usingEmbedded)
        Navigator.pop(context);
      else
        setState(() {
          showBlank = true;
        });

      Map<String, dynamic> data = value.data["data"];
      widget.onTransactionVerified
          ?.call(data, data["status"], data["reference"]);

      return value;
    });
  }

  Future<NavigationDecision> navigationDelegate(
      NavigationRequest request) async {
    // print("Navigation request: $request, ${request.url}");
    if (request.url.contains("tel")) {
      // Handling event when a user taps on a USSD code
      if (await canLaunch(request.url)) launch(request.url);
    } else if (request.url.contains(PaystackApi.callbackUrl)) {
      // Transaction complete, verifyTransaction
      verifyTransaction();
    } else if (request.url.contains("checkout")) {
      // Fixes blank screen on iOS
      return NavigationDecision.navigate;
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
    return ValueListenableBuilder(
      valueListenable: showVerification,
      builder: (context, showVerification, child) {
        if (!showVerification) return SizedBox();

        return PackageFutureBuilder(
            future: verifyingFuture,
            onRefresh: () async {
              setState(() {
                verifyTransaction();
              });
            },
            loadingWidget: _defaultVerifyingIndicator(),
            child: Container());
      },
    );
  }

  void handleWebResourceError(WebResourceError webResourceError) {
    String errorDescription = webResourceError.description;
    if (WebViewError.hasWebviewError(errorDescription)) {
      // Display an error widget to reload the current url
      webViewError.value = true;
    }
  }
}

typedef OnTransactionInitialize(PaystackInitialize paystackInitialize);

typedef OnTransactionVerified(
    Map verificationMap, String status, String reference);

