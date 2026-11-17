%EXPORTREADMEIMAGES  Regenerate the images shown in README.md.
%   Run from anywhere:  run("examples/exportReadmeImages.m")
%   Writes images/features.png and images/orbital-elements.png.

here     = fileparts(mfilename("fullpath"));
imageDir = fullfile(fileparts(here), "images");
if ~isfolder(imageDir)
    mkdir(imageDir);
end

run(fullfile(here, "demo_plotAngleArc3d.m"));

exports = ["plotAngleArc3d: features",          "features.png"
           "plotAngleArc3d: orbital elements",  "orbital-elements.png"];
for k = 1:height(exports)
    fig = findobj(groot, "Type", "figure", "Name", exports(k, 1));
    exportgraphics(fig(1), fullfile(imageDir, exports(k, 2)), ...
        Resolution=150, BackgroundColor="white");
    fprintf("Wrote %s\n", fullfile(imageDir, exports(k, 2)));
end
