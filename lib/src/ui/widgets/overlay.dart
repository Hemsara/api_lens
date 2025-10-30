import 'package:flutter/material.dart';

import '../../../api_lens.dart';

class ApiLensOverlay extends StatefulWidget {
  final Widget child;
  final ApiLoggerConfig? config;
  final GlobalKey<NavigatorState>? navigatorKey;

  const ApiLensOverlay({
    super.key,
    required this.child,
    this.config,
        this.navigatorKey,

  });

  @override
  State<ApiLensOverlay> createState() => _ApiLensOverlayState();
}

class _ApiLensOverlayState extends State<ApiLensOverlay> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Offset _position = const Offset(0, 100);
  bool _isHidden = false;
  bool _isDragging = false;

  ApiLoggerConfig get _config => widget.config ?? ApiLens.instance.config;

  @override
  Widget build(BuildContext context) {
    if (!_config.showDebugButton) {
      return widget.child;
    }

    final wrappedChild = _wrapWithNavigatorKey(widget.child);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          wrappedChild,
          _buildDraggableButton(),
        ],
      ),
    );
  }

  Widget _wrapWithNavigatorKey(Widget child) {
    if (child is MaterialApp) {
      return MaterialApp(
        key: child.key,
        navigatorKey: widget.navigatorKey ?? _navigatorKey,
        home: child.home,
        title: child.title,
        theme: child.theme,
        routes: child.routes ?? {},
        debugShowCheckedModeBanner: child.debugShowCheckedModeBanner,
      );
    }
    return child;
  }

  Widget _buildDraggableButton() {
    final buttonColor = _config.buttonColor ?? const Color(0xFF2563EB);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLeft = _position.dx < screenWidth / 2;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx)
                  .clamp(0.0, MediaQuery.of(context).size.width - 32),
              (_position.dy + details.delta.dy)
                  .clamp(0.0, MediaQuery.of(context).size.height - 48),
            );
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          _snapToEdge();
        },
        onTap: () {
          if (!_isDragging) {
            if (_isHidden) {
              setState(() => _isHidden = false);
            } else {
              _navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (context) => const ApiLogsScreen()),
              );
            }
          }
        },
        onDoubleTap: () => setState(() => _isHidden = !_isHidden),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isHidden ? 4 : 32,
          height: _isHidden ? 32 : 48,
          decoration: BoxDecoration(
            color: buttonColor.withOpacity(_isHidden ? 0.5 : 1.0),
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(isLeft ? 0 : 16),
              right: Radius.circular(isLeft ? 16 : 0),
            ),
            boxShadow: _isHidden
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: _isHidden
              ? const SizedBox.shrink()
              : Icon(
                  isLeft ? Icons.chevron_right : Icons.chevron_left,
                  color: Colors.white,
                  size: 20,
                ),
        ),
      ),
    );
  }

  void _snapToEdge() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLeft = _position.dx < screenWidth / 2;

    setState(() {
      _position = Offset(
        isLeft ? 0 : screenWidth - (_isHidden ? 4 : 32),
        _position.dy,
      );
    });
  }
}
