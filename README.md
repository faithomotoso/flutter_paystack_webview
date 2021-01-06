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

#### As embedded
```dart
...
PaystackWebView(
    // if embedded set usingEmbedded to true
          setEmbedded: true,
          secretKey: "your_secret_key",
          customerEmail: "customer@email.com",
          amountInNaira: "100",
          callbackURL: "https://www.paystack.com",
          onTransactionInitialized: (PaystackInitialize paystackInitialize) {
            print(paystackInitialize.toString());
          },
          onTransactionVerified: (verifiedMap) async {
            print("Transaction verified: $verifiedMap");
          },)
...
```

#### As full page
```dart
Navigator.push(context, builder: (_) => PaystackWebView(
                            // if embedded set usingEmbedded to true
                                    setEmbedded: true,
                                    secretKey: "your_secret_key",
                                    customerEmail: "customer@email.com",
                                    amountInNaira: "100",
                                    callbackURL: "https://www.paystack.com",
                                    onTransactionInitialized: (PaystackInitialize paystackInitialize) {
                                    print(paystackInitialize.toString());
                                    },
                                    onTransactionVerified: (verifiedMap) async {
                                    print("Transaction verified: $verifiedMap");
                                    },));
```


### Please report bugs and suggest features

