{
  lib,
  fetchFromGitHub,
  mkSwiftPackage,
  swift,
  swift-collections,
  swift-foundation-icu,
  swift-syntax,
  swift_release,
}:

mkSwiftPackage (finalAttrs: {
  pname = "swift-foundation";
  version = swift_release;

  src = fetchFromGitHub {
    owner = "swiftlang";
    repo = "swift-foundation";
    tag = finalAttrs.version;
    hash = lib.fakeHash;
  };

  buildInputs = [
    swift-collections
    swift-foundation-icu
    swift-syntax
  ];

  #  buildInputs = [ swift-asn1 ];

  meta = {
    homepage = "https://github.com/apple/swift-foundation";
    description = "Open-source implementation of the Foundation framework in Swift";
    license = lib.licenses.asl20;
    teams = [ lib.teams.swift ];
  };
})
