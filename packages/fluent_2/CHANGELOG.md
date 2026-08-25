## Unreleased

### Breaking

- **Removed `FluentSpinButtonUnderlinePainter`.** The spin button's two bottom
  rules now come from the shared `FluentInputUnderline` /
  `FluentInputFocusUnderline` pair, like every other input. The painter drew both
  with `canvas.drawRect`, so they were square and overhung the field's rounded
  corners; upstream's `useSpinButtonStyles` rounds them via
  `height: max(2px, borderRadiusMedium)` plus
  `clipPath: inset(calc(100% - 2px) 0 0 0)`. `FluentSpinButtonChevronPainter` is
  unaffected. Anyone who subclassed or instantiated the removed painter should
  use the two widgets instead.

## 0.0.1

- Initial release.
