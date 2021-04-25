import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';

class Fav extends ChangeNotifier {
  Fav({required this.saved});
  List<WordPair> saved = [];
  var is_loading = false;
  var is_match = true;
  var if_img = false;
  var img = null;

  void add(WordPair pair) {
    saved.add(pair);
    notifyListeners();
  }

  void remove(WordPair pair) {
    saved.remove(pair);
    notifyListeners();
  }

  void removeAll() {
    saved.clear();
    notifyListeners();
  }

  void addAll(all) {
    saved.addAll(all);
    notifyListeners();
  }

  void loading(){
    is_loading =true;
    notifyListeners();
  }

  void end_loading(){
    is_loading =false;
    notifyListeners();
  }

  void match_true(){
    is_match =true;
    notifyListeners();
  }

  void match_false(){
    is_match =false;
    notifyListeners();
  }

  void ex_img(){
    if_img =true;
    notifyListeners();
  }

  void not_ex_img(){
    if_img =false;
    notifyListeners();
  }

  void the_img(imgg){
    img = imgg;
    notifyListeners();
  }

}
