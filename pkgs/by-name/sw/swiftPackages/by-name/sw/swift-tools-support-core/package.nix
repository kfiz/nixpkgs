{
  lib,
  mkSwiftPackage,
  fetchFromGitHub,
  stdenv,
  swift,
  swift-no-swift-driver,
  swift_release,
}:

let
  swiftPlatform = stdenv.hostPlatform.swift.platform;
in

# Swift Tools Support Core is a dependency to both Swift Compiler Driver and SwiftPM.
# It must be built with CMake and use Swift without swift-driver to avoid dependency cycles.
mkSwiftPackage.override
  {
    swift = swift-no-swift-driver;
    build-system = "cmake";
  }
  (finalAttrs: {
    pname = "swift-tools-support-core";
    version = swift_release;

    outputs = [
      "out"
      "include"
    ];

    src = fetchFromGitHub {
      owner = "swiftlang";
      repo = "swift-tools-support-core";
      tag = "swift-${finalAttrs.version}-RELEASE";
      hash = "sha256-mV+z5sdG/maUzXUhK1vMtsnLCclcjqyXSMO6J2FjBEg=";
    };

    patches = [
      # Match the dynamic library structure of the SwiftPM build when using CMake.
      ./patches/0001-build-SwiftToolsSupport.patch
    ];

    postPatch = ''
      # Disable using XCTest framework properties that aren’t provided by swift-corelibs-xctest.
      substituteInPlace "Sources/TSCTestSupport/XCTestCasePerf.swift" \
        --replace-fail '#if canImport(Darwin)' '#if false'
    '';

    postInstall = ''
      # Install the swiftmodule.
      mkdir -p "''${!outputInclude}/lib/swift/${swiftPlatform}"
      cp -v swift/*.swiftmodule "''${!outputInclude}/lib/swift/${swiftPlatform}"

      # Install the C module
      mkdir -p "''${!outputInclude}/include"
      cp -v "$NIX_BUILD_TOP/$sourceRoot/Sources/TSCclibc/include"/* "''${!outputInclude}/include"

      # Install CMake config file for the SwiftSupportTools library.
      mkdir -p mkdir -p "''${!outputInclude}/lib/cmake/TSC"
      substitute ${./files/TSCConfig.cmake} "''${!outputInclude}/lib/cmake/TSC/TSCConfig.cmake" \
        --replace-fail '@buildType@' ${if stdenv.hostPlatform.isStatic then "STATIC" else "SHARED"} \
        --replace-fail '@include@' "''${!outputInclude}" \
        --replace-fail '@lib@' "''${!outputLib}" \
        --replace-fail '@swiftPlatform@' ${swiftPlatform}
    '';

    meta = {
      homepage = "https://github.com/swift/swift-tools-support-core";
      description = "Common infrastructure code used by SwiftPM and llbuild";
      license = lib.licenses.asl20;
      teams = [ lib.teams.swift ];
    };
  })
