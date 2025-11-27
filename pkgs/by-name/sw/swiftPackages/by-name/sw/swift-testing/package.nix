{
  lib,
  fetchFromGitHub,
  mkSwiftPackage,
  stdenv,
  swift-syntax,
  swift-no-swift-driver,
  swift_release,
}:

mkSwiftPackage.override
  {
    build-system = "cmake";
    swift = swift-no-swift-driver;
  }
  (finalAttrs: {
    pname = "swift-testing";
    version = swift_release;

    outputs = [
      "out"
      "include"
    ];

    src = fetchFromGitHub {
      owner = "swiftlang";
      repo = "swift-testing";
      tag = "swift-${finalAttrs.version}-RELEASE";
      hash = "sha256-445tgO3jF1ZILoSNosYtn2RN+5gYA1QRXaznNXLzans=";
    };

    patches = [ ./patches/0001-gnu-install-dirs.patch ];

    postPatch = ''
      # Need to reference $include, so this can’t be substituted by `replaceVars`.
      substituteInPlace CMakeLists.txt --replace-fail '@include@' "''${!outputInclude}"
    '';

    cmakeFlags = [
      (lib.cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
    ];

    buildInputs = [ (lib.getInclude swift-syntax) ];
  })
