import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tags/tag.dart';
import 'package:image_ml/components/rounded_button.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

void main() => runApp(ImageApp());

class ImageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.amber[100],
        backgroundColor: Colors.amber[100],
        accentColor: Colors.amberAccent,
//        fontFamily: 'NotoSerif',
      ),
      home: ImagePage(),
    );
  }
}

class ImagePage extends StatefulWidget {
  static const String id = "text_screen";

  @override
  _ImagePageState createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage>
    with SingleTickerProviderStateMixin {
  File pickedImage;
  bool isImageLoaded = false;
  TabController _tabController;
  ScrollController _scrollViewController;

  final String _selectInstructions =
      'Select an image from your gallery for machine learning'
      ' (ML Vision) text extraction.'
      ' Then, edit the extracted words to your liking.'
      ' When finished editing, you can search for them in the web.';
  final String _searchInstructions = 'Use the back arrow to navigate'
      ' back to the app after searching.';

  bool _symmetry = false;
  bool _startDirection = false;
  bool _horizontalScroll = false;

  int _column = 0;
  double _fontSize = 18;

  String _onPressed = '';

  FirebaseVisionImage ourImage;

  Future pickImage() async {
    try {
      var tempStore = await ImagePicker.pickImage(
          source: ImageSource.gallery, maxHeight: 2000.0, maxWidth: 2000.0);
      setState(() {
        pickedImage = tempStore;
        isImageLoaded = true;
        readText();
      });
    } catch (e) {
      throw Exception('File is not available');
    }
  }

  Future<void> _launchURL() async {
    int _count = 0;

    String url = 'https://www.google.com/search?q=';
    String workvar = "";
    for (var _mytag in _items) {
      _count += 1;
      // Google searches are restricted to 32 words
      if (_count < 33) {
        workvar = _mytag;
        // Strip special characters from the tag
        workvar = workvar.replaceAll(RegExp(r'[^\s\w]'), '');
        url = url + workvar + '+';
      }
    }
//    print("Search url $url");

    if (await canLaunch(url)) {
      await launch(
        url,
//        forceSafariVC: true,
        forceWebView: true,
        enableJavaScript: true,
      );
      setState(() {});
    } else {
      throw 'Could not launch $url';
    }
  }

  Future readText() async {
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    ourImage = FirebaseVisionImage.fromFile(pickedImage);
    VisionText visionText = await recognizeText.processImage(ourImage);

    // flush list as it might be a subsequent image being processed
    if (_items.length > 0) {
      _items.removeRange(0, _items.length);
    }

    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        // Same getters as TextBlock
        for (TextElement element in line.elements) {
          // Same getters as TextBlock
//          print(element.text);
          if (element.text != null) {
            _items.add(element.text);
          }
        }
      }
    }

    if (_items.length == 0) {
      _items.add("No text returned from ML Vision for this image.");
    }
//    print("_items $_items");
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollViewController = ScrollController();
  }

  List _items = [];

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height * 0.65;
    double _width = MediaQuery.of(context).size.width * 0.9;

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollViewController,
        headerSliverBuilder: (BuildContext context, bool boxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              centerTitle: true,
              pinned: true,
              expandedHeight: 0,
              floating: true,
              forceElevated: boxIsScrolled,
              bottom: TabBar(
                isScrollable: false,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 6.0,
//                labelStyle: TextStyle(fontSize: 18.0, fontFamily: 'NotoSerif'),
                labelStyle: TextStyle(fontSize: 18.0),
                tabs: [
                  Tab(text: "Select"),
                  Tab(text: "Edit Words"),
                  Tab(text: "Search"),
                ],
                controller: _tabController,
              ),
            )
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            ListView(
              padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
              children: <Widget>[
                SizedBox(height: 10.0),
                isImageLoaded
                    ? Image.file(pickedImage,
                        height: _height, width: _width, fit: BoxFit.cover)
                    : Container(),
                SizedBox(height: 10.0),
                RoundedButton(
                  title: 'Select Image',
                  color: Colors.lightBlueAccent,
                  onPressed: pickImage,
                ),
                Text(_selectInstructions, style: TextStyle(fontSize: 20.0)),
              ],
            ),
            CustomScrollView(
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: Colors.grey[300], width: 0.5),
                          ),
                        ),
                        margin:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: ExpansionTile(
                          title: Text("Settings"),
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                GestureDetector(
                                  child: Row(
                                    children: <Widget>[
                                      Checkbox(
                                          value: _horizontalScroll,
                                          onChanged: (a) {
                                            setState(() {
                                              _horizontalScroll =
                                                  !_horizontalScroll;
                                            });
                                          }),
                                      Text('Horizontal scroll')
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _horizontalScroll = !_horizontalScroll;
                                    });
                                  },
                                ),
                                GestureDetector(
                                  child: Row(
                                    children: <Widget>[
                                      Checkbox(
                                          value: _startDirection,
                                          onChanged: (a) {
                                            setState(() {
                                              _startDirection =
                                                  !_startDirection;
                                            });
                                          }),
                                      Text('Start Direction')
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _startDirection = !_startDirection;
                                    });
                                  },
                                ),
                              ],
                            ),
                            Column(
                              children: <Widget>[
                                Text('Font Size'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Slider(
                                      value: _fontSize,
                                      min: 6,
                                      max: 30,
                                      onChanged: (a) {
                                        setState(() {
                                          _fontSize = (a.round()).toDouble();
                                        });
                                      },
                                    ),
                                    Text(_fontSize.toString()),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(20),
                      ),
                      _imageTags,
                      Container(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: <Widget>[
                            Divider(
                              color: Colors.blueGrey,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(_onPressed),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ListView(
              padding: EdgeInsets.symmetric(vertical: 70.0, horizontal: 4.0),
              children: <Widget>[
//                SizedBox(height: 10.0),
                RoundedButton(
                  title: 'Search words',
                  color: Colors.lightBlueAccent,
                  onPressed: () {
                    _launchURL();
                  },
                ),
                Text(_searchInstructions, style: TextStyle(fontSize: 20.0)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Position for popup menu
  Offset _tapPosition;

  Widget get _imageTags {
    //popup Menu
    final RenderBox overlay = Overlay.of(context).context?.findRenderObject();

    ItemTagsCombine combine = ItemTagsCombine.onlyText;

    return Tags(
      symmetry: _symmetry,
      columns: _column,
      horizontalScroll: _horizontalScroll,
      verticalDirection:
          _startDirection ? VerticalDirection.up : VerticalDirection.down,
      textDirection: _startDirection ? TextDirection.rtl : TextDirection.ltr,
      heightHorizontalScroll: 60 * (_fontSize / 14),
      textField: TagsTextFiled(
        hintText: "Add a word",
        autofocus: false,
        textStyle: TextStyle(fontSize: _fontSize),
        onSubmitted: (String str) {
          setState(() {
            _items.add(str);
          });
        },
      ),
      itemCount: _items.length,
      itemBuilder: (index) {
        final item = _items[index];

        return GestureDetector(
          child: ItemTags(
            index: index,
            title: item,
            pressEnabled: false,
            activeColor: Colors.green[400],
            combine: combine,
            removeButton: ItemTagsRemoveButton(
              backgroundColor: Colors.green[900],
            ),
            textScaleFactor:
                utf8.encode(item.substring(0, 1)).length > 2 ? 0.8 : 1,
            textStyle: TextStyle(
              fontSize: _fontSize,
            ),
            onRemoved: () {
              setState(() {
                _items.removeAt(index);
              });
            },
          ),
          onTapDown: (details) => _tapPosition = details.globalPosition,
          onLongPress: () {
            showMenu(
                    items: <PopupMenuEntry>[
                  PopupMenuItem(
                    child: Text(item, style: TextStyle(color: Colors.blueGrey)),
                    enabled: false,
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.content_copy),
                        Text("Copy text"),
                      ],
                    ),
                  ),
                ],
                    context: context,
                    position: RelativeRect.fromRect(
                        _tapPosition & Size(40, 40),
                        Offset.zero &
                            overlay
                                .size) // & RelativeRect.fromLTRB(65.0, 40.0, 0.0, 0.0),
                    )
                .then((value) {
              if (value == 1) Clipboard.setData(ClipboardData(text: item));
            });
          },
        );
      },
    );
  }
}
