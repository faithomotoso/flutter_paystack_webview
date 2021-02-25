import 'package:flutter/material.dart';

class PkgErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRefresh;

  PkgErrorWidget({@required this.errorMessage, @required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            errorMessage,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 5,
          ),
          IconButton(
              icon: Icon(Icons.refresh_outlined), onPressed: onRefresh?.call)
        ],
      ),
    );
  }
}
