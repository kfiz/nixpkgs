{
  lib,
  fetchFromGitHub,
  mkSwiftPackage,
  swift_release,
}:

mkSwiftPackage (finalAttrs: {
  pname = "swift-docc-symbolkit";
  version = swift_release;

  src = fetchFromGitHub {
    owner = "swiftlang";
    repo = "swift-docc-symbolkit";
    tag = "swift-${finalAttrs.version}-RELEASE";
    hash = "sha256-L0ifS0XZYFQmvye2hO7aiCwW535mE6Y+3EJTAUvX3Jk=";
  };
})
