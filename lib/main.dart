// @dart=2.9
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:hello_me/auth.dart';
import 'package:hello_me/fav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return ChangeNotifierProvider<Fav>(
              create: (_) => Fav(saved: []), child: MyApp());
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        // Add the 3 lines from here...
        primaryColor: Colors.red,
      ),
      home: RandomWords(),
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final snackBar_del =
      SnackBar(content: Text('Deletion is not implemented yet'));
  final snackBar_img = SnackBar(content: Text('No image selected'));
  final _suggestions = <WordPair>[];
  final _saved = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18);
  AuthRepository auth = AuthRepository.instance();
  var _email_string;
  var _pssword_string;
  var _password_2;
  var is_loggedin = false;
  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // NEW lines from here...
        builder: (BuildContext context) {
          return Consumer<Fav>(builder: (context, fav, _) {
            final tiles = Provider.of<Fav>(context, listen: false).saved.map(
              (WordPair pair) {
                return ListTile(
                  title: Text(
                    pair.asPascalCase,
                    style: _biggerFont,
                  ),
                  trailing: Icon(Icons.delete_outline),
                  onTap: () async {
                    Provider.of<Fav>(context, listen: false).remove(pair);
                    if (auth.isAuthenticated) {
                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(FirebaseAuth.instance.currentUser.uid.toString())
                          .collection("favorites")
                          .doc(pair.toString())
                          .delete();
                    }
                  },
                );
              },
            );

            List<Widget> divided = [];
            if (tiles.isNotEmpty) {
              divided = ListTile.divideTiles(
                context: context,
                tiles: tiles,
              ).toList();
            }

            return Scaffold(
              appBar: AppBar(
                title: Text('Saved Suggestions'),
              ),
              body: ListView(children: divided),
            );
          });
        },
      ),
    );
  }

  void confirm_sign_up() {
    if (_password_2 == _pssword_string) {
      Provider.of<Fav>(context, listen: false).match_true();
      auth.signUp(_email_string, _pssword_string);
      _do_login();
      Navigator.pop(context);
    } else {
      Provider.of<Fav>(context, listen: false).match_false();
    }
  }


  void doo_sign_up(BuildContext context) async {
    showModalBottomSheet(
        context: context,
        builder: (aa) {
        return Container(
          height: 180,
          color: Colors.white,
          alignment: FractionalOffset.center,
          padding: const EdgeInsets.only( left: 20.0, top: 10.0, right: 20.0, bottom: 10.0),
          child: Column(
            children: <Widget>[
              Text('Please confirm your password below'),
              Consumer<Fav>(builder: (context, fav, _) {
                return TextFormField(
                  decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Password',
                      errorStyle: TextStyle(),
                      errorText:
                      Provider.of<Fav>(context, listen: false).is_match
                          ? null
                          : 'Passwords must match'),
                  onChanged: (String str2) {
                    _password_2 = str2;
                  },
                );
              }),
              Consumer<Fav>(builder: (context, fav, _) {
                return Container(
                  child: ElevatedButton(
                    child: const Text('Confirm'),
                    onPressed: confirm_sign_up,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _do_login() async {
    Provider.of<Fav>(context, listen: false).loading();

    bool x = await auth.signIn(context, _email_string, _pssword_string);
    if (x) {
      List<QueryDocumentSnapshot> cloud_saved = (await FirebaseFirestore
              .instance
              .collection("users")
              .doc(FirebaseAuth.instance.currentUser.uid.toString())
              .collection("favorites")
              .get())
          .docs;
      var cloud_sugg = cloud_saved.map((line) => WordPair(
          line.data().entries.first.value.toString(),
          line.data().entries.last.value.toString()));

      Provider.of<Fav>(context, listen: false).saved.forEach((line) async {
        var alreadySaved2 = cloud_sugg.contains(line);

        if (alreadySaved2 != true) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(FirebaseAuth.instance.currentUser.uid.toString())
              .collection("favorites")
              .doc(line.toString())
              .set({"first": line.first, "second": line.second});
        }
      });

      List<QueryDocumentSnapshot> cloud_saved2 = (await FirebaseFirestore
              .instance
              .collection("users")
              .doc(FirebaseAuth.instance.currentUser.uid.toString())
              .collection("favorites")
              .get())
          .docs;
      var cloud_sugg2 = cloud_saved2.map((line) => WordPair(
          line.data().entries.first.value.toString(),
          line.data().entries.last.value.toString()));

      Provider.of<Fav>(context, listen: false).removeAll();
      Provider.of<Fav>(context, listen: false).addAll(cloud_sugg2);

      Provider.of<Fav>(context, listen: false).the_img(auth.user.photoURL);
      if (auth.user.photoURL != null) {
        Provider.of<Fav>(context, listen: false).ex_img();
      }
      Navigator.pop(context);
      login_ok();
    }
    Provider.of<Fav>(context, listen: false).end_loading();
  }

  Widget _loginFields() {
    return Container(
        alignment: FractionalOffset.center,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Text("Welcome to Startup Names Generator, please log in below"),
            TextFormField(
              decoration: InputDecoration(
                  border: UnderlineInputBorder(), labelText: 'Email'),
              onChanged: (String str1) {
                _email_string = str1;
              },
            ),
            TextFormField(
              decoration: InputDecoration(
                  border: UnderlineInputBorder(), labelText: 'Password'),
              onChanged: (String str2) {
                _pssword_string = str2;
              },
            ),
            Consumer<Fav>(builder: (context, fav, _) {
              return Provider.of<Fav>(context, listen: false).is_loading
                  ? Center(child: CircularProgressIndicator())
                  : Container(
                      child: Column(
                        children: <Widget>[
                          Container(
                              width: double.infinity,
                              padding: EdgeInsets.only(top: 20.0),
                              child: FlatButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32.0),
                                ),
                                onPressed: _do_login,
                                color: Colors.red,
                                child: Text('Log in',
                                    style: TextStyle(color: Colors.white)),
                              )),
                          Container(
                              width: double.infinity,
                              child: FlatButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32.0),
                                ),
                                onPressed: () => doo_sign_up(context),
                                color: Colors.grey,
                                child: Text('New user? Click to sign up',
                                    style: TextStyle(color: Colors.white)),
                              )),
                        ],
                      ),
                    );
            }),
          ],
        ));
  }

  void login_ok() {
    setState(() {
      is_loggedin = true;
    });
  }

  void _login() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // NEW lines from here...
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Login'),
              centerTitle: true,
            ),
            body: _loginFields(),
          );
        },
      ),
    );
  }

  void login_out_ok() {
    setState(() {
      is_loggedin = false;
    });
  }

  void _logout() {
    auth.signOut();
    Provider.of<Fav>(context, listen: false).removeAll();
    Provider.of<Fav>(context, listen: false).not_ex_img();

    login_out_ok();
  }

  Widget goo() {
    return auth.isAuthenticated ? _snapp() : _buildSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Startup Name Generator'),
        actions: [
          IconButton(icon: Icon(Icons.favorite), onPressed: _pushSaved),
          IconButton(
              icon: auth.isAuthenticated
                  ? Icon(Icons.exit_to_app)
                  : Icon(Icons.login),
              onPressed: auth.isAuthenticated ? _logout : _login),
        ],
      ),
      body: goo(),
    );
  }

  void _change_avatar() async {
    String the_email = auth.user.email;
    PickedFile image = await ImagePicker().getImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      Provider.of<Fav>(context, listen: false).not_ex_img();
      final taskSnapshot = await FirebaseStorage.instance
          .ref()
          .child("user/$the_email/img")
          .putFile(File(image.path))
          .whenComplete(() => null);
      String new_url = await taskSnapshot.ref.getDownloadURL();
      await auth.update_photo_url(new_url);
      Provider.of<Fav>(context, listen: false).img = new_url;
      Provider.of<Fav>(context, listen: false).ex_img();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(snackBar_img);
    }
  }

  SnappingSheetController _snappingSheetController;
  @override
  void initState() {
    _snappingSheetController = SnappingSheetController();
    super.initState();
  }

  Widget _snapp() {
    return Scaffold(
      body: SnappingSheet(
        controller: _snappingSheetController,
        snappingPositions: [
          SnappingPosition.factor(
            positionFactor: 0.0,
            grabbingContentOffset: GrabbingContentOffset.top,
          ),
          SnappingPosition.pixels(
            positionPixels: 150,
          ),
        ],
        child: _buildSuggestions(),
        grabbingHeight: 60,
        grabbing: Container(
          padding: const EdgeInsets.all(20.0),
          color: Colors.grey,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Container(
                  child: Text("Welcome back, " + auth.user.email,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.black)),
                ),
              ),
              Container(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      _snappingSheetController.setSnappingSheetPosition(150);
                    },
                    child: Icon(
                      Icons.expand_less,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        sheetBelow: SnappingSheetContent(
          sizeBehavior: SheetSizeStatic(height: 150),
          draggable: true,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Consumer<Fav>(builder: (context, fav, _) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                        width: 60.0,
                        height: 60.0,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image:
                                Provider.of<Fav>(context, listen: false).if_img
                                    ? DecorationImage(
                                        fit: BoxFit.fill,
                                        image: NetworkImage(Provider.of<Fav>(
                                                    context,
                                                    listen: false)
                                                .if_img
                                            ? Provider.of<Fav>(context,
                                                    listen: false)
                                                .img
                                            : 'https://via.placeholder.com/150'),
                                      )
                                    : null)),
                  );
                }),
                Container(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      children: [
                        Flexible(
                          child: Text(
                            auth.user.email,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                        FlatButton(
                          onPressed: _change_avatar,
                          color: Colors.blueGrey,
                          child: Text('Change avatar',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        // The itemBuilder callback is called once per suggested
        // word pairing, and places each suggestion into a ListTile
        // row. For even rows, the function adds a ListTile row for
        // the word pairing. For odd rows, the function adds a
        // Divider widget to visually separate the entries. Note that
        // the divider may be difficult to see on smaller devices.
        itemBuilder: (BuildContext _context, int i) {
          // Add a one-pixel-high divider widget before each row
          // in the ListView.
          if (i.isOdd) {
            return Divider();
          }

          // The syntax "i ~/ 2" divides i by 2 and returns an
          // integer result.
          // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
          // This calculates the actual number of word pairings
          // in the ListView,minus the divider widgets.
          final int index = i ~/ 2;
          // If you've reached the end of the available word
          // pairings...
          if (index >= _suggestions.length) {
            // ...then generate 10 more and add them to the
            // suggestions list.
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        });
  }

  Widget _buildRow(WordPair pair) {
    return Consumer<Fav>(
      builder: (context, fav, _) {
        // final alreadySaved = _saved.contains(pair);
        final alreadySaved =
            Provider.of<Fav>(context, listen: false).saved.contains(pair);
        return ListTile(
          title: Text(
            pair.asPascalCase,
            style: _biggerFont,
          ),
          trailing: Icon(
            alreadySaved ? Icons.favorite : Icons.favorite_border,
            color: alreadySaved ? Colors.red : null,
          ),
          onTap: () async {
            if (alreadySaved) {
              Provider.of<Fav>(context, listen: false).remove(pair);
              if (auth.isAuthenticated) {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(FirebaseAuth.instance.currentUser.uid.toString())
                    .collection("favorites")
                    .doc(pair.toString())
                    .delete();
              }
            } else {
              Provider.of<Fav>(context, listen: false).add(pair);

              if (auth.isAuthenticated) {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(FirebaseAuth.instance.currentUser.uid.toString())
                    .collection("favorites")
                    .doc(pair.toString())
                    .set({"first": pair.first, "second": pair.second});
              }
            }
          },
        );
      },
    );
  }
}
