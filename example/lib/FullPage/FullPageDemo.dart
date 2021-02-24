import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_paystack_webview/flutter_paystack_webview.dart';

// This launches the PaystackWebView as a full page by navigating to it

class FullPageDemo extends StatefulWidget {
  @override
  _FullPageDemoState createState() => _FullPageDemoState();
}

class _FullPageDemoState extends State<FullPageDemo> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Full Page Demo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            SizedBox(
              height: 10,
            ),
            TextFormField(
              controller: amountController,
              decoration: InputDecoration(labelText: "Amount"),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PaystackWebView(
                                // your secret key here
                                secretKey: "your_secret_key",
                                customerEmail: emailController.text,
                                amountInNaira:
                                    double.parse(amountController.text),
                                callbackURL: "https://www.google.com",
                                onTransactionInitialized:
                                    (PaystackInitialize paystackInitialize) {
                                  print(paystackInitialize.toString());
                                },
                                onTransactionVerified: (verifiedMap, status, reference) async {
                                  print("Transaction verified: $verifiedMap");
                                  await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return Center(
                                          child: Container(
                                            height: 200,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.5,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            child: Align(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "Transaction ${verifiedMap["status"]}",
                                                    style: TextStyle(
                                                        inherit: false,
                                                        color: Colors.black,
                                                        fontSize: 20),
                                                  ),
                                                  OutlinedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child: Text("OK"))
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      });
                                },
                              )));
                },
                child: Text("Pay")),
          ],
        ),
      ),
    );
  }
}
