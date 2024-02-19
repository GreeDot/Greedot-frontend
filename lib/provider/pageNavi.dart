import 'package:flutter/material.dart';
import '../structure/structure.dart';

class PageData {
  final int? greeId; 
  final String? imageUrl;

  PageData({this.greeId, this.imageUrl});
}

class PageNavi with ChangeNotifier {
  String _currentPageKey = "RiggingRoot";
  PageData? _currentPageData;

  String get currentPageKey => _currentPageKey;
  PageData? get currentPageData => _currentPageData;

  void changePage(String pageKey, {PageData? data}) {
    _currentPageKey = pageKey;
    _currentPageData = data;

    notifyListeners();
  
  }
}