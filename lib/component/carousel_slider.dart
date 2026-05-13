import 'dart:async';

import 'package:flutter/material.dart';
import 'package:thesisapp/theme_color.dart';

class CarouselSliderWidget extends StatefulWidget {
  final List<String> images;
  final double height;

  const CarouselSliderWidget({
    super.key,
    required this.images,
    this.height = 182,
  });

  @override
  State<CarouselSliderWidget> createState() => _CarouselSliderWidgetState();
}

class _CarouselSliderWidgetState extends State<CarouselSliderWidget> {
  late final PageController _controller;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = _loopStartPage();
    _controller = PageController(initialPage: _currentPage);
    _startAutoScroll();
  }

  int _loopStartPage() {
    if (widget.images.isEmpty) {
      return 0;
    }

    return widget.images.length * 1000;
  }

  ImageProvider _imageProvider(String image) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return NetworkImage(image);
    }

    return AssetImage(image);
  }

  void _startAutoScroll() {
    if (widget.images.length < 2) {
      return;
    }

    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }

      _controller.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant CarouselSliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length != widget.images.length) {
      _currentIndex = 0;
      _currentPage = _loopStartPage();
      if (_controller.hasClients) {
        _controller.jumpToPage(_currentPage);
      }
      _autoScrollTimer?.cancel();
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length < 2 ? widget.images.length : null,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  _currentIndex = index % widget.images.length;
                });
              },
              itemBuilder: (context, index) {
                final imageIndex = index % widget.images.length;

                return Image(
                  image: _imageProvider(widget.images[imageIndex]),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(
                      color: Color(0xFFEDE7DF),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.black38,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index ? GText1 : GBackground4,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        ),
      ],
    );
  }
}
