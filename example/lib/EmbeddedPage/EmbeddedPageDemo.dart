import 'package:example/api/AppDemoApi.dart';
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
  void initState() {
    super.initState();
    emailController.text = "some@email.com";
    amountController.text = "100";
  }

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
                  initTransaction();
                },
                child: Text("Pay"))
          ],
        ),
      ),
    );
  }

  void initTransaction() async {
    showDialog(context: context, builder: (ctx) => Center(child: CircularProgressIndicator(),));
    AppDemoApi.initializeTransaction(
        customerEmail: emailController.text,
        amount: double.parse(amountController.text))
        .then((value) {
      Navigator.pop(context);
      if (value is String) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CustomPaymentPage(
                  amountInNaira: amountController.text,
                  paymentUrl: value,
                )));
      }
    });
  }
}

class CustomPaymentPage extends StatefulWidget {
  final String paymentUrl;
  final String amountInNaira;

  CustomPaymentPage({@required this.paymentUrl, this.amountInNaira});

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
              callbackURL: AppDemoApi.callbackUrl,
              paymentURL: widget.paymentUrl,
              onTransactionCompleted: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return Center(
                        child: Container(
                          height: 200,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8)),
                          child: Align(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Transaction completed. Verify here",
                                  style: TextStyle(
                                      inherit: false,
                                      color: Colors.black,
                                      fontSize: 20),
                                ),
                                ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("OK"))
                              ],
                            ),
                          ),
                        ),
                      );
                    });
              },
            ),
          )
        ],
      ),
    );
  }

}
