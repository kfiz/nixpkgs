{
  lib,
  fetchFromGitHub,
  mkSwiftPackage,
  ncurses,
  sqlite,
  stdenv,
  swift,
  swift-no-swift-driver,
  swift_release,
}:

let
  swiftPlatform = stdenv.hostPlatform.swift.platform;
in

# LLBuild is a dependency to both Swift Compiler Driver and SwiftPM.
# It must be built with CMake and use Swift without swift-driver to avoid dependency cycles.
mkSwiftPackage.override
  {
    swift = swift-no-swift-driver;
    build-system = "cmake";
  }
  (finalAttrs: {
    pname = "swift-llbuild";
    version = swift_release;

    outputs = [
      "out"
      "lib"
      "include"
    ];

    src = fetchFromGitHub {
      owner = "swiftlang";
      repo = "swift-llbuild";
      tag = "swift-${finalAttrs.version}-RELEASE";
      hash = "sha256-nZdiFXYrUiTSlSl6lxNFVpD2x8KGC4OVUUvJSOqH7gU=";
    };

    patches = [ ./patches/gnu-install-dirs.patch ];

    postPatch = ''
      # Disable performance tests, which require XCTest.framework. XCTest.framework is not available.
      substituteInPlace CMakeLists.txt --replace-fail 'add_subdirectory(perftests)' ""

      # Disable building the framework on Darwin, which we don’t use.
      substituteInPlace products/libllbuild/CMakeLists.txt \
        --replace-fail 'if(''${CMAKE_SYSTEM_NAME} MATCHES "Darwin")' "if(FALSE)"

      # Use ncurses instead of curses
      grep -rl 'curses)' -Z | while IFS= read -d "" file; do
        substituteInPlace "$file" --replace-fail 'curses)' 'ncurses)'
      done
    '';

    buildInputs = [
      ncurses
      sqlite
    ];

    postInstall = ''
      # Install the module map for the `llbuild` module.
      mkdir -p "''${!outputInclude}/include"
      cp -v "$NIX_BUILD_TOP/$sourceRoot/products/libllbuild/include/module.modulemap" "''${!outputInclude}/include"

      # Install the swiftmodule (needed to use `llbuildSwift`).
      mkdir -p "''${!outputInclude}/lib/swift/${swiftPlatform}"
      cp -v products/llbuildSwift/llbuildSwift.swiftmodule "''${!outputInclude}/lib/swift/${swiftPlatform}"

      # Install CMake config file for llbuild and llbuildSwift.
      mkdir -p mkdir -p "''${!outputInclude}/lib/cmake/LLBuild"
      substitute ${./files/LLBuildConfig.cmake} "''${!outputInclude}/lib/cmake/LLBuild/LLBuildConfig.cmake" \
        --replace-fail '@buildType@' ${if stdenv.hostPlatform.isStatic then "STATIC" else "SHARED"} \
        --replace-fail '@include@' "''${!outputInclude}" \
        --replace-fail '@lib@' "''${!outputLib}" \
        --replace-fail '@swiftPlatform@' ${swiftPlatform}
    '';

    cmakeFlags = [
      # Defaults to not building shared libs.
      (lib.cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
      # Swift bindings are needed to build swift-driver.
      (lib.cmakeFeature "LLBUILD_SUPPORT_BINDINGS" "Swift")
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      # Defaults to the `buildPlatform` architecture if this is not set.
      (lib.cmakeFeature "CMAKE_OSX_ARCHITECTURES" stdenv.hostPlatform.darwinArch)
    ];

    meta = {
      homepage = "https://github.com/swift/swift-llbuild";
      description = "Low-level build system used by SwiftPM and Xcode";
      license = lib.licenses.asl20;
      teams = [ lib.teams.swift ];
    };
  })
