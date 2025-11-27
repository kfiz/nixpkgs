{
  lib,
  fetchFromGitHub,
  mkSwiftPackage,
  swift-docc-symbolkit,
}:

mkSwiftPackage (finalAttrs: {
  pname = "swift-docc-plugin";
  version = "1.4.5";

  src = fetchFromGitHub {
    owner = "swiftlang";
    repo = "swift-docc-plugin";
    tag = finalAttrs.version;
    hash = "sha256-wjsQK00vE6EKfZrrMwbx8F/088kSdyYCIONV1xginsE=";
  };

  buildInputs = [ swift-docc-symbolkit ];
})
