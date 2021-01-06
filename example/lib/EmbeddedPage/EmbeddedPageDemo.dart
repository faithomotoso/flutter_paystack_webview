import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_paystack_webview/flutter_paystack_webview.dart';

class EmbeddedPageDemo extends StatefulWidget {
  @override
  _EmbeddedPageDemoState createState() => _EmbeddedPageDemoState();
}

class _EmbeddedPageDemoState extends State<EmbeddedPageDemo> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Embedded Page Demo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
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
                          builder: (_) => CustomPaymentPage(
                                email: emailController.text,
                                amountInNaira: amountController.text,
                              )));
                },
                child: Text("Pay"))
          ],
        ),
      ),
    );
  }
}

class CustomPaymentPage extends StatefulWidget {
  final String email;
  final String amountInNaira;

  CustomPaymentPage({this.email, this.amountInNaira});

  @override
  _CustomPaymentPageState createState() => _CustomPaymentPageState();
}

class _CustomPaymentPageState extends State<CustomPaymentPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Custom Payment Page"),
      ),
      body: Column(
        children: [
          Text("You are now paying ${widget.amountInNaira}"),
          Expanded(
            child: PaystackWebView(
                usingEmbedded: true,
                // your secret key here
                secretKey: "your_secret_key",
                customerEmail: widget.email,
                amountInNaira: double.parse(widget.amountInNaira),
                callbackURL: "https://www.google.com",
                onTransactionInitialized:
                    (PaystackInitialize paystackInitialize) {
                  print(paystackInitialize.toString());
                },
                onTransactionVerified: (verifiedMap) async {
                  print("Transaction verified: $verifiedMap");
                  await showDialog(
                      context: context,
                      builder: (context) {
                        return Center(
                          child: Container(
                            height: 200,
                            width: MediaQuery.of(context).size.width * 0.5,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8)),
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
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("OK"))
                                ],
                              ),
                            ),
                          ),
                        );
                      });
                }),
          )
        ],
      ),
    );
  }
}
