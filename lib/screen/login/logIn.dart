import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../widget/design/settingColor.dart';
import '../../widget/design/sharedController.dart';
import '../../provider/pageNavi.dart';
import '../../service/user_service.dart';
import 'package:provider/provider.dart';



class LogIn extends StatefulWidget {
  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  Future<void> _login() async {
    final pageNavi = Provider.of<PageNavi>(context, listen: false); 
    final loginModel = LoginModel(
      username: loginEmailController.text,
      password: loginPasswordController.text,
    );
    final response = await ApiService.loginUser(loginModel);
    if (response.statusCode == 200) {
      final token = json.decode(response.body)['access_token'];
      await AuthService.saveToken(token);
      pageNavi.changePage('RiggingRoot');
    }
    else {
      // 로그인 실패 처리
      final responseData = json.decode(response.body);
      final errorMessage = responseData['message'] ?? '로그인에 실패했습니다.';
      _showLoginFailedDialog(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageNavi = Provider.of<PageNavi>(context, listen: false);
    return Scaffold(
      backgroundColor: colorMainBG_greedot,
      // email, password 입력하는 부분을 제외한 화면을 탭하면, 키보드 사라지게 GestureDetector 사용
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(padding: EdgeInsets.only(top: 50)),
              Center(
                child: Image(
                  image: AssetImage('assets/images/gree.png'),
                  width: 200.0,
                ),
              ),
              Form(
                  child: Theme(
                data: ThemeData(
                    primaryColor: Colors.grey,
                    inputDecorationTheme: InputDecorationTheme(
                        labelStyle: TextStyle(
                            color: colorSnackBar_greedot, fontSize: 15.0,fontFamily:'greedot_font'))),
                child: Container(
                    padding: EdgeInsets.all(40.0),
                    child: Builder(builder: (context) {
                      return Column(
                        children: [
                          TextField(
                            controller: loginEmailController,
                            autofocus: true,
                            decoration: InputDecoration(
                                labelText: 'email',
                                hintText: 'example@nate.com',
                                hintStyle: TextStyle(color: Colors.grey,fontFamily:'greedot_font'),
                                icon: Icon(Icons.mail_outline)),
                            style: TextStyle(fontFamily:'greedot_font'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          TextField(
                            controller: loginPasswordController,
                            decoration: InputDecoration(
                                labelText: 'password',
                                icon: Icon(Icons.lock_outline)),
                            keyboardType: TextInputType.text,
                            obscureText: true, // 비밀번호 안보이도록 하는 것
                          ),
                          SizedBox(
                            height: 40.0,
                          ),
                          ButtonTheme(
                              minWidth: 100.0,
                              height: 50.0,
                              child: ElevatedButton(
                                onPressed: _login,
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: colorBig_But_greedot,
                                  size: 35.0,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorBut_greedot,
                                ),
                              )),
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              // 'child'를 추가해야 합니다.
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    pageNavi.changePage('SignupScreen');
                                  },
                                  child: Text(
                                    '회원가입 하기',
                                    style:
                                        TextStyle(color: colorSnackBar_greedot,fontFamily:'greedot_font'),
                                  ),
                                ),
                                Text('|',
                                    style: TextStyle(
                                        color: colorSnackBar_greedot,fontFamily:'greedot_font')),
                                TextButton(
                                  onPressed: () {
                                    pageNavi.changePage('FindPassword');
                                  },
                                  child: Text(
                                    '아이디·비밀번호 찾기',
                                    style:
                                        TextStyle(color: colorSnackBar_greedot,fontFamily:'greedot_font'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      );
                    })),
              ))
            ],
          ),
        ),
      ),
    );
  }
}

void showSnackBar(BuildContext context, Text text) {
  final snackBar = SnackBar(
    content: text,
    backgroundColor: colorSnackBar_greedot,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

void _showLoginFailedDialog(BuildContext context, String errorMessage) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('로그인 실패'),
      content: Text(errorMessage),
      actions: <Widget>[
        TextButton(
          child: Text('확인'),
          onPressed: () {
            Navigator.of(ctx).pop();
          },
        ),
      ],
    ),
  );
}
