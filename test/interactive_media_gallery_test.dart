import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_media_gallery/custom_dismissible.dart';
import 'package:interactive_media_gallery/hero_dialog_route.dart';
import 'package:interactive_media_gallery/interactive_media_gallery.dart';
import 'package:interactive_media_gallery/interactive_viewer_boundary.dart';

class _Gallery extends StatelessWidget {
  const _Gallery({this.controller, this.initialIndex = 1, this.onPageChanged});

  final PageController? controller;
  final int initialIndex;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    return InteractiveMediaGallery<int>(
      sources: const [0, 1, 2],
      initIndex: initialIndex,
      maxScale: 4,
      pageController: controller,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index, focused) => SizedBox.expand(
        child: ColoredBox(
          color: const Color(0xFF123456),
          child: Center(child: Text('$index:$focused')),
        ),
      ),
    );
  }
}

class _Host extends StatelessWidget {
  const _Host({required this.child, this.navigatorKey});

  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFF000000),
      navigatorKey: navigatorKey,
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => child,
      ),
    );
  }
}

void main() {
  group('InteractiveMediaGallery', () {
    testWidgets('opens the requested page and reports swipes and focus', (
      tester,
    ) async {
      final pages = <int>[];
      await tester.pumpWidget(
        _Host(child: _Gallery(initialIndex: 1, onPageChanged: pages.add)),
      );
      expect(find.text('1:true'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-700, 0));
      await tester.pumpAndSettle();
      expect(find.text('2:true'), findsOneWidget);
      expect(pages, [2]);
    });

    testWidgets('leaves a caller-owned page controller usable after removal', (
      tester,
    ) async {
      final controller = PageController(initialPage: 1);
      await tester.pumpWidget(_Host(child: _Gallery(controller: controller)));
      await tester.pumpWidget(const SizedBox());
      controller.addListener(() {});
      controller.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'accepts a replacement page controller without disposing either caller controller',
      (tester) async {
        final first = PageController(initialPage: 1);
        final second = PageController(initialPage: 2);
        final current = ValueNotifier<PageController>(first);
        await tester.pumpWidget(
          _Host(
            child: ValueListenableBuilder<PageController>(
              valueListenable: current,
              builder: (context, controller, _) =>
                  _Gallery(controller: controller),
            ),
          ),
        );
        current.value = second;
        await tester.pumpAndSettle();
        expect(second.hasClients, isTrue);
        expect(first.hasClients, isFalse);
        first.addListener(() {});
        await tester.pumpWidget(const SizedBox());
        second.addListener(() {});
        first.dispose();
        second.dispose();
        current.dispose();
      },
    );

    testWidgets('double tap zoom disables dismissal until zoom is reset', (
      tester,
    ) async {
      await tester.pumpWidget(const _Host(child: _Gallery()));
      final point = tester.getCenter(find.byType(PageView));
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CustomDismissible>(find.byType(CustomDismissible))
            .enabled,
        isFalse,
      );
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(
        viewer.transformationController!.value.getMaxScaleOnAxis(),
        greaterThan(1),
      );
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CustomDismissible>(find.byType(CustomDismissible))
            .enabled,
        isTrue,
      );
    });

    testWidgets('supports a transparent hero route and downward dismissal', (
      tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _Host(navigatorKey: navigator, child: const SizedBox.expand()),
      );
      final route = HeroDialogRoute<void>(builder: (_) => const _Gallery());
      navigator.currentState!.push(route);
      await tester.pumpAndSettle();
      expect(route.opaque, isFalse);
      await tester.drag(find.byType(PageView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveMediaGallery<int>), findsNothing);
    });
  });

  group('InteractiveViewerBoundary', () {
    testWidgets('supports default scale limits without Material or Cupertino', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _Host(
          child: InteractiveViewerBoundary(
            boundaryWidth: 800,
            child: SizedBox.expand(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'uses replacement transformation controllers and preserves caller ownership',
      (tester) async {
        final first = TransformationController();
        final second = TransformationController();
        final current = ValueNotifier<TransformationController>(first);
        await tester.pumpWidget(
          _Host(
            child: ValueListenableBuilder<TransformationController>(
              valueListenable: current,
              builder: (context, controller, _) => InteractiveViewerBoundary(
                controller: controller,
                boundaryWidth: 800,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
        current.value = second;
        await tester.pump();
        expect(
          tester
              .widget<InteractiveViewer>(find.byType(InteractiveViewer))
              .transformationController,
          same(second),
        );
        await tester.pumpWidget(const SizedBox());
        first.addListener(() {});
        second.addListener(() {});
        first.dispose();
        second.dispose();
        current.dispose();
      },
    );
  });
}
