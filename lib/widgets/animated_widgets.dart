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
      ..color = color
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

// Yeni eklenen animasyonlu arka plan widget'ı
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final Color color1;
  final Color color2;
  final int bubbleCount;

  const AnimatedBackground({
    Key? key,
    required this.child,
    this.color1 = const Color(0xFF82E0F9),
    this.color2 = const Color(0xFFF9CC3E),
    this.bubbleCount = 15,
  }) : super(key: key);

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<Offset> _positions;
  late List<double> _sizes;
  late List<Color> _colors;
  late List<bool> _isCircle; // Bazı şekillerin daire, bazılarının yumuşak köşeli kare olması için

  @override
  void initState() {
    super.initState();
    
    final random = math.Random();
    
    // Animasyon kontrolcülerini ve pozisyonları başlat
    _controllers = List.generate(
      widget.bubbleCount,
      (index) => AnimationController(
        duration: Duration(seconds: random.nextInt(10) + 10),
        vsync: this,
      )..repeat(reverse: true),
    );
    
    _animations = _controllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      );
    }).toList();
    
    _positions = List.generate(
      widget.bubbleCount,
      (index) => Offset(
        random.nextDouble(),
        random.nextDouble(),
      ),
    );
    
    _sizes = List.generate(
      widget.bubbleCount,
      (index) => random.nextDouble() * 50 + 20,
    );
    
    _colors = List.generate(
      widget.bubbleCount,
      (index) {
        final ratio = random.nextDouble();
        return Color.lerp(widget.color1, widget.color2, ratio)!.withOpacity(0.15);
      },
    );
    
    _isCircle = List.generate(
      widget.bubbleCount,
      (index) => random.nextBool(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Arka plan rengi
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFFFF), // Beyaz
                Color(0xFFF8FBFF), // Çok açık mavi
                Color(0xFFEDF7FF), // Açık mavi
              ],
            ),
          ),
        ),
        
        // Animasyonlu şekiller
        ...List.generate(widget.bubbleCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              final size = _sizes[index];
              final position = _positions[index];
              
              // Animasyon değerine göre pozisyonu güncelle
              final dx = position.dx * MediaQuery.of(context).size.width;
              final dy = position.dy * MediaQuery.of(context).size.height;
              
              // Animasyon değerine göre hareket
              final offset = Offset(
                dx + 20 * math.sin(_animations[index].value * math.pi * 2),
                dy + 20 * math.cos(_animations[index].value * math.pi * 2),
              );
              
              return Positioned(
                left: offset.dx - size / 2,
                top: offset.dy - size / 2,
                width: size,
                height: size,
                child: Container(
                  decoration: BoxDecoration(
                    shape: _isCircle[index] ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: _isCircle[index] ? null : BorderRadius.circular(size / 4),
                    color: _colors[index],
                    boxShadow: [
                      BoxShadow(
                        color: _colors[index].withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
        
        // İçerik
        widget.child,
      ],
    );
  }
}

// Animasyonlu AppBar
class AnimatedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final Widget? logo;
  final VoidCallback? onTitleTap;
  final bool showSearchButton;
  final VoidCallback? onSearchTap;

  const AnimatedAppBar({
    Key? key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
    this.height = kToolbarHeight + 25,
    this.logo,
    this.onTitleTap,
    this.showSearchButton = false,
    this.onSearchTap,
  }) : super(key: key);

  @override
  State<AnimatedAppBar> createState() => _AnimatedAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(height);
}

class _AnimatedAppBarState extends State<AnimatedAppBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHoveringTitle = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF82E0F9), // Açık mavi
                const Color(0xFF5BBCD9), // Açık mavinin koyu tonu
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Stack(
                children: [
                  // Arka plan animasyonu
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: CustomPaint(
                        painter: BubblePainter(
                          bubbleCount: 10,
                          color: Colors.white,
                          maxRadius: 15,
                        ),
                      ),
                    ),
                  ),
                  
                  // AppBar içeriği
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sol taraf (leading veya logo)
                      if (widget.leading != null)
                        widget.leading!
                      else if (widget.logo != null)
                        _buildTouchableWidget(
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: widget.logo,
                            ),
                          ),
                          padding: const EdgeInsets.all(4.0),
                          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        )
                      else
                        _buildTouchableWidget(
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.air,
                                  color: Color(0xFF82E0F9),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(4.0),
                          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        ),
                      
                      // Başlık
                      Expanded(
                        child: _buildTouchableWidget(
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: widget.foregroundColor ?? Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 2.0,
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: widget.centerTitle ? TextAlign.center : TextAlign.start,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          onTap: widget.onTitleTap,
                          onHover: (isHovering) {
                            setState(() {
                              _isHoveringTitle = isHovering;
                            });
                          },
                        ),
                      ),
                      
                      // Sağ taraf (arama butonu ve actions)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Arama butonu (opsiyonel)
                          if (widget.showSearchButton)
                            _buildTouchableWidget(
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              padding: const EdgeInsets.only(right: 8.0),
                              onTap: widget.onSearchTap,
                            ),
                          
                          // Actions
                          if (widget.actions != null) 
                            ...widget.actions!.map((action) => 
                              _buildTouchableWidget(
                                child: action,
                                padding: const EdgeInsets.only(left: 4.0),
                              )
                            ).toList(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Dokunulabilir widget oluşturma yardımcı metodu
  Widget _buildTouchableWidget({
    required Widget child,
    required EdgeInsets padding,
    VoidCallback? onTap,
    Function(bool)? onHover,
  }) {
    return Padding(
      padding: padding,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: onHover != null ? (_) => onHover(true) : null,
        onExit: onHover != null ? (_) => onHover(false) : null,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: child,
        ),
      ),
    );
  }
}

// Kabarcık çizici
class BubblePainter extends CustomPainter {
  final int bubbleCount;
  final Color color;
  final double maxRadius;
  final List<Bubble> _bubbles = [];

  BubblePainter({
    required this.bubbleCount,
    required this.color,
    this.maxRadius = 10,
  }) {
    // Kabarcıkları oluştur
    for (int i = 0; i < bubbleCount; i++) {
      _bubbles.add(
        Bubble(
          position: Offset(
            _random.nextDouble(),
            _random.nextDouble(),
          ),
          radius: _random.nextDouble() * maxRadius,
          opacity: 0.1 + _random.nextDouble() * 0.4,
        ),
      );
    }
  }

  final _random = math.Random();

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in _bubbles) {
      final paint = Paint()
        ..color = color.withOpacity(bubble.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(
          bubble.position.dx * size.width,
          bubble.position.dy * size.height,
        ),
        bubble.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Bubble {
  final Offset position;
  final double radius;
  final double opacity;

  Bubble({
    required this.position,
    required this.radius,
    required this.opacity,
  });
} 