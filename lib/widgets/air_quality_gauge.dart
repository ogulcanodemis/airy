import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../styles/app_styles.dart';

class AirQualityGauge extends StatefulWidget {
  final double aqi;
  final String category;
  final double size;
  final bool animate;

  const AirQualityGauge({
    Key? key,
    required this.aqi,
    required this.category,
    this.size = 200.0,
    this.animate = true,
  }) : super(key: key);

  @override
  State<AirQualityGauge> createState() => _AirQualityGaugeState();
}

class _AirQualityGaugeState extends State<AirQualityGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.05),
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: CustomPaint(
              painter: _AirQualityGaugePainter(
                aqi: widget.aqi * _animation.value,
                category: widget.category,
                animationValue: _animation.value,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (widget.aqi * _animation.value).toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: widget.size * 0.18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 12.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 2),
                          ),
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'AQI',
                      style: TextStyle(
                        fontSize: widget.size * 0.08,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 12.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 2),
                          ),
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: widget.size * 0.05),
                    Text(
                      widget.category,
                      style: TextStyle(
                        fontSize: widget.size * 0.07,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 12.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 2),
                          ),
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'İyi':
        return AppStyles.airQualityGood;
      case 'Orta':
        return AppStyles.airQualityModerate;
      case 'Hassas Gruplar İçin Sağlıksız':
        return AppStyles.airQualitySensitive;
      case 'Sağlıksız':
        return AppStyles.airQualityUnhealthy;
      case 'Çok Sağlıksız':
        return AppStyles.airQualityVeryUnhealthy;
      case 'Tehlikeli':
        return AppStyles.airQualityHazardous;
      default:
        return Colors.grey;
    }
  }
}

class _AirQualityGaugePainter extends CustomPainter {
  final double aqi;
  final String category;
  final double animationValue;

  _AirQualityGaugePainter({
    required this.aqi,
    required this.category,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final strokeWidth = size.width * 0.08;
    
    // Dış çerçeve
    final outerCirclePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(center, radius + strokeWidth + 4, outerCirclePaint);
    
    // Arka plan daire
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.5) // Opaklığı artırdım
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      backgroundPaint,
    );
    
    // AQI değeri için daire
    final double sweepAngle = math.min(aqi / 500, 1.0) * math.pi * 1.5;
    
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: math.pi * 0.75,
      endAngle: math.pi * 2.25,
      colors: [
        const Color(0xFF82E0F9), // Açık mavi
        const Color(0xFF8BE246), // Yeşil
        const Color(0xFFF9CC3E), // Sarı
        const Color(0xFFFF9800), // Turuncu
        const Color(0xFFFF5722), // Kırmızı
        const Color(0xFF9C27B0), // Mor
      ],
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );
    
    final foregroundPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    // Gradient dairenin etrafına siyah kenar çizgisi
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      sweepAngle,
      false,
      borderPaint,
    );
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      sweepAngle,
      false,
      foregroundPaint,
    );
    
    // İbre
    if (animationValue > 0) {
      final needleLength = radius + strokeWidth / 2;
      final needleAngle = math.pi * 0.75 + sweepAngle;
      
      // İbre gölgesi
      final needleShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.5
        ..strokeCap = StrokeCap.round;
      
      final needleShadowEnd = Offset(
        center.dx + needleLength * math.cos(needleAngle) + 2,
        center.dy + needleLength * math.sin(needleAngle) + 2,
      );
      
      canvas.drawLine(
        Offset(center.dx + 1, center.dy + 1), 
        needleShadowEnd, 
        needleShadowPaint
      );
      
      // İbre
      final needleEnd = Offset(
        center.dx + needleLength * math.cos(needleAngle),
        center.dy + needleLength * math.sin(needleAngle),
      );
      
      final needlePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.4
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(center, needleEnd, needlePaint);
      
      // İbre merkez noktası gölgesi
      final centerDotShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(center.dx + 1, center.dy + 1), 
        strokeWidth * 0.6, 
        centerDotShadowPaint
      );
      
      // İbre merkez noktası
      final centerDotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, strokeWidth * 0.5, centerDotPaint);
    }
    
    // Ölçek çizgileri
    final scalePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.015;
    
    for (int i = 0; i <= 5; i++) {
      final scaleAngle = math.pi * 0.75 + (math.pi * 1.5 / 5) * i;
      final scaleStart = Offset(
        center.dx + (radius - strokeWidth / 2) * math.cos(scaleAngle),
        center.dy + (radius - strokeWidth / 2) * math.sin(scaleAngle),
      );
      final scaleEnd = Offset(
        center.dx + (radius + strokeWidth / 2) * math.cos(scaleAngle),
        center.dy + (radius + strokeWidth / 2) * math.sin(scaleAngle),
      );
      
      // Ölçek çizgisi gölgesi
      final scaleShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.015;
      
      canvas.drawLine(
        Offset(scaleStart.dx + 1, scaleStart.dy + 1),
        Offset(scaleEnd.dx + 1, scaleEnd.dy + 1),
        scaleShadowPaint
      );
      
      canvas.drawLine(scaleStart, scaleEnd, scalePaint);
    }
    
    // AQI değer etiketleri
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: size.width * 0.045,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          blurRadius: 4.0,
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(1, 1),
        ),
      ],
    );
    
    final values = ['0', '100', '200', '300', '400', '500'];
    for (int i = 0; i <= 5; i++) {
      final scaleAngle = math.pi * 0.75 + (math.pi * 1.5 / 5) * i;
      final textRadius = radius + strokeWidth * 1.3; // Biraz daha dışarıda
      final textPosition = Offset(
        center.dx + textRadius * math.cos(scaleAngle),
        center.dy + textRadius * math.sin(scaleAngle),
      );
      
      final textSpan = TextSpan(
        text: values[i],
        style: textStyle,
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(
          textPosition.dx - textPainter.width / 2,
          textPosition.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_AirQualityGaugePainter oldDelegate) => 
      aqi != oldDelegate.aqi || 
      category != oldDelegate.category ||
      animationValue != oldDelegate.animationValue;
      
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'İyi':
        return AppStyles.airQualityGood;
      case 'Orta':
        return AppStyles.airQualityModerate;
      case 'Hassas Gruplar İçin Sağlıksız':
        return AppStyles.airQualitySensitive;
      case 'Sağlıksız':
        return AppStyles.airQualityUnhealthy;
      case 'Çok Sağlıksız':
        return AppStyles.airQualityVeryUnhealthy;
      case 'Tehlikeli':
        return AppStyles.airQualityHazardous;
      default:
        return Colors.grey;
    }
  }
} 