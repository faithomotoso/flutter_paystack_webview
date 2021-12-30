import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_paystack_webview/src/components/error_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'models/WebviewError.dart';

class PaystackWebView extends StatefulWidget {
  /// URL gotten from paystack after initializing.
  /// Initialization should either be from your backend or done locally
  final String paymentURL;

  /// Called when a transaction has been completed and webview closed (fullscreen)
  final VoidCallback onTransactionCompleted;

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
  /// Check the example folder...
  final bool usingEmbedded;

  PaystackWebView(
      {@required this.paymentURL,
      @required this.callbackURL,
      @required this.onTransactionCompleted,
      this.usingEmbedded = false})
      : assert(
            callbackURL.contains("https://") || callbackURL.contains("http://"),
            "Callback URL must begin with 'https:// or http://");

  @override
  _PaystackWebViewState createState() => _PaystackWebViewState();
}

class _PaystackWebViewState extends State<PaystackWebView> {
  final ValueNotifier<bool> webViewError = ValueNotifier<bool>(false);
  final ValueNotifier<bool> loadingWebview = ValueNotifier<bool>(false);
  WebViewController webViewController;

  // Set to true when widget.usingEmbedded is true and transaction
  // has been completed
  bool showBlank = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  void dispose() {
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
                    child: ValueListenableBuilder(
                        valueListenable: webViewError,
                        builder: (context, wError, child) {
                          if (wError)
                            return PkgErrorWidget(
                                errorMessage:
                                    "An error occurred while loading. Tap to reload.",
                                onRefresh: () {
                                  webViewError.value = false;
                                  // webViewController.reload();
                                });

                          return ValueListenableBuilder(
                              valueListenable: loadingWebview,
                              builder: (context, loading, child) {
                                return IndexedStack(
                                  index: loading ? 0 : 1,
                                  children: [
                                    _colLoadingIndicator(
                                        "Loading payment gateway..."),
                                    WebView(
                                      initialUrl: widget.paymentURL,
                                      onWebViewCreated: (controller) {
                                        webViewController = controller;
                                        loadingWebview.value = true;
                                      },
                                      onPageFinished: (_) {
                                        loadingWebview.value = false;
                                      },
                                      javascriptMode:
                                          JavascriptMode.unrestricted,
                                      navigationDelegate: navigationDelegate,
                                      onWebResourceError:
                                          handleWebResourceError,
                                    )
                                  ],
                                );
                              });
                        }),
                  )
                ],
              ),
      ),
    );
  }

  Future<NavigationDecision> navigationDelegate(
      NavigationRequest request) async {
    // print("Navigation request: $request, ${request.url}");
    if (request.url.contains("tel")) {
      // Handling event when a user taps on a USSD code
      if (await canLaunch(request.url)) launch(request.url);
    } else if (request.url.contains(widget.callbackURL)) {
      // Transaction complete

      if (!widget.usingEmbedded) {
        Navigator.pop(context);
      } else {
        setState(() {
          showBlank = true;
        });
      }
      widget.onTransactionCompleted?.call();
    } else if (request.url.contains("checkout")) {
      // Fixes blank screen on iOS
      return NavigationDecision.navigate;
    }

    return NavigationDecision.prevent;
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
          Center(
            child: CircularProgressIndicator(),
          )
        ],
      ),
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
