# Changelog

## 2.0.0 — 2026-11-17

Complete rewrite. **The calling syntax has changed**; see
[Upgrading from 1.x](README.md#upgrading-from-1x).

### Changed
- Name-value interface: `plotAngleArc3d(v1, v2, Radius=0.5, Label="\theta", ...)`
  replaces the nine positional inputs.
- `WhichAngle = -1` (concave) is now `Reflex=true`.
- Any line property (`Color`, `LineWidth`, `LineStyle`, `DisplayName`, ...) is
  passed directly instead of an `ArcStyle` cell array.
- Outputs are now `[hArc, hLabel, labelPos]`. The arrowhead is part of the arc's
  line object, so it shares its style and is deleted with it.
- On a reflex angle the arrowhead now points at `v2`, as it does on the minor angle.
- The default arrowhead size is proportional to `Radius`, so it looks the same at
  any scale.
- Drawing uses `line` and `text`: the `hold` state and the view are not changed.
- Requires MATLAB R2021a or later.

### Added
- `Normal` option: sets the direction of rotation, so angles from 0 to 360 degrees
  can be drawn, and settles which side to draw for opposite vectors.
- `Parent` option to draw into specific axes.
- `RightAngleMarker`, `NumPoints`, `ArrowSize`, `LabelOffset` options.
- 2D vectors are accepted.
- Unit tests and a demo script.

### Fixed
- `ArrowedAngle = 0` caused an error.
- With `hold off`, drawing the arrowhead erased the arc.
- The size check accepted vectors with the wrong number of elements.
- Parallel or opposite vectors could leave the angle undefined, and vectors along
  the z-axis gave a degenerate plane.
- A 270-degree angle between perpendicular vectors was drawn as a right-angle square.
- An empty text object was created when no label was given.

## 1.0.1 — 2023

Original release on
[MATLAB File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/127654-plot-any-three-dimensional-3d-angle).
