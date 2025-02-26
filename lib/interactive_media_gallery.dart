library;

import 'package:flutter/material.dart';
import './custom_dismissible.dart';
import './interactive_viewer_boundary.dart';

/// Builds a carousel controlled by a [PageView] for media sources.
///
/// Used for showing a full screen view of media sources.
///
/// The sources can be panned and zoomed interactively using an
/// [InteractiveViewer].
/// An [InteractiveViewerBoundary] is used to detect when the boundary of the
/// source is hit after zooming in to disable or enable the swiping gesture of
/// the [PageView].
///
typedef IndexedFocusedWidgetBuilder = Widget Function(
    BuildContext context, int index, bool isFocus);

typedef IndexedTagStringBuilder = String Function(int index);

class InteractiveMediaGallery<T> extends StatefulWidget {
  const InteractiveMediaGallery({
    required this.sources,
    required this.initIndex,
    required this.itemBuilder,
    this.pageController,
    this.maxScale = 2.5,
    this.minScale = 1.0,
    this.onPageChanged,
    super.key,
  });

  /// The sources to show.
  final List<T> sources;

  /// The index of the first source in [sources] to show.
  final int initIndex;

  /// The item content builder
  final IndexedFocusedWidgetBuilder itemBuilder;

  /// Maximum scale factor for zooming
  final double maxScale;

  /// Minimum scale factor for zooming
  final double minScale;

  /// Callback when page changes
  final ValueChanged<int>? onPageChanged;

  /// Optional page controller
  final PageController? pageController;

  @override
  State<InteractiveMediaGallery<T>> createState() =>
      _InteractiveMediaGalleryState<T>();
}

class _InteractiveMediaGalleryState<T> extends State<InteractiveMediaGallery<T>>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late TransformationController _transformationController;

  /// The controller to animate the transformation value of the
  /// [InteractiveViewer] when it should reset.
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  /// `true` when an source is zoomed in and not at the at a horizontal boundary
  /// to disable the [PageView].
  final ValueNotifier<bool> _enablePageViewNotifier = ValueNotifier<bool>(true);

  /// `true` when an source is zoomed in to disable the [CustomDismissible].
  final ValueNotifier<bool> _enableDismissNotifier = ValueNotifier<bool>(true);

  late Offset _doubleTapLocalPosition;

  final ValueNotifier<int> currentIndexNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();

    _pageController =
        widget.pageController ?? PageController(initialPage: widget.initIndex);

    _transformationController = TransformationController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )
      ..addListener(() {
        _transformationController.value =
            _animation?.value ?? Matrix4.identity();
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed &&
            !_enableDismissNotifier.value) {
          _enableDismissNotifier.value = true;
        }
      });

    currentIndexNotifier.value = widget.initIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    _animationController.dispose();
    _enablePageViewNotifier.dispose();
    _enableDismissNotifier.dispose();
    currentIndexNotifier.dispose();

    super.dispose();
  }

  /// When the source gets scaled up, the swipe up / down to dismiss gets
  /// disabled.
  ///
  /// When the scale resets, the dismiss and the page view swiping gets enabled.
  void _onScaleChanged(double scale) {
    final bool initialScale = scale <= widget.minScale;

    _enableDismissNotifier.value = initialScale;
    _enablePageViewNotifier.value = initialScale;
  }

  /// When the left boundary has been hit after scaling up the source, the page
  /// view swiping gets enabled if it has a page to swipe to.
  void _onLeftBoundaryHit() {
    if (!_enablePageViewNotifier.value && _pageController.page!.floor() > 0) {
      _enablePageViewNotifier.value = true;
    }
  }

  /// When the right boundary has been hit after scaling up the source, the page
  /// view swiping gets enabled if it has a page to swipe to.
  void _onRightBoundaryHit() {
    if (!_enablePageViewNotifier.value &&
        _pageController.page!.floor() < widget.sources.length - 1) {
      _enablePageViewNotifier.value = true;
    }
  }

  /// When the source has been scaled up and no horizontal boundary has been hit,
  /// the page view swiping gets disabled.
  void _onNoBoundaryHit() {
    if (_enablePageViewNotifier.value) {
      _enablePageViewNotifier.value = false;
    }
  }

  /// When the page view changed its page, the source will animate back into the
  /// original scale if it was scaled up.
  ///
  /// Additionally the swipe up / down to dismiss gets enabled.
  void _onPageChanged(int page) {
    currentIndexNotifier.value = page;
    widget.onPageChanged?.call(page);

    if (_transformationController.value != Matrix4.identity()) {
      // animate the reset for the transformation of the interactive viewer
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: Matrix4.identity(),
      ).animate(
        CurveTween(curve: Curves.easeOut).animate(_animationController),
      );

      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _enableDismissNotifier,
        _enablePageViewNotifier,
        currentIndexNotifier,
      ]),
      builder: (context, _) {
        return InteractiveViewerBoundary(
          key: widget.key,
          controller: _transformationController,
          boundaryWidth: MediaQuery.of(context).size.width,
          onScaleChanged: _onScaleChanged,
          onLeftBoundaryHit: _onLeftBoundaryHit,
          onRightBoundaryHit: _onRightBoundaryHit,
          onNoBoundaryHit: _onNoBoundaryHit,
          maxScale: widget.maxScale,
          minScale: widget.minScale,
          child: CustomDismissible(
            onDismissed: () => Navigator.of(context).pop(),
            enabled: _enableDismissNotifier.value,
            child: PageView.builder(
              onPageChanged: _onPageChanged,
              controller: _pageController,
              physics: _enablePageViewNotifier.value
                  ? null
                  : const NeverScrollableScrollPhysics(),
              itemCount: widget.sources.length,
              itemBuilder: _buildPageItem,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageItem(BuildContext context, int index) {
    return GestureDetector(
      onDoubleTapDown: (TapDownDetails details) {
        _doubleTapLocalPosition = details.localPosition;
      },
      onDoubleTap: _handleDoubleTap,
      child: widget.itemBuilder(
        context,
        index,
        index == currentIndexNotifier.value,
      ),
    );
  }

  void _handleDoubleTap() {
    final Matrix4 matrix = _transformationController.value.clone();
    final double currentScale = matrix.row0.x;

    final double targetScale = currentScale <= widget.minScale
        ? widget.maxScale * 0.7
        : widget.minScale;

    final double offSetX = targetScale == widget.minScale
        ? 0.0
        : -_doubleTapLocalPosition.dx * (targetScale - 1);
    final double offSetY = targetScale == widget.minScale
        ? 0.0
        : -_doubleTapLocalPosition.dy * (targetScale - 1);

    final Matrix4 newMatrix = Matrix4.fromList([
      targetScale,
      matrix.row1.x,
      matrix.row2.x,
      matrix.row3.x,
      matrix.row0.y,
      targetScale,
      matrix.row2.y,
      matrix.row3.y,
      matrix.row0.z,
      matrix.row1.z,
      targetScale,
      matrix.row3.z,
      offSetX,
      offSetY,
      matrix.row2.w,
      matrix.row3.w
    ]);

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: newMatrix,
    ).animate(
      CurveTween(curve: Curves.easeOut).animate(_animationController),
    );

    _animationController
        .forward(from: 0)
        .whenComplete(() => _onScaleChanged(targetScale));
  }
}
