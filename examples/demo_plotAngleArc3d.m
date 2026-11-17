%DEMO_PLOTANGLEARC3D  Tour of plotAngleArc3d features.
%   Run from the repository root:  run("examples/demo_plotAngleArc3d.m")

addpath(fileparts(fileparts(mfilename("fullpath"))));
latex = {'Interpreter', 'latex', 'FontSize', 16};

%% 1. Feature overview ------------------------------------------------------
figure(Name="plotAngleArc3d: features", Color="w", Position=[100 100 1100 700]);
tl = tiledlayout(2, 3, TileSpacing="compact", Padding="compact");

% Minor angle, with label and arrowhead
ax = setupAxes(tl, "Minor angle (default)", [35 20]);
v1 = [1 0 0.2]; v2 = [0.2 1 0.6];
drawVectors(ax, [0 0 0], v1, v2);
plotAngleArc3d(v1, v2, Parent=ax, Radius=0.45, Arrow=true, Color="#0072BD", ...
    LineWidth=1.5, Label="$\theta$", LabelProperties=latex);

% Reflex angle
ax = setupAxes(tl, "Reflex=true", [35 20]);
drawVectors(ax, [0 0 0], v1, v2);
plotAngleArc3d(v1, v2, Parent=ax, Radius=0.3, Color="#0072BD", Label="$\theta$", ...
    LabelProperties=latex);
plotAngleArc3d(v1, v2, Parent=ax, Radius=0.5, Reflex=true, Arrow=true, ...
    Color="#D95319", LineWidth=1.5, LineStyle="--", ...
    Label="$2\pi-\theta$", LabelProperties=latex);

% Right angle
ax = setupAxes(tl, "Right angle", [35 20]);
w1 = [1 0 0]; w2 = [0 0.5 1];   % perpendicular, but not along the axes
w2 = w2 - dot(w2, w1) * w1;
drawVectors(ax, [0 0 0], w1, w2);
plotAngleArc3d(w1, w2, Parent=ax, Radius=0.25, LineWidth=1.5);

% Normal fixes the direction of rotation, so angles can exceed 180 degrees
ax = setupAxes(tl, "Normal=[0 0 1]: 0 to 360 degrees", [-30 40]);
a = [1 0 0]; b = [cosd(250) sind(250) 0];
drawVectors(ax, [0 0 0], a, b);
plotAngleArc3d(a, b, Parent=ax, Normal=[0 0 1], Radius=0.4, Arrow=true, ...
    Color="#7E2F8E", LineWidth=1.5, Label="$250^\circ$", LabelProperties=latex);

% Any origin, dotted style, custom arrow size
ax = setupAxes(tl, "Origin, line style, ArrowSize", [120 25]);
o = [0.5 0.5 0.5]; p = [-0.3 1 0.2]; q = [0.8 -0.2 0.9];
drawVectors(ax, o, p, q);
plotAngleArc3d(p, q, Parent=ax, Origin=o, Radius=0.5, Arrow=true, ArrowSize=0.12, ...
    Color="#77AC30", LineWidth=2, LineStyle=":", Label="$\varphi$", ...
    LabelProperties=latex);

% 2D vectors work too
ax = nexttile(tl); hold(ax, "on"); axis(ax, "equal"); grid(ax, "on");
title(ax, "2D input");
c = [1 0.3]; d = [-0.4 1];
quiver(ax, [0 0], [0 0], [c(1) d(1)], [c(2) d(2)], 0, "k", LineWidth=1.2);
plotAngleArc3d(c, d, Parent=ax, Radius=0.35, Arrow=true, Color="#A2142F", ...
    LineWidth=1.5, Label="$\alpha$", LabelProperties=latex);

%% 2. Orbital elements --------------------------------------------------------
% The kind of figure the function was first written for.
inc = 35; RAAN = 60; argp = 50; nu = 70;   % degrees

N  = [cosd(RAAN); sind(RAAN); 0];                       % ascending node
h  = [sind(RAAN)*sind(inc); -cosd(RAAN)*sind(inc); cosd(inc)];  % orbit normal
T  = cross(h, N);                                       % in-plane, 90 deg ahead of N
e  = cosd(argp)*N + sind(argp)*T;                       % periapsis
r  = cosd(argp + nu)*N + sind(argp + nu)*T;             % spacecraft

figure(Name="plotAngleArc3d: orbital elements", Color="w");
ax = axes; hold(ax, "on"); axis(ax, "equal"); axis(ax, "off"); view(ax, 125, 22);

t = linspace(0, 2*pi, 200);
plot3(ax, cos(t), sin(t), 0*t, ":", Color=[0.5 0.5 0.5]);              % equator
orbit = N*cos(t) + T*sin(t);
plot3(ax, orbit(1,:), orbit(2,:), orbit(3,:), "k", LineWidth=1);        % orbit

axisVec = {[1.3;0;0], "$\hat{x}$"; [0;1.3;0], "$\hat{y}$"; [0;0;1.3], "$\hat{z}$"};
for k = 1:3
    drawArrow(ax, axisVec{k, 1}, "k", axisVec{k, 2});
end
drawArrow(ax, 1.3*h, "#0072BD", "$\hat{h}$");
drawArrow(ax, 1.2*N, "#D95319", "$\hat{N}$");
drawArrow(ax, e,     "#77AC30", "$\hat{e}$");
drawArrow(ax, r,     "#7E2F8E", "$\vec{r}$");

plotAngleArc3d([1 0 0], N, Parent=ax, Normal=[0 0 1], Radius=0.45, Arrow=true, ...
    Color="#D95319", LineWidth=1.5, Label="$\Omega$", LabelProperties=latex);
plotAngleArc3d([0 0 1], h, Parent=ax, Radius=0.6, Arrow=true, ...
    Color="#0072BD", LineWidth=1.5, Label="$i$", LabelProperties=latex);
plotAngleArc3d(N, e, Parent=ax, Normal=h, Radius=0.6, Arrow=true, ...
    Color="#77AC30", LineWidth=1.5, Label="$\omega$", LabelProperties=latex);
plotAngleArc3d(e, r, Parent=ax, Normal=h, Radius=0.75, Arrow=true, ...
    Color="#7E2F8E", LineWidth=1.5, Label="$\nu$", LabelProperties=latex);

% =========================================================================
function ax = setupAxes(tl, ttl, viewAngles)
% Each tile has its own view, chosen so the plane of the angle faces the camera.
ax = nexttile(tl);
hold(ax, "on"); axis(ax, "equal"); grid(ax, "on"); view(ax, viewAngles);
xlabel(ax, "x"); ylabel(ax, "y"); zlabel(ax, "z");
title(ax, ttl);
end

function drawVectors(ax, o, varargin)
for k = 1:numel(varargin)
    v = varargin{k};
    quiver3(ax, o(1), o(2), o(3), v(1), v(2), v(3), 0, "k", LineWidth=1.2);
end
end

function drawArrow(ax, v, color, label)
quiver3(ax, 0, 0, 0, v(1), v(2), v(3), 0, Color=color, LineWidth=1.3, ...
    MaxHeadSize=0.15);
text(ax, 1.08*v(1), 1.08*v(2), 1.08*v(3), label, Interpreter="latex", ...
    FontSize=15, Color=color);
end
