import 'package:example/EmbeddedPage/EmbeddedPageDemo.dart';
import 'package:example/FullPage/FullPageDemo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_paystack_webview/flutter_paystack_webview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Paystack WebView Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Demo(),
    );
  }
}

class Demo extends StatefulWidget {
  @override
  _DemoState createState() => _DemoState();
}

class _DemoState extends State<Demo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Demo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (_) => FullPageDemo()));
              }, child: Text("Full Page Demo")),
              ElevatedButton(onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (_) => EmbeddedPageDemo()));
              }, child: Text("Embedded Page Demo")),
            ],
          ),
        ),
      ),
    );
  }
}
