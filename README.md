# Interactive Media Gallery

A powerful Flutter library for displaying interactive image and video galleries with smooth transitions and rich gesture support.

## Features

- 🖼️ Seamless image and video preview gallery
- 🔍 Interactive zoom with two-finger gestures
- 👆 Double-tap to zoom in/out
- 🔄 Smooth horizontal navigation between media items
- ↩️ Intuitive gesture-based dismissal with scale, translation, and background opacity effects
- ⏯️ Automatic video pausing when not in focus
- ✨ Hero animations for elegant transitions



## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  interactive_media_gallery:
    git:
      url: https://github.com/sputnik8/interactive_media_gallery.git
      ref: release/1.2.0+3
```
Then run:

```bash
flutter pub get
```

## SDK and UI dependencies

Development uses Flutter 3.47.9 (Dart 3.13.7), pinned in `.fvmrc`.
The package requires Flutter 3.47+ and Dart 3.13+.
The library imports only `package:flutter/widgets.dart`; it does not depend on Material or Cupertino.
The example app uses `material_ui` and `cupertino_ui`.

## Controller ownership

The gallery owns and disposes controllers it creates internally. When passing a
`PageController`, the caller must dispose it after the gallery is removed.
`InteractiveViewerBoundary` follows the same rule for a supplied
`TransformationController`. Both widgets support replacing external controllers.

## Usage

### Basic Implementation

1. Wrap your grid items with `Hero` widgets for smooth transitions:

```dart
Hero(
  tag: source.url, // Unique identifier for the Hero animation
  child: YourGridViewItem(),
)
```

2. Create a gallery view with your data model:

```dart
void openGallery(YourDataModel source) {
  Navigator.of(context).push(
    HeroDialogRoute<void>(
      builder: (BuildContext context) => InteractiveMediaGallery<YourDataModel>(
        sources: sourceList,
        initIndex: sourceList.indexOf(source),
        itemBuilder: (context, index, isFocused) {
          // Build your gallery item based on your data model
          return YourGalleryItemWidget(
            source: sourceList[index],
            isFocused: isFocused,
          );
        },
        onPageChanged: (int pageIndex) {
          // Handle page change events
          print("Current page: $pageIndex");
        },
      ),
    ),
  );
}
```

### Advanced Configuration

The `InteractiveMediaGallery` widget supports several customization options:

```dart
InteractiveMediaGallery<YourDataModel>(
  sources: sourceList,
  initIndex: initialIndex,
  itemBuilder: itemBuilder,
  maxScale: 3.0,           // Maximum zoom scale (default: 2.5)
  minScale: 0.8,           // Minimum zoom scale (default: 1.0)
  pageController: customPageController,  // Optional custom page controller
  onPageChanged: onPageChangedCallback,
)
```

## Example

Check out the [example project](https://github.com/sputnik8/interactive_media_gallery/tree/release/1.2.0%2B3/example) for a complete implementation.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.