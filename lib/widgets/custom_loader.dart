import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/sizes.dart';

class CustomLoader {
  static CustomLoader _customLoader;

  CustomLoader._createObject();

  factory CustomLoader() {
    if (_customLoader != null) {
      return _customLoader;
    } else {
      _customLoader = CustomLoader._createObject();
      return _customLoader;
    }
  }

  //static OverlayEntry _overlayEntry;
  OverlayState _overlayState; //= new OverlayState();
  OverlayEntry _overlayEntry;

  _buildLoader() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Container(
            height: Sizes.fullHeight(context),
            width: Sizes.fullWidth(context),
            child: buildLoader(context));
      },
    );
  }

  showLoader(context, {height = 100.0, width = 100.0}) {
    _overlayState = Overlay.of(context);
    _buildLoader();
    _overlayState.insert(_overlayEntry);
  }

  hideLoader() {
    try {
      _overlayEntry?.remove();
      _overlayEntry = null;
    } catch (e) {
      print("Exception:: $e");
    }
  }

  buildLoader(BuildContext context, {height = 100.0, width = 100.0}) {
    return Center(
        child: Image.asset(
      'assets/images/glitcher_loader.gif',
      height: height,
      width: width,
    ));
  }
}

class CustomScreenLoader2 {
  static CustomScreenLoader2 _customScreenLoader;

  CustomScreenLoader2._createObject();

  factory CustomScreenLoader2() {
    if (_customScreenLoader != null) {
      return _customScreenLoader;
    } else {
      _customScreenLoader = CustomScreenLoader2._createObject();
      return _customScreenLoader;
    }
  }

  //static OverlayEntry _overlayEntry;
  OverlayState _overlayState; //= new OverlayState();
  OverlayEntry _overlayEntry;

  _buildLoader() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Container(
            height: Sizes.fullHeight(context),
            width: Sizes.fullWidth(context),
            child: buildLoader(context));
      },
    );
  }

  showLoader(context, {height = 100.0, width = 100.0}) {
    _overlayState = Overlay.of(context);
    _buildLoader();
    _overlayState.insert(_overlayEntry);
  }

  hideLoader() {
    try {
      _overlayEntry?.remove();
      _overlayEntry = null;
    } catch (e) {
      print("Exception:: $e");
    }
  }

  buildLoader(BuildContext context, {height = 100.0, width = 100.0}) {
    return Center(
        child: Image.asset(
      'assets/images/glitcher_loader.gif',
      height: height,
      width: width,
    ));
  }
}

class CustomScreenLoader extends ModalRoute<void> {
//  @override
//  Widget build(BuildContext context) {
////    return Container(
////      child: Container(
////        height: Sizes.fullHeight(context),
////        width: Sizes.fullWidth(context),
////        alignment: Alignment.center,
////        child: Container(
////          padding: EdgeInsets.all(10),
////          decoration: BoxDecoration(
////              color: Colors.white,
////              borderRadius: BorderRadius.all(Radius.circular(10))),
////          child: Stack(
////            alignment: Alignment.center,
////            children: <Widget>[
////              Platform.isIOS
////                  ? CupertinoActivityIndicator(
////                      radius: 35,
////                    )
////                  : CircularProgressIndicator(
////                      strokeWidth: 2,
////                    ),
////              Image.asset(
////                'assets/images/glitcher_loader.gif',
////                height: 200,
////                width: 200,
////              )
////            ],
////          ),
////        ),
////      ),
////    );
//    return Center(
//        child: Image.asset(
//      'assets/images/glitcher_loader.gif',
//      height: 150,
//      width: 150,
//    ));
//  }

  @override
  Color get barrierColor => Colors.black.withOpacity(0.5);

  @override
  bool get barrierDismissible => false;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => Duration(milliseconds: 500);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // This makes sure that text and other content follows the material style
    return Material(
      type: MaterialType.transparency,
      // make sure that the overlay content is not cut off
      child: SafeArea(
        child: _buildOverlayContent(context),
      ),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    return Center(
        child: Image.asset(
      'assets/images/glitcher_loader.gif',
      height: 150,
      width: 150,
    ));
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // You can add your own animations for the overlay content
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  }
}
