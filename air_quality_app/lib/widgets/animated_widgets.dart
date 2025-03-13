import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:math' show Random;

// Dalgalı animasyon widget'ı
class WaveAnimation extends StatefulWidget {
  final Widget child;
  final Color color;
  final double height;
  final double speed;

  const WaveAnimation({
    Key? key,
    required this.child,
    required this.color,
    this.height = 20.0,
    this.speed = 1.0,
  }) : super(key: key);

  @override
  State<WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2000 / widget.speed).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: WavePainter(
                animation: _controller,
                color: widget.color,
                height: widget.height,
              ),
              child: widget.child,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double height;

  WavePainter({
    required this.animation,
    required this.color,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    final y = size.height / 2;

    path.moveTo(0, y);
    for (var i = 0.0; i < size.width; i++) {
      path.lineTo(
        i,
        y + math.sin((i / size.width * 2 * math.pi) + (animation.value * 2 * math.pi)) * height,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}

// Nefes alan animasyon widget'ı
class BreathingAnimation extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const BreathingAnimation({
    Key? key,
    required this.child,
    this.minScale = 0.9,
    this.maxScale = 1.1,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<BreathingAnimation> createState() => _BreathingAnimationState();
}

class _BreathingAnimationState extends State<BreathingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
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
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

// Yüzen animasyon widget'ı
class FloatingAnimation extends StatefulWidget {
  final Widget child;
  final double height;
  final Duration duration;

  const FloatingAnimation({
    Key? key,
    required this.child,
    this.height = 10.0,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<FloatingAnimation> createState() => _FloatingAnimationState();
}

class _FloatingAnimationState extends State<FloatingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -widget.height / 2,
      end: widget.height / 2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
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
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: widget.child,
        );
      },
    );
  }
}

// Parçacık animasyonu widget'ı
class ParticleAnimation extends StatefulWidget {
  final Widget child;
  final Color color;
  final int particleCount;

  const ParticleAnimation({
    Key? key,
    required this.child,
    required this.color,
    this.particleCount = 10,
  }) : super(key: key);

  @override
  State<ParticleAnimation> createState() => _ParticleAnimationState();
}

class _ParticleAnimationState extends State<ParticleAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    particles = List.generate(
      widget.particleCount,
      (index) => Particle(
        random: random,
        color: widget.color,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(
                particles: particles,
                animation: _controller,
              ),
              child: widget.child,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double size;
  late double speed;
  late Color color;
  late double opacity;

  Particle({
    required Random random,
    required Color color,
  }) {
    this.color = color;
    reset(random, true);
  }

  void reset(Random random, bool initial) {
    x = random.nextDouble() * 2 - 1;
    y = initial ? (random.nextDouble() * 2 - 1) : -1 - random.nextDouble() * 0.2;
    size = 2 + random.nextDouble() * 4;
    speed = 0.1 + random.nextDouble() * 0.3;
    opacity = 0.1 + random.nextDouble() * 0.4;
  }

  void update(Random random) {
    y += speed;
    if (y > 1) {
      reset(random, false);
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Animation<double> animation;
  final Random random = Random();

  ParticlePainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update(random);
      
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      final position = Offset(
        (particle.x * 0.5 + 0.5) * size.width,
        (particle.y * 0.5 + 0.5) * size.height,
      );
      
      canvas.drawCircle(position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

// Yanıp sönen animasyon widget'ı
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;

  const PulseAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 1),
    this.minOpacity = 0.6,
    this.maxOpacity = 1.0,
  }) : super(key: key);

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
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
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
} 