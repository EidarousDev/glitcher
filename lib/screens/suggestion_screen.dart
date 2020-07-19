import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';

class SuggestionScreen extends StatefulWidget {
  final String initialTitle;
  final String initialDetails;
  final String gameId;

  const SuggestionScreen({Key key, this.initialTitle, this.initialDetails, this.gameId,}) : super(key: key);

  @override
  _SuggestionScreenState createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  TextEditingController _detailsTextEditingController = TextEditingController();
  TextEditingController _titleTextEditingController = TextEditingController();
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    setState(() {
      _titleTextEditingController.text = widget.initialTitle;
      _detailsTextEditingController.text = widget.initialDetails;
    });

    super.initState();
  }

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
          title: Text('New suggestion'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    autofocus: true,
                    controller: _titleTextEditingController,
                    decoration: InputDecoration(
                        border: new OutlineInputBorder(
                            borderSide: new BorderSide(color: Colors.white)),
                        hintText: 'Title'),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                TextField(
                  maxLength: Sizes.maxPostChars,
                  minLines: 5,
                  maxLines: 15,
                  autofocus: true,
                  maxLengthEnforced: true,
                  focusNode: focusNode,
                  controller: _detailsTextEditingController,
                  decoration: InputDecoration(
                      border: new OutlineInputBorder(
                          borderSide: new BorderSide(color: Colors.white)),
                      hintText: 'Details...'),
                  style: TextStyle(fontSize: 14),
                ),
                MaterialButton(
                  color: MyColors.darkPrimary,
                  child: Text('Send suggestion'),
                  onPressed: () async {

                    await suggestionsRef.add({
                      'title': _titleTextEditingController.text,
                      'details': _detailsTextEditingController.text,
                      'submitter': Constants.currentUserID,
                      'game_id': widget.gameId,
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
  @override
  void didChangeDependencies() {
    FocusScope.of(context).requestFocus(focusNode);
    super.didChangeDependencies();
  }
}


