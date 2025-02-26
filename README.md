# interactive_media__gallery

[中文文档](./README_CH.md)

A flutter library to show picture and video preview gallery
support
1. two-finger gesture zoom
2. double-click to zoom
3. switch left and right
4. gesture back: scale, transfer, opacity of background
5. video auto paused when miss focus

## Setup

because the library is base on InteractiveViewer so require flutter verion above or equal 1.20.0
```dart
interactiveviewer_gallery: ${last_version}
```

## How to use

1. Wrap Hero in your image gridview item:
```dart
Hero(
    tag: source.url,
    child: ${gridview item}
)
 ```

2. gridview item's GestureDetector add jumping to interactiveviewer_gallery:
```dart
// DemoSourceEntity is your data model
// itemBuilder is gallery page item
void _openGallery(DemoSourceEntity source) {
  Navigator.of(context).push(
    HeroDialogRoute<void>(
      // DisplayGesture is just debug, please remove it when use
      builder: (BuildContext context) => InteractiveviewerGallery<DemoSourceEntity>(
          sources: sourceList,
          initIndex: sourceList.indexOf(source),
          itemBuilder: itemBuilder,
          onPageChanged: (int pageIndex) {
            print("nell-pageIndex:$pageIndex");
          },
      ),
    ),
  );
}
```
