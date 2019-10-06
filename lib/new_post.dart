import 'package:flutter/material.dart';

class NewPost extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              minLines: 10,
              maxLines: 20,
              autocorrect: true,
              autofocus: true,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(child: Container( margin: EdgeInsets.symmetric(horizontal: 10),child: RaisedButton(onPressed: null)),
                  flex: 1,),
                SizedBox(
                  width: 20,
                ),
                Expanded(child: Container( margin: EdgeInsets.symmetric(horizontal: 10),child: RaisedButton(onPressed: null)),
                  flex: 1,),
              ],
            ),
            Container( margin: EdgeInsets.symmetric(horizontal: 10),child: RaisedButton(onPressed: null))
          ],
        ),
      ),
    );
  }

}