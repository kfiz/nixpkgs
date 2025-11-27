{
  lib,
  fetchFromGitHub,
  mkSwiftPackage,
  swift_release,
}:

mkSwiftPackage (finalAttrs: {
  pname = "swift-experimental-string-processing";
  version = swift_release;

  src = fetchFromGitHub {
    owner = "swiftlang";
    repo = "swift-experimental-string-processing";
    tag = "swift-${finalAttrs.version}-RELEASE";
    hash = "sha256-WtLLqdvYTmLWSS5q42b8yXFrJcC+dUy4uTuCeIflRFs=";
  };

  meta = {
    homepage = "https://github.com/swiftlang/swift-experimental-string-processing";
    description = "General-purpose pattern matching engine for Swift";
    license = lib.licenses.asl20;
    teams = [ lib.teams.swift ];
  };
})
