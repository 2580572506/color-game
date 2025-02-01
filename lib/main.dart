import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(ColorMatchGame());
}

class ColorMatchGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // 游戏状态
  Color targetColor = Colors.blue;
  List<Color> colors = [];
  List<ShapeType> shapes = [];
  int score = 0;
  int timeLeft = 30;
  int combo = 0;
  int highScore = 0;
  bool isGameActive = true;
  bool _isPressed = false;

  // 音效播放器
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioCache _audioCache = AudioCache(prefix: 'assets/sounds/');

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _generateNewColors();
    _startTimer();
    _playBackgroundMusic();
  }

  // 加载最高分
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => highScore = prefs.getInt('highScore') ?? 0);
  }

  // 播放背景音乐
  void _playBackgroundMusic() async {
    await _audioCache.play('background.mp3', volume: 0.5, loop: true);
  }

  // 生成颜色和形状
  void _generateNewColors() {
    final random = Random();
    colors = List.generate(9, (_) => _randomColor());
    shapes = List.generate(9, (_) => ShapeType.values[random.nextInt(3)]);
    targetColor = colors[random.nextInt(9)];
  }

  Color _randomColor() => Color.fromARGB(255, Random().nextInt(256), Random().nextInt(256), Random().nextInt(256));

  // 处理点击
  void _handleColorTap(Color tappedColor, int index) async {
    if (!isGameActive) return;

    await _audioCache.play('click.mp3'); // 点击音效

    setState(() {
      if (tappedColor == targetColor) {
        score += 10;
        combo += 1;
        if (combo % 3 == 0) score += 15; // 连击奖励
        Vibration.vibrate(duration: 50);
        _audioCache.play('success.mp3');
        _generateNewColors();
      } else {
        score = max(0, score - 5); // 错误扣分（不低于0）
        combo = 0;
        Vibration.vibrate(pattern: [100, 50, 100]);
      }
    });
  }

  // 其他方法（倒计时、游戏结束等）保持之前逻辑，添加形状绘制...

  // 构建形状
  Widget _buildShape(Color color, ShapeType type) {
    switch (type) {
      case ShapeType.circle:
        return Container(decoration: BoxDecoration(color: color, shape: BoxShape.circle));
      case ShapeType.triangle:
        return CustomPaint(painter: TrianglePainter(color));
      default:
        return Container(color: color);
    }
  }

  // 游戏主界面
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final squareSize = (screenWidth - 32) / 3;

    return Scaffold(
      body: Column(
        children: [
          // 分数显示部分...
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              children: List.generate(9, (index) => GestureDetector(
                onTap: () => _handleColorTap(colors[index], index),
                child: _AnimatedShape(
                  color: colors[index],
                  shape: shapes[index],
                  size: squareSize,
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

// 形状类型枚举
enum ShapeType { square, circle, triangle }

// 三角形绘制
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width/2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 带动画的形状组件
class _AnimatedShape extends StatefulWidget {
  final Color color;
  final ShapeType shape;
  final double size;

  const _AnimatedShape({required this.color, required this.shape, required this.size});

  @override
  __AnimatedShapeState createState() => __AnimatedShapeState();
}

class __AnimatedShapeState extends State<_AnimatedShape> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: 1 - _controller.value * 0.1,
        child: Container(
          width: widget.size,
          height: widget.size,
          margin: EdgeInsets.all(8),
          child: _buildShape(),
        ),
      ),
    );
  }

  Widget _buildShape() {
    // 根据形状类型返回不同组件...
  }
}
