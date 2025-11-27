{
  lib,
  fetchFromGitHub,
  mkSwiftPackage,
  stdenv,
  swift-no-swift-driver,
  swift-argument-parser,
  swift-llbuild,
  swift-tools-support-core,
  swift-no-testing,
  swift_release,
}:

let
  swiftPlatform = stdenv.hostPlatform.swift.platform;
in

# Swift Driver is a dependency of SwiftPM.
# It must be built with CMake to avoid dependency cycles. It can’t be built with swift-driver for obvious reasons.
mkSwiftPackage.override
  {
    build-system = "cmake";
    swift = swift-no-swift-driver;
  }
  (finalAttrs: {
    pname = "swift-driver";
    version = swift_release;

    outputs = [
      "out"
      "lib"
      "include"
    ];

    src = fetchFromGitHub {
      owner = "swiftlang";
      repo = "swift-driver";
      tag = "swift-${finalAttrs.version}-RELEASE";
      hash = "sha256-CZYqUadpAsAUnCTZElobZS9nlMfCuHiMnac3o0k7hnI=";
    };

    patches = [
      ./patches/0001-gnu-install-dirs.patch
      # Adjust the built libraries to match the way SwiftPM would build the Swift Compiler Driver.
      ./patches/0002-match-swiftpm-products.patch
    ];

    buildInputs = [
      (lib.getInclude swift-argument-parser)
      (lib.getInclude swift-llbuild)
      (lib.getInclude swift-tools-support-core)
    ];

    env.NIX_LDFLAGS = lib.optionalString stdenv.hostPlatform.isDarwin "-headerpad_max_install_names";

    postInstall = ''
      # Install the swiftmodule.
      mkdir -p "''${!outputInclude}/lib/swift/${swiftPlatform}"
      cp -v swift/*.swiftmodule "''${!outputInclude}/lib/swift/${swiftPlatform}"

      # Install CMake config file for the Swift Compiler Driver library.
      mkdir -p mkdir -p "''${!outputInclude}/lib/cmake/SwiftDriver"
      substitute ${./files/SwiftDriverConfig.cmake} "''${!outputInclude}/lib/cmake/SwiftDriver/SwiftDriverConfig.cmake" \
        --replace-fail '@buildType@' ${if stdenv.hostPlatform.isStatic then "STATIC" else "SHARED"} \
        --replace-fail '@include@' "''${!outputInclude}" \
        --replace-fail '@lib@' "''${!outputLib}" \
        --replace-fail '@swiftPlatform@' ${swiftPlatform}
    '';

    meta = {
      mainProgram = "swift-driver";
      homepage = "https://github.com/apple/swift-driver";
      description = "Swift compiler driver written in Swift";
      license = lib.licenses.asl20;
      teams = [ lib.teams.swift ];
    };
  })
