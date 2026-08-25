## 0.0.2

### Added

- **ColorPicker.** `FluentColorPicker`, `FluentColorArea`, `FluentColorSlider`
  and `FluentAlphaSlider`, ported from `@fluentui/react-color-picker-preview`,
  with `FluentColorPickerStyle`, `FluentColorAreaStyle` and
  `FluentColorSliderStyle`, the three matching `*Theme` widgets and the usual
  `resolve*State` / `resolve*Style` / `build*` trio per component. The colour is
  Flutter's own `HSVColor` — no new colour type reaches the API — and a picker
  publishes it to its children through `FluentColorPickerScope`, so all four
  controls always agree. Controlled only: there is no `defaultColor`, because
  upstream's uncontrolled mode gives each child its own copy of the value and
  they drift apart on the first drag. A new showroom page covers all eight
  upstream stories.

### Fixed

- **`FluentSlider` no longer loses a touch drag to a scrolling ancestor.** It
  used a `GestureDetector` with `onTapDown` + `onHorizontalDrag*`, which does not
  claim the pointer until the drag slop is exceeded — long enough for a
  horizontally scrolling parent to win the arena. It now claims at pointer-down
  through the same `EagerGestureRecognizer` path the colour controls use. Mouse
  input was never affected, because Flutter leaves mouse out of
  `ScrollBehavior.dragDevices`, which is why no test caught it.

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

### Publishing

- Use the Fluent 2 project logo as the first pub.dev screenshot and thumbnail.
- Require `fluent_2_core` and `fluent_2_fonts_web` 0.0.2.

## 0.0.1

- Initial release.
