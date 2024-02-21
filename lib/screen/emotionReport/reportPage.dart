import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widget/design/settingColor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../service/gree_service.dart';

import '../../widget/design/sharedController.dart';
import '../../provider/pageNavi.dart';
import '../../service/user_service.dart';
import 'package:provider/provider.dart';
import 'package:projectfront/widget/design/basicButtons.dart';
import '../../models/user_model.dart';

class ReportPage extends StatefulWidget {
  final int? greeId;
  const ReportPage({Key? key, this.greeId}) : super(key: key);
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int touchedIndex = -1;
  Map<String, List<String>> emotions = {}; // 초기 상태는 비어있음
  Map<String, String> urls = {};


  @override
  void initState() {
    super.initState();
    fetchEmotionData();
  }


  Future<void> fetchEmotionData() async {
    try {
      List<String> sentences = await ApiServiceGree.fetchSentences(widget.greeId!);
      var report = await ApiServiceGree.makeEmotionReport(sentences,widget.greeId!);
      setState(() {
        emotions = report['emotions'].map((emotion, sentences) =>
            MapEntry(emotion, List<String>.from(sentences))).cast<String,
            List<String>>();
        urls = report['urls'].cast<String, String>();
      });
    } catch (e) {
      print('Error fetching emotion data: $e');
    }
  }


  final Map<String, Color> emotionColor = {
    '기쁨': Colors.blue[400]!,
    '당황': Colors.orange[400]!,
    '분노': Colors.red[400]!,
    '불안': Colors.teal[400]!,
    '상처': Colors.purple[400]!,
    '슬픔': Colors.green[400]!,
  };

  Widget buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: emotionColor.keys.map((emotion) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: emotionColor[emotion], // 수정된 부분: 각 감정에 대한 정확한 색상을 사용
                ),
              ),
              SizedBox(width: 2),
              Text(emotion),
            ],
          ),
        );
      }).toList(),
    );
  }


  List<PieChartSectionData> showingSections() {
    int totalSentences = emotions.values.fold(0, (previous, element) => previous + element.length);
    if (totalSentences == 0) {
      return [];
    }

    List<PieChartSectionData> sections = [];
    emotions.forEach((key, sentences) {
      final bool isTouched = emotions.keys.toList().indexOf(key) == touchedIndex;
      final double fontSize = isTouched ? 17 : 15;
      final double radius = isTouched ? 60 : 50;
      final double percentage = sentences.length / totalSentences * 100;

      // 디버깅을 위한 로그 출력
      print('Emotion: $key, Is Touched: $isTouched, Percentage: $percentage');

      if (percentage > 0) {
        String titleText = isTouched ? '$key\n${percentage.toStringAsFixed(1)}%' : key;
        // 타이틀 설정 전에 로그 출력
        print('Title Text: $titleText');

        sections.add(PieChartSectionData(
          color: emotionColor[key],
          value: percentage,
          title: titleText,
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xffffffff),
          ),
        ));
      }
    });

    return sections;
  }




  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          setState(() {
            touchedIndex = -1; // 차트 바깥을 누르면 선택 해제
          });
        },
        child : Scaffold(
          backgroundColor: colorMainBG_greedot,
          body: SafeArea(
            child: Stack(
              children: <Widget>[
                // Align( // 필요한가? -> 자동 리포트 업데이트 되면 되지 않을까
                //   alignment: Alignment.topCenter, // 화면의 상단 가운데 정렬
                //   child : EleButton_greedot(
                //     buttonText: "지금까지의 리포트 생성하기",
                //     fontSize: 11,
                //     width: 140, height: 35,
                //     padding: EdgeInsets.symmetric(horizontal: 2),
                //   ),
                // ),
                Align(
                  alignment: Alignment.topCenter, // 화면의 상단 가운데 정렬
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40), // 상단 여백 조정
                    child: Text('< 차트를 클릭하면 대화 로그가 보여요! >'),
                  ),
                ),
                Positioned(
                  top: 20,
                  // 상단에 위치
                  left: 0,
                  right: 0,
                  height: MediaQuery
                      .of(context)
                      .size
                      .height / 2,
                  child: buildChartAndImageRow(),
                ),
                Positioned(
                  top: MediaQuery
                      .of(context)
                      .size
                      .height / 2 - 35, // 파이 차트 바로 아래에 위치
                  left: 0,
                  right: 0,
                  child: buildLegend(), // 범례를 빌드하는 함수를 호출
                ),
                if (touchedIndex != -1) // touchedIndex가 -1이 아닐 때만 문장을 표시
                  Positioned(
                    bottom: 25,
                    // 하단에 위치
                    left: 10,
                    right: 10,
                    height: 200,
                    child: buildScrollableEmotionSentences(
                      emotions.keys.elementAt(touchedIndex),
                    ),
                  ),
              ],
            ),
          ),
        )
    );
  }

  Widget buildChartAndImageRow() {
    return Container(
      height: MediaQuery.of(context).size.height / 3,
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (event is FlTapUpEvent && pieTouchResponse != null &&
                          pieTouchResponse.touchedSection != null) {
                        int currentIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        // 디버깅 로그 추가: 현재 터치된 섹션 인덱스
                        print('Current touched section index: $currentIndex');
                        List<String> displayedEmotions = emotions.keys.where((key) => emotions[key]!.isNotEmpty).toList();
                        String touchedEmotion = displayedEmotions[currentIndex];
                        // 디버깅 로그 추가: 현재 터치된 감정
                        print('Touched emotion: $touchedEmotion');
                        setState(() {
                          touchedIndex = emotions.keys.toList().indexOf(touchedEmotion);
                          // 디버깅 로그 추가: 설정된 touchedIndex
                          print('Set touchedIndex: $touchedIndex');
                        });
                      }
                    },
                  ),
                )

            ),
          ),
          if (touchedIndex != -1 && urls.isNotEmpty) // 선택된 감정이 있고, urls 맵이 비어있지 않을 때
            Expanded(
              child: Image.network(
                urls[emotions.keys.elementAt(touchedIndex)] ?? '', // null 대체 연산자를 사용하여 urls 맵에 해당 키가 없을 경우 빈 문자열 반환
                width: 100.0,
                errorBuilder: (context, error, stackTrace) {
                  // 이미지 로드 실패 시 대체 이미지 표시
                  return Image.asset('assets/images/greegirl_3.png', width: 100.0);
                },
              ),
            ),
        ],
      ),
    );
  }



  Widget buildScrollableEmotionSentences(String emotion) {
    // 특정 감정에 대한 모든 문장을 스크롤 가능한 텍스트로 표시하는 메서드 구현
    List<String>? sentencesList = emotions[emotion];
    String allSentences = sentencesList != null ? sentencesList.join('\n\n') : 'No sentences found for this emotion.';
    return Container(
      height: 200,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorFilling_greedot,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[400]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Text(
          allSentences,
          style: TextStyle(fontSize: 13.0),
        ),
      ),
    );
  }
}