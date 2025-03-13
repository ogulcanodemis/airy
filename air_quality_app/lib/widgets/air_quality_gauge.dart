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
        return SizedBox(
          width: widget.size,
          height: widget.size,
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
                      color: _getCategoryColor(widget.category),
                    ),
                  ),
                  Text(
                    'AQI',
                    style: TextStyle(
                      fontSize: widget.size * 0.08,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: widget.size * 0.05),
                  Text(
                    widget.category,
                    style: TextStyle(
                      fontSize: widget.size * 0.07,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(widget.category),
                    ),
                  ),
                ],
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
    final strokeWidth = size.width * 0.05;
    
    // Arka plan daire
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
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
        AppStyles.airQualityGood,
        AppStyles.airQualityModerate,
        AppStyles.airQualitySensitive,
        AppStyles.airQualityUnhealthy,
        AppStyles.airQualityVeryUnhealthy,
        AppStyles.airQualityHazardous,
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
      final needleEnd = Offset(
        center.dx + needleLength * math.cos(needleAngle),
        center.dy + needleLength * math.sin(needleAngle),
      );
      
      final needlePaint = Paint()
        ..color = _getCategoryColor(category)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.3
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(center, needleEnd, needlePaint);
      
      // İbre merkez noktası
      final centerDotPaint = Paint()
        ..color = _getCategoryColor(category)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, strokeWidth * 0.4, centerDotPaint);
    }
    
    // Ölçek çizgileri
    final scalePaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.005;
    
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
      
      canvas.drawLine(scaleStart, scaleEnd, scalePaint);
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