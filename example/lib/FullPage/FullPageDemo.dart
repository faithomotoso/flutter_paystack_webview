import 'package:example/api/AppDemoApi.dart';
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
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final ValueNotifier<bool> loadingTransaction = ValueNotifier<bool>(false);

  String paymentUrl;

  @override
  void initState() {
    super.initState();
    emailController.text = "ayoomotoso@yandex.com";
    amountController.text = "100";

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Full Page Demo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
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
                  child: Text("Pay")),
            ],
          ),
        ),
      ),
    );
  }

  void initTransaction() async {
    // This should either be done from your backend or within the app itself
    // Doing this within the app will require your secret key from paystack

    showDialog(context: context, builder: (ctx) => Center(child: CircularProgressIndicator(),));
    loadingTransaction.value = true;
    AppDemoApi.initializeTransaction(customerEmail: emailController.text,
        amount: double.parse(amountController.text)).then((value) {
          loadingTransaction.value = false;
          Navigator.pop(context);
          if (value is String) {
            setState(() {
              paymentUrl = value;
            });

            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        PaystackWebView(
                          callbackURL: AppDemoApi.callbackUrl,
                          paymentURL: paymentUrl,
                          onTransactionCompleted: () {
                            showDialog(
                                context: context,
                                builder: (ctx) {
                                  return Center(
                                    child: Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              "Transaction complete, verify transaction here",
                                          style: TextStyle(inherit: false, color: Colors.black),),
                                          ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context),
                                              child: Text("Ok"))
                                        ],
                                      ),
                                    ),
                                  );
                                });
                          },
                        )));
          }
    });
  }
}
