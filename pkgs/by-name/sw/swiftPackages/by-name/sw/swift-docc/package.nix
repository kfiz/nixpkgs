{
  lib,
  mkSwiftPackage,
  fetchFromGitHub,
  swift-nio,
  swift-markdown,
  swift-lmdb,
  swift-argument-parser,
  swift-docc-symbolkit,
  swift-crypto,
  swift-docc-plugin,
  swift_release,
}:

mkSwiftPackage (finalAttrs: {
  pname = "swift-ddoc";
  version = swift_release;

  src = fetchFromGitHub {
    owner = "swiftlang";
    repo = "swift-ddoc";
    tag = "swift-${finalAttrs.version}-RELEASE";
    hash = lib.fakeHash;
  };

  buildInputs = [
    swift-argument-parser
    swift-crypto
    swift-docc-plugin
    swift-docc-symbolkit
    swift-lmdb
    swift-markdown
    swift-nio
  ];

  meta = {
    description = "Documentation compiler for Swift";
    mainProgram = "docc";
    homepage = "https://github.com/apple/swift-docc";
    platforms = with lib.platforms; linux ++ darwin;
    license = lib.licenses.asl20;
    teams = [ lib.teams.swift ];
  };
})
