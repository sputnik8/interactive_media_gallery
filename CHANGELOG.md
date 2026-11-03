## 1.2.0+3 - 2026-11-03

- Support Flutter 3.47 / Dart 3.13; pin development SDK to Flutter 3.47.9.
- Use only Flutter widgets in the library; migrate the example to material_ui and cupertino_ui.
- Preserve caller ownership of page controllers and support controller replacement.
- Give InteractiveViewerBoundary usable default zoom limits and support controller replacement.
- Detect unzoomed boundaries relative to the configured minimum scale.

#

## 0.6.0 - 25.06.2021
* fix nullable error

## 0.5.0 - 06.04.2021

* add onPageChanged
* optimize the position of double-click to enlarge

## 0.4.0 - 12.03.2021

* support null safe

## 0.3.0 - 04.11.2020

* fix itemBuilder's initState multi run
* optimized demo: reclaim invisible items