function [hArc, hLabel, labelPos] = plotAngleArc3d(v1, v2, opts, lineOpts)
%PLOTANGLEARC3D  Draw the arc marking the angle between two vectors in 3D.
%
%   PLOTANGLEARC3D(V1, V2) draws, in the current axes, a circular arc of
%   radius 0.3 centered at the origin that spans the angle between vectors
%   V1 and V2 (the smaller one, between 0 and 180 degrees). The arc starts
%   on V1 and ends on V2. When V1 and V2 are perpendicular, a square (the
%   usual right-angle symbol) is drawn instead of the arc.
%
%   V1 and V2 are 3-element vectors (row or column). 2-element vectors are
%   accepted too and are taken to lie in the z = 0 plane.
%
%   PLOTANGLEARC3D(..., Name=Value) sets options:
%
%   Geometry
%     Origin            Common tail of V1 and V2.              [0 0 0]
%     Radius            Arc radius, in data units.             0.3
%     Reflex            true draws the reflex angle (360 degrees minus
%                       the smaller one), still going from V1 to V2.
%                                                              false
%     Normal            Normal of the plane of the angle. It fixes the
%                       direction of rotation: the arc goes counter-
%                       clockwise from V1 to V2 as seen from the tip of
%                       Normal (right-hand rule), so it can span 0 to
%                       360 degrees. V1 and V2 are first projected onto
%                       the plane perpendicular to Normal. Cannot be
%                       combined with Reflex.                  []
%     RightAngleMarker  Draw a square for 90-degree angles.    true
%     NumPoints         Number of points along the arc.        101
%
%   Arrowhead
%     Arrow             Draw an arrowhead at the V2 end.       false
%     ArrowSize         Arrowhead side length, in data units.
%                       [] scales it with Radius.              []
%
%   Label
%     Label             Text placed next to the middle of the arc.  ""
%     LabelOffset       Distance of the label from Origin, as a
%                       multiple of the distance of the arc midpoint.
%                                                              1.25
%     LabelProperties   Cell array of name-value pairs passed to TEXT,
%                       e.g. {'Interpreter','latex','FontSize',14}. {}
%
%   Line appearance
%     Any line property (Color, LineWidth, LineStyle, DisplayName, Tag,
%     Parent, ...). Color defaults to black. Use Parent to draw into
%     specific axes instead of the current ones.
%
%   [hArc, hLabel, labelPos] = PLOTANGLEARC3D(...) returns the line object
%   (arc and arrowhead together), the text object (empty when there is no
%   Label), and the 3x1 point where the label is placed. labelPos is
%   returned even without a Label, to place your own annotation.
%
%   The arc is drawn with LINE and TEXT, so it is added to the axes
%   whatever the HOLD state and the view is left unchanged: on new axes,
%   call view(3) to see it in 3D.
%
%   Example
%     v1 = [1 0 0];
%     v2 = [0.3 1 0.5];
%     figure, hold on, axis equal, grid on, view(3)
%     quiver3(0, 0, 0, v1(1), v1(2), v1(3), 0, 'k')
%     quiver3(0, 0, 0, v2(1), v2(2), v2(3), 0, 'k')
%     plotAngleArc3d(v1, v2, Radius=0.4, Arrow=true, Color="r", ...
%         LineWidth=1.5, Label="$\theta$", ...
%         LabelProperties={'Interpreter', 'latex', 'FontSize', 14})
%
%   See also LINE, TEXT, QUIVER3.

%   Copyright (c) 2023-2026 Alessandro Beolchi
%   Distributed under the BSD 3-Clause License (see LICENSE).

arguments
    v1 {mustBeNumeric, mustBeReal, mustBeFinite, mustBeVector}
    v2 {mustBeNumeric, mustBeReal, mustBeFinite, mustBeVector}
    opts.Origin {mustBeNumeric, mustBeReal, mustBeFinite, mustBeVector} = [0 0 0]
    opts.Radius (1,1) double {mustBePositive, mustBeFinite} = 0.3
    opts.Reflex (1,1) logical = false
    opts.Normal {mustBeNumeric, mustBeReal, mustBeFinite} = []
    opts.RightAngleMarker (1,1) logical = true
    opts.NumPoints (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(opts.NumPoints, 2)} = 101
    opts.Arrow (1,1) logical = false
    opts.ArrowSize double {mustBeScalarOrEmpty, mustBePositive, mustBeFinite} = []
    opts.Label {mustBeText} = ""
    opts.LabelOffset (1,1) double {mustBePositive, mustBeFinite} = 1.25
    opts.LabelProperties cell = {}
    lineOpts.?matlab.graphics.chart.primitive.Line
end

ZERO_TOL        = 1e-12;          % below this, an angle or a sine is zero
RIGHT_ANGLE_TOL = 1e-8;           % radians
ARROW_HALF_ANGLE = deg2rad(27);   % half opening of the arrowhead

% ---- Inputs as 3x1 column vectors ---------------------------------------
u1     = unitVector(v1, "V1");
u2     = unitVector(v2, "V2");
origin = to3(opts.Origin, "Origin");
R      = opts.Radius;

% ---- Plane of the arc and swept angle -----------------------------------
% The arc is R*(cos(t)*e1 + sin(t)*e2) for t in [0, sweep]: e1 points
% along V1, e2 is 90 degrees ahead in the direction of rotation.
[e1, e2, sweep] = arcFrame(u1, u2, opts, ZERO_TOL);

if sweep < ZERO_TOL
    warning("plotAngleArc3d:zeroAngle", ...
        "V1 and V2 point in the same direction, so there is no angle to draw.");
    hArc     = gobjects(0);
    hLabel   = gobjects(0);
    labelPos = origin + opts.LabelOffset * R * e1;
    return
end

% ---- Arc (or right-angle square) points, relative to Origin -------------
if opts.RightAngleMarker && abs(sweep - pi/2) < RIGHT_ANGLE_TOL
    P       = R * [e1, e1 + e2, e2];   % square of side Radius
    mid     = P(:, 2);                 % label goes past the outer corner
    tangent = -e1;                     % direction of travel at the end
else
    t       = linspace(0, sweep, opts.NumPoints);
    P       = R * (e1 * cos(t) + e2 * sin(t));
    mid     = R * (e1 * cos(sweep/2) + e2 * sin(sweep/2));
    tangent = -e1 * sin(sweep) + e2 * cos(sweep);
end
labelPos = origin + opts.LabelOffset * mid;

% ---- Arrowhead: a "V" at the end, in the plane of the arc ---------------
% It is appended to the same line object after a NaN break, so it shares
% the arc's style and is deleted with it.
if opts.Arrow
    if isempty(opts.ArrowSize)
        L = R * min(0.2, 0.5 * sweep);  % never longer than half the arc
    else
        L = opts.ArrowSize;
    end
    tip  = P(:, end);
    side = cross(cross(e1, e2), tangent);   % in plane, normal to tangent
    back = -cos(ARROW_HALF_ANGLE) * tangent;
    head = [tip + L * (back + sin(ARROW_HALF_ANGLE) * side), ...
            tip, ...
            tip + L * (back - sin(ARROW_HALF_ANGLE) * side)];
    P = [P, NaN(3, 1), head];
end

% ---- Draw ---------------------------------------------------------------
if isfield(lineOpts, "Parent")
    parent   = lineOpts.Parent;
    lineOpts = rmfield(lineOpts, "Parent");
else
    parent = gca;
end
if ~isfield(lineOpts, "Color")
    lineOpts.Color = "k";
end
lineArgs = namedargs2cell(lineOpts);

X    = origin + P;
hArc = line(X(1, :), X(2, :), X(3, :), "Parent", parent, lineArgs{:});

hLabel = gobjects(0);
if any(strlength(string(opts.Label)) > 0)
    hLabel = text(labelPos(1), labelPos(2), labelPos(3), opts.Label, ...
        "Parent", parent, ...
        "HorizontalAlignment", "center", "VerticalAlignment", "middle", ...
        opts.LabelProperties{:});
end

end

% =========================================================================
function [e1, e2, sweep] = arcFrame(u1, u2, opts, zeroTol)
%ARCFRAME  In-plane basis (e1 along V1, e2 ahead of it) and swept angle.

if ~isempty(opts.Normal)
    if opts.Reflex
        error("plotAngleArc3d:conflictingOptions", ...
            "Reflex and Normal cannot be used together: Normal already " + ...
            "determines which side of the angle is drawn.");
    end
    n  = unitVector(opts.Normal, "Normal");
    p1 = u1 - dot(u1, n) * n;          % projections onto the plane
    p2 = u2 - dot(u2, n) * n;
    if norm(p1) < sqrt(eps) || norm(p2) < sqrt(eps)
        error("plotAngleArc3d:parallelToNormal", ...
            "V1 and V2 must not be parallel to Normal.");
    end
    e1 = p1 / norm(p1);
    p2 = p2 / norm(p2);
    e2 = cross(n, e1);
    sweep = mod(atan2(dot(cross(e1, p2), n), dot(e1, p2)), 2*pi);
    if sweep > 2*pi - zeroTol          % same direction up to round-off
        sweep = 0;
    end
    return
end

c     = cross(u1, u2);
s     = norm(c);
theta = atan2(s, dot(u1, u2));         % in [0, pi], accurate at all angles

if s > zeroTol
    n = c / s;
else
    % V1 and V2 are collinear: any plane through them would do.
    n = perpendicularTo(u1);
    if theta > pi/2 || opts.Reflex
        warning("plotAngleArc3d:undefinedPlane", ...
            "V1 and V2 are collinear, so the plane of the angle is " + ...
            "undefined and an arbitrary one was chosen. Use the Normal " + ...
            "option to choose it.");
    end
end

if opts.Reflex
    n     = -n;                        % go the long way round to V2
    sweep = 2*pi - theta;
else
    sweep = theta;
end
e1 = u1;
e2 = cross(n, e1);
end

% =========================================================================
function n = perpendicularTo(u)
%PERPENDICULARTO  Unit vector normal to u, as close as possible to +z.
% For vectors in the xy-plane this gives +z, so 2D input stays in 2D.
z = [0; 0; 1];
if abs(dot(u, z)) < 0.9
    n = z - dot(z, u) * u;
else
    x = [1; 0; 0];
    n = x - dot(x, u) * u;
end
n = n / norm(n);
end

% =========================================================================
function u = unitVector(v, name)
v = to3(v, name);
r = norm(v);
if r == 0
    error("plotAngleArc3d:zeroVector", "%s must be a nonzero vector.", name);
end
u = v / r;
end

% =========================================================================
function v = to3(v, name)
%TO3  Return a 3x1 double column; 2-element input gets z = 0.
v = double(v(:));
if numel(v) == 2
    v(3) = 0;
elseif numel(v) ~= 3
    error("plotAngleArc3d:badSize", "%s must have 2 or 3 elements.", name);
end
end
