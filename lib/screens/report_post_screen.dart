import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';

class ReportPostScreen extends StatefulWidget {
  final String postAuthor;
  final String postId;

  const ReportPostScreen({Key key, this.postAuthor, this.postId}) : super(key: key);

  @override
  _ReportPostScreenState createState() => _ReportPostScreenState();
}

class _ReportPostScreenState extends State<ReportPostScreen> {
  String reason;
  TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: gradientAppBar(),
          leading: new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () {
              _onBackPressed();
            },
          ),
          title: Text('Report post'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Reason: '),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButton(
                        items: <String>[
                          'Sexual content',
                          'Bad language',
                          'Violence',
                          'Other'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String newValue) {
                          setState(() {
                            reason = newValue;
                          });
                          print('Report reason: $reason');
                        },
                        value: reason,
                      ),
                    ),
                  ],
                ),
                TextField(
                  maxLength: Sizes.maxPostChars,
                  minLines: 5,
                  maxLines: 15,
                  autofocus: true,
                  maxLengthEnforced: true,
                  controller: _textEditingController,
                  decoration: InputDecoration(
                      border: new OutlineInputBorder(
                          borderSide: new BorderSide(color: Colors.white)),
                      hintText: 'Details...'),
                  style: TextStyle(fontSize: 18),
                ),
                MaterialButton(
                  color: MyColors.darkPrimary,
                  child: Text('Send report'),
                  onPressed: () async {
                    await reportsRef.add({
                      'reason': reason,
                      'details': _textEditingController.text,
                      'post_author': widget.postAuthor,
                      'post_id': widget.postId,
                      'submitter': Constants.currentUserID,
                      'dealt': false,
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onBackPressed() {
    Navigator.of(context).pop();
  }
}
