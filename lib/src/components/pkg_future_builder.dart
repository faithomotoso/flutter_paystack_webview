import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paystack_webview/src/components/error_widget.dart';

class PackageFutureBuilder extends StatefulWidget {
  final Future future;
  final VoidCallback onRefresh;
  final Widget child;
  final Function onData;
  final Widget loadingWidget;

  PackageFutureBuilder(
      {@required this.future,
      @required this.onRefresh,
      @required this.child,
      this.onData,
      this.loadingWidget});

  @override
  _PackageFutureBuilderState createState() => _PackageFutureBuilderState();
}

class _PackageFutureBuilderState extends State<PackageFutureBuilder> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return widget.loadingWidget;

        if (snapshot.hasError) {
          return PkgErrorWidget(
            errorMessage: "An error occurred. Tap to reload",
            onRefresh: widget.onRefresh?.call,
          );
        }

        return widget.child;
      },
    );
  }

  Widget _errorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              widget.onRefresh?.call();
            },
            icon: Icon(Icons.refresh),
          ),
          SizedBox(
            height: 4,
          ),
          Text("An error occurred. Tap to reload.")
        ],
      ),
    );
  }
}
