# flutter_paystack_webview
A Flutter plugin for payments with Paystack using a WebView.

=========================================
### Note: This package is experimental
=========================================

## Installation
To use this package, add in `pubspec.yaml`
```yaml
flutter_paystack_webview:
    git: https://github.com/faithomotoso/flutter_paystack_webview.git
```

## Usage

You can use this plugin either as a *full page* or *embedded* with your own page

`paymentURL` should be initialized either from your backend or locally on the app using
https://paystack.com/docs/api/#transaction

`onTransactionCompleted` is called when the transaction has been completed and your `callbackURL` is Navigated to
Run verification of the transaction here https://paystack.com/docs/api/#transaction-verify

#### As embedded
```dart
PaystackWebView(
          usingEmbedded: true,
          paymentUrl: "URL gotten from paystack initialization"
          callbackURL: "https://www.paystack.com",
          onTransactionCompleted: () {
          // Verify transaction here
})
```

#### As full page
Note: When the transaction is completed, the webview closes itself using `Navigator.pop(context)` before calling `onTransactionCompleted`
```dart
Navigator.push(context, builder: (_) => PaystackWebView(
                                    paymentUrl: "URL gotten from paystack initialization"
                                    callbackURL: "https://www.paystack.com",
                                    onTransactionCompleted: () {
                                  // Verify transaction here
                        }));
```


### Please report bugs and suggest features

