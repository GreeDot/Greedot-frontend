import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../structure/structure.dart';
import '../../structure/structureInit.dart';
import '../../widget/design/basicButtons.dart';

import './riggingRoot.dart';

//global varchr
double radiusDragBut = 15.0;

class SkeletonCanvas extends StatefulWidget {
  @override
  _SkeletonCanvasState createState() => _SkeletonCanvasState();
}

class _SkeletonCanvasState extends State<SkeletonCanvas> {
  List<Offset> positions = List.generate(
      skeletonInfo.length, (index) => Offset(100.0 * (index + 1), 100.0));

  double offsetX = 0.0;
  double offsetY = 0.0;
  double preX = 0.0;
  double preY = 0.0;

  bool trigger = false;
  bool _initState = true;

  late double moveX, moveY, newPosX, newPosY;

  double? imageWidth = Image.file(File(importedImage!.path)).width;
  double? imageHeight = Image.file(File(importedImage!.path)).height;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red), // 테두리 추가
              color: Colors.blue.shade100, // 배경 색상 추가
            ),
            child: _buildPhotoArea(importedImage),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: LinePainter(positions),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  EleButton_greedot(
                    height: 40, // 높이 설정
                    width: 100, // 너비 설정
                    additionalFunc: () {
                      for (var node in skeletonInfo) {
                        print(
                            '${node.fromJoint} = (${node.point.dx}, ${node.point.dy})');
                      }
                    },
                    buttonText: '좌표 출력',
                  ),
                  SizedBox(height: 10),
                  EleButton_greedot(
                    height: 40,
                    width: 100,
                    bgColor: Colors.blue,
                    additionalFunc: () async {
                      await writeNodesToYaml(
                          skeletonInfo, imageWidth!, imageHeight!);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Yaml 파일 저장됨')));
                    },
                    buttonText: 'Yaml 저장',
                  ),
                  SizedBox(height: 10),
                  EleButton_greedot(
                    height: 40,
                    width: 100,
                    bgColor: Colors.blue,
                    gotoScene: () => SkeletonCanvas(),
                    buttonText: '홈으로 가기',
                  ),
                ],
              ),
            ),
          ),
          // Draggable buttons
          ...List.generate(skeletonInfo.length, (index) {
            //List.generate 버튼 수 만큼의 리스트를 생성
            return Positioned(
              // Positioned 위젯 반환
              left: skeletonInfo[index].point.dx,
              top: skeletonInfo[index]
                  .point
                  .dy, // 버튼 좌표 skeletonInfo 안의 point로 설정
              child: Draggable(
                // 드래그 할 수 있는 요소 생성
                feedback: _buildDraggableCircle(index), // 드래그 중 보여지는 위젯을 정의
                onDragStarted:
                    () {}, // onDragStarted 드래그 시작시 실행할 함수를 정의 여기선 정의 안 함
                onDragUpdate: (updateDragDetails) {
                  // 드래그가 업데이트될 때마다 호출
                  if (_initState) {
                    moveX = updateDragDetails.localPosition.dx -
                        skeletonInfo[index].point.dx;
                    moveY = updateDragDetails.localPosition.dy -
                        skeletonInfo[index]
                            .point
                            .dy; // moveX, moveY 시작위치와 현재위치의 차이 구함
                    _initState = false;
                  }
                  newPosX = updateDragDetails.localPosition.dx - moveX;
                  newPosY =
                      updateDragDetails.localPosition.dy - moveY; // 새로운 위치 계산
                  // positions[index] = Offset(newPosX, newPosY);
                  if (newPosX >= 0 &&
                      newPosX <= imageWidth! &&
                      newPosY >= 0 &&
                      newPosY <= imageHeight!)
                    _onDrag(index, Offset(newPosX, newPosY));
                },
                onDragEnd: (endDragDetails) {
                  _initState = true;
                },
                child: _buildDraggableCircle(index),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDraggableCircle(int index) {
    return Tooltip(
      message: skeletonInfo[index].fromJoint, // 마우스 클릭 시 설명
      child: CircleAvatar(radius: radiusDragBut, child: Text('${index + 1}')),
    );
  }

  void _onDrag(int index, Offset offset) {
    // 드래그 위치가 이미지 영역 내에 있는지 확인
    bool withinWidthBounds = offset.dx >= 0 && offset.dx <= imageWidth!;
    bool withinHeightBounds = offset.dy >= 0 && offset.dy <= imageHeight!;

    // 조건을 만족하면 상태 업데이트
    if (withinWidthBounds && withinHeightBounds) {
      setState(() {
        skeletonInfo[index].point = offset;
      });
    }
  }

  Widget _buildPhotoArea(image) {
    return image != null
        ? Container(
            width: 400,
            height: 400,
            child: Image.file(File(image!.path)), //가져온 이미지를 화면에 띄워주는 코드
          )
        : Container(
            width: 400,
            height: 400,
            color: Colors.grey,
          );
  }
}

class LinePainter extends CustomPainter {
  final List<Offset> positions;

  LinePainter(this.positions);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    for (Node fromJ in skeletonInfo) {
      //Node 객체들이 들어 있으며, 각 Node는 연결점을 나타냄
      String currentJoint = fromJ.fromJoint;
      for (Node toJ in skeletonInfo) {
        String? connectedJoint = toJ.toJoint;
        if (currentJoint == connectedJoint) {
          Offset coord1 = Offset(
              fromJ.point.dx + radiusDragBut, fromJ.point.dy + radiusDragBut);
          Offset coord2 = Offset(
              toJ.point.dx + radiusDragBut, toJ.point.dy + radiusDragBut);
          canvas.drawLine(coord1, coord2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
