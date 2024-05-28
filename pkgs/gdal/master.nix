{ fetchFromGitHub, gdal }:

let
  srcRevision = import ./master-rev.nix;
in
{
  master = gdal.overrideAttrs (final: prev: {
    pname = "gdal-master";
    version = "git-${srcRevision.rev}";

    src = fetchFromGitHub {
      owner = "OSGeo";
      repo = "gdal";
      rev = srcRevision.rev;
      hash = srcRevision.hash;
    };

    patches = [ ];
  });
}
