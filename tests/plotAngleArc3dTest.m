function tests = plotAngleArc3dTest
%PLOTANGLEARC3DTEST  Unit tests for plotAngleArc3d.
%   Run from the repository root with:  runtests("tests")
tests = functiontests(localfunctions);
end

% ---- Fixtures ------------------------------------------------------------
function setupOnce(tc)
repoRoot = fileparts(fileparts(mfilename("fullpath")));
tc.applyFixture(matlab.unittest.fixtures.PathFixture(repoRoot));
end

function setup(tc)
tc.TestData.fig = figure("Visible", "off");
tc.TestData.ax  = axes(tc.TestData.fig);
end

function teardown(tc)
close(tc.TestData.fig);
end

% ---- Helpers -------------------------------------------------------------
function P = arcPoints(h)
% Arc vertices (3xN), without the arrowhead that follows the NaN break.
P = [h.XData; h.YData; h.ZData];
k = find(any(isnan(P), 1), 1);
if ~isempty(k)
    P = P(:, 1:k-1);
end
end

function L = polylineLength(P)
L = sum(vecnorm(diff(P, 1, 2)));
end

function u = unit(v)
u = v(:) / norm(v);
end

% ---- Geometry ------------------------------------------------------------
function testEndpointsLieOnVectors(tc)
v1 = [1 2 3]; v2 = [-1 0.5 2]; o = [1; -1; 2]; R = 0.7;
h = plotAngleArc3d(v1, v2, Origin=o, Radius=R, Parent=tc.TestData.ax);
P = arcPoints(h);
tc.verifyEqual(P(:, 1),   o + R*unit(v1), AbsTol=1e-12);
tc.verifyEqual(P(:, end), o + R*unit(v2), AbsTol=1e-12);
end

function testPointsOnCircleAndInPlane(tc)
v1 = [1 2 3]; v2 = [-1 0.5 2]; o = [1; -1; 2]; R = 0.7;
h = plotAngleArc3d(v1, v2, Origin=o, Radius=R, Parent=tc.TestData.ax);
D = arcPoints(h) - o;
tc.verifyEqual(vecnorm(D), R*ones(1, size(D, 2)), AbsTol=1e-12);
tc.verifyEqual(unit(cross(v1, v2))' * D, zeros(1, size(D, 2)), AbsTol=1e-12);
end

function testMinorAngleLength(tc)
v1 = [1 2 3]; v2 = [-1 0.5 2]; R = 0.7;
theta = acos(dot(unit(v1), unit(v2)));
h = plotAngleArc3d(v1, v2, Radius=R, Parent=tc.TestData.ax);
tc.verifyEqual(polylineLength(arcPoints(h)), R*theta, RelTol=1e-3);
tc.verifyNumElements(h.XData, 101);
end

function testLabelPositionOnBisector(tc)
v1 = [1 0 0]; v2 = [1 1 1]; R = 0.5;
[~, ~, pos] = plotAngleArc3d(v1, v2, Radius=R, LabelOffset=2, Parent=tc.TestData.ax);
tc.verifyEqual(pos, 2*R*unit(unit(v1) + unit(v2)), AbsTol=1e-12);
end

function testReflexAngle(tc)
v1 = [1 2 3]; v2 = [-1 0.5 2]; R = 0.7;
theta = acos(dot(unit(v1), unit(v2)));
[h, ~, pos] = plotAngleArc3d(v1, v2, Radius=R, Reflex=true, Parent=tc.TestData.ax);
P = arcPoints(h);
tc.verifyEqual(P(:, 1),   R*unit(v1), AbsTol=1e-12);
tc.verifyEqual(P(:, end), R*unit(v2), AbsTol=1e-12);
tc.verifyEqual(polylineLength(P), R*(2*pi - theta), RelTol=1e-3);
% The middle of a reflex arc lies opposite the bisector of the minor angle.
tc.verifyEqual(unit(pos), -unit(unit(v1) + unit(v2)), AbsTol=1e-12);
end

function testRowAndColumnInputsAgree(tc)
h1 = plotAngleArc3d([1 2 3],  [3 -1 0],  Origin=[1 1 1],  Parent=tc.TestData.ax);
h2 = plotAngleArc3d([1;2;3],  [3;-1;0],  Origin=[1;1;1],  Parent=tc.TestData.ax);
tc.verifyEqual(arcPoints(h1), arcPoints(h2));
end

function testTwoDimensionalInput(tc)
h = plotAngleArc3d([1 0], [1 1], Origin=[2 3], Parent=tc.TestData.ax);
tc.verifyEqual(h.ZData, zeros(size(h.ZData)));
P = arcPoints(h);
tc.verifyEqual(P(:, end), [2; 3; 0] + 0.3*unit([1 1 0]), AbsTol=1e-12);
end

% ---- Right angle -----------------------------------------------------------
function testRightAngleSquare(tc)
R = 0.4;
h = plotAngleArc3d([2 0 0], [0 0 5], Radius=R, Parent=tc.TestData.ax);
tc.verifyEqual(arcPoints(h), R*[1 1 0; 0 0 0; 0 1 1], AbsTol=1e-12);
end

function testRightAngleMarkerOff(tc)
h = plotAngleArc3d([1 0 0], [0 1 0], RightAngleMarker=false, Parent=tc.TestData.ax);
tc.verifyNumElements(h.XData, 101);
end

function testReflexRightAngleIsArc(tc)
% 270 degrees is not a right angle: draw an arc.
h = plotAngleArc3d([1 0 0], [0 1 0], Reflex=true, NumPoints=50, Parent=tc.TestData.ax);
tc.verifyNumElements(h.XData, 50);
end

% ---- Normal option -------------------------------------------------------
function testNormalSetsRotationSense(tc)
% Seen from -z, going from +x to +y counter-clockwise takes 270 degrees.
R = 1;
[h, ~, pos] = plotAngleArc3d([1 0 0], [0 1 0], Normal=[0 0 -1], Radius=R, ...
    LabelOffset=1, Parent=tc.TestData.ax);
P = arcPoints(h);
tc.verifyEqual(polylineLength(P), R*3*pi/2, RelTol=1e-3);
tc.verifyEqual(pos, R*unit([-1 -1 0]), AbsTol=1e-12);
end

function testNormalProjectsVectors(tc)
R = 1;
h = plotAngleArc3d([1 0 1], [-1 1 5], Normal=[0 0 2], Radius=R, Parent=tc.TestData.ax);
P = arcPoints(h);
tc.verifyEqual(P(3, :), zeros(1, size(P, 2)), AbsTol=1e-12);
tc.verifyEqual(P(:, 1),   R*[1; 0; 0],          AbsTol=1e-12);
tc.verifyEqual(P(:, end), R*unit([-1 1 0]),     AbsTol=1e-12);
end

function testNormalResolvesAntiparallel(tc)
% No warning: Normal tells which half-circle to draw.
h = tc.verifyWarningFree(@() plotAngleArc3d([1 0 0], [-1 0 0], ...
    Normal=[0 1 0], Parent=tc.TestData.ax));
P = arcPoints(h);
% Counter-clockwise about +y from +x goes through -z.
tc.verifyLessThan(P(3, 51), 0);
end

% ---- Arrowhead -----------------------------------------------------------
function testArrowhead(tc)
L = 0.05;
h = plotAngleArc3d([1 0 0], [1 1 0], Arrow=true, ArrowSize=L, Parent=tc.TestData.ax);
X = [h.XData; h.YData; h.ZData];
k = find(isnan(X(1, :)));
tc.verifyNumElements(k, 1);
head = X(:, k+1:end);
tc.verifySize(head, [3 3]);
tip = X(:, k-1);
tc.verifyEqual(head(:, 2), tip, AbsTol=1e-12);
tc.verifyEqual(vecnorm(head(:, [1 3]) - tip), [L L], AbsTol=1e-12);
tc.verifyEqual(head(3, :), [0 0 0], AbsTol=1e-12);   % stays in the plane
end

function testNoArrowByDefault(tc)
h = plotAngleArc3d([1 0 0], [1 1 0], Parent=tc.TestData.ax);
tc.verifyFalse(any(isnan(h.XData)));
end

% ---- Label ---------------------------------------------------------------
function testLabel(tc)
[~, hl, pos] = plotAngleArc3d([1 0 0], [1 1 0], Label="\alpha", ...
    LabelProperties={'FontSize', 15}, Parent=tc.TestData.ax);
tc.verifyClass(hl, "matlab.graphics.primitive.Text");
tc.verifyEqual(string(hl.String), "\alpha");
tc.verifyEqual(hl.FontSize, 15);
tc.verifyEqual(hl.Position(:), pos, AbsTol=1e-12);
end

function testNoLabelByDefault(tc)
[~, hl] = plotAngleArc3d([1 0 0], [1 1 0], Parent=tc.TestData.ax);
tc.verifyEmpty(hl);
tc.verifyEmpty(findobj(tc.TestData.ax, "Type", "text"));
end

% ---- Graphics behaviour --------------------------------------------------
function testDefaultColorIsBlack(tc)
h = plotAngleArc3d([1 0 0], [1 1 0], Parent=tc.TestData.ax);
tc.verifyEqual(h.Color, [0 0 0]);
end

function testLinePropertiesPassThrough(tc)
h = plotAngleArc3d([1 0 0], [1 1 0], Color="r", LineWidth=2.5, ...
    LineStyle=":", Tag="myArc", Parent=tc.TestData.ax);
tc.verifyEqual(h.Color, [1 0 0]);
tc.verifyEqual(h.LineWidth, 2.5);
tc.verifyEqual(char(h.LineStyle), ':');
tc.verifyEqual(char(h.Tag), 'myArc');
end

function testDoesNotClearAxesWhenHoldIsOff(tc)
ax = tc.TestData.ax;
hold(ax, "off");
p = plot3(ax, [0 1], [0 1], [0 1]);
plotAngleArc3d([1 0 0], [0 1 1], Arrow=true, Label="x", Parent=ax);
tc.verifyTrue(isvalid(p));
end

function testUsesCurrentAxesByDefault(tc)
h = plotAngleArc3d([1 0 0], [1 1 0]);
tc.verifyEqual(h.Parent, tc.TestData.ax);
end

function testParentOption(tc)
other = axes(figure("Visible", "off"));
cleanup = onCleanup(@() close(other.Parent));
% Make the fixture axes current without making its figure visible.
set(groot, "CurrentFigure", tc.TestData.fig);
tc.TestData.fig.CurrentAxes = tc.TestData.ax;
[h, hl] = plotAngleArc3d([1 0 0], [1 1 0], Label="a", Parent=other);
tc.verifyEqual(h.Parent, other);
tc.verifyEqual(hl.Parent, other);
end

% ---- Degenerate cases ----------------------------------------------------
function testAntiparallelWarnsAndDrawsHalfCircle(tc)
R = 0.3;
h = tc.verifyWarning(@() plotAngleArc3d([1 0 0], [-2 0 0], Parent=tc.TestData.ax), ...
    "plotAngleArc3d:undefinedPlane");
tc.verifyEqual(polylineLength(arcPoints(h)), R*pi, RelTol=1e-3);
end

function testAntiparallelIn2DStaysInPlane(tc)
h = tc.verifyWarning(@() plotAngleArc3d([1 1], [-1 -1], Parent=tc.TestData.ax), ...
    "plotAngleArc3d:undefinedPlane");
tc.verifyEqual(h.ZData, zeros(size(h.ZData)), AbsTol=1e-12);
end

function testParallelWarnsAndDrawsNothing(tc)
[h, hl] = tc.verifyWarning(@() plotAngleArc3d([1 2 3], [2 4 6], ...
    Label="x", Parent=tc.TestData.ax), "plotAngleArc3d:zeroAngle");
tc.verifyEmpty(h);
tc.verifyEmpty(hl);
tc.verifyEmpty(tc.TestData.ax.Children);
end

function testParallelReflexIsFullCircle(tc)
R = 0.3;
h = tc.verifyWarning(@() plotAngleArc3d([0 0 1], [0 0 3], Reflex=true, ...
    Parent=tc.TestData.ax), "plotAngleArc3d:undefinedPlane");
tc.verifyEqual(polylineLength(arcPoints(h)), 2*pi*R, RelTol=1e-3);
end

function testNearlyRightAngleWithinTolerance(tc)
h = plotAngleArc3d([1 0 0], [1e-12 1 0], Parent=tc.TestData.ax);
tc.verifyNumElements(h.XData, 3);
end

% ---- Input errors --------------------------------------------------------
function testZeroVectorErrors(tc)
tc.verifyError(@() plotAngleArc3d([0 0 0], [1 0 0], Parent=tc.TestData.ax), ...
    "plotAngleArc3d:zeroVector");
end

function testWrongSizeErrors(tc)
tc.verifyError(@() plotAngleArc3d([1 0 0 0], [1 0 0], Parent=tc.TestData.ax), ...
    "plotAngleArc3d:badSize");
tc.verifyError(@() plotAngleArc3d([1 0 0], [1 1 0], Origin=[1 2 3 4], ...
    Parent=tc.TestData.ax), "plotAngleArc3d:badSize");
end

function testReflexWithNormalErrors(tc)
tc.verifyError(@() plotAngleArc3d([1 0 0], [0 1 0], Reflex=true, Normal=[0 0 1], ...
    Parent=tc.TestData.ax), "plotAngleArc3d:conflictingOptions");
end

function testVectorAlongNormalErrors(tc)
tc.verifyError(@() plotAngleArc3d([0 0 1], [0 1 0], Normal=[0 0 1], ...
    Parent=tc.TestData.ax), "plotAngleArc3d:parallelToNormal");
end

function testInvalidRadiusErrors(tc)
tc.verifyError(@() plotAngleArc3d([1 0 0], [0 1 0], Radius=-1, ...
    Parent=tc.TestData.ax), "MATLAB:validators:mustBePositive");
end
