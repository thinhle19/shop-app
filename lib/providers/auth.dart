import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/secret/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Auth with ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  Timer? _authTimer;

  bool get isAuth {
    //if toke had and not outdated
    return token != null;
  }

  String? get userId {
    return _userId;
  }

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=${Constant.APIKey}");
    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            "email": email,
            "password": password,
            "returnSecureToken": true,
          },
        ),
      );
      final responseData = json.decode(response.body);
      if (responseData["error"] != null) {
        throw HttpException(responseData["error"]["message"]);
      }
      _token = responseData["idToken"];
      print("token: $_token");
      _userId = responseData["localId"];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(responseData["expiresIn"]),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      print("got instance");
      final userData = json.encode({
        "token": _token,
        "userId": _userId,
        "expiryDate": _expiryDate!.toIso8601String(),
      });
      prefs.setString("userData", userData);
      _autoLogout();
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<bool> tryAutoLogin() async {
    print("tried");
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey("userData")) {
      print("container");
      return false;
    } else {
      print("not contained");
      final extractedUserData =
          json.decode(prefs.getString("userData")!) as Map<String, dynamic>;
      if (extractedUserData != null) {
        final expiryDate =
            DateTime.parse(extractedUserData["expiryDate"] as String);
        if (expiryDate.isBefore(DateTime.now())) {
          return false;
        }
        _token = extractedUserData["token"] as String;
        _userId = extractedUserData["userId"] as String;
        _expiryDate = expiryDate;
        notifyListeners();
        print("called");
        _autoLogout();
        return true;
      } else {
        return false;
      }
    }
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, "signUp");
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, "signInWithPassword");
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    final timeToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }
}
