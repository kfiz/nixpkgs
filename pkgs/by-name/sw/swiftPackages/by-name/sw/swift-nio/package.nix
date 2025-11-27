{
  fetchFromGitHub,
  mkSwiftPackage,
  swift-atomics,
  swift-collections,
  swift-system,
}:

mkSwiftPackage (finalAttrs: {
  pname = "swift-nio";
  version = "2.92.0";

  src = fetchFromGitHub {
    owner = "apple";
    repo = "swift-nio";
    tag = finalAttrs.version;
    hash = "sha256-DszfL36eLNCuUVpZQ79lFIpViLYuP+EAoWscfoCBoFQ=";
  };

  buildInputs = [
    swift-atomics
    swift-collections
    swift-system
  ];
})
