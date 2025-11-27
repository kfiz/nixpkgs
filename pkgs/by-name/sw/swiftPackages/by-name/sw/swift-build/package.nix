{
  lib,
  cmake,
  coreutils,
  darwin,
  diffutils,
  fetchFromGitHub,
  gnused,
  libiconv,
  libtiff,
  llvm_libtool,
  llvmPackages_current,
  ninja,
  oxipng,
  replaceVars,
  sqlite,
  stdenv,
  stdenvNoCC,
  swift,
  swift-argument-parser,
  swift-driver,
  swift-llbuild,
  swift-system,
  swift-tools-support-core,
  swift_release,
  xcbuild,
  mkSwiftPackage,
}:

let
  graphics_cmds = stdenvNoCC.mkDerivation {
    pname = "graphics_cmds";
    version = "1";

    buildCommand = ''
      install -m755 -D -t "$out/bin" ${replaceVars ./extra-bins/copypng { inherit coreutils oxipng; }}
      install -m755 -D -t "$out/bin" ${replaceVars ./extra-bins/tiffutil { inherit libtiff; }}
    '';
  };

  swiftPlatform = stdenv.hostPlatform.swift.platform;
in

# Swift Build is a dependency of SwiftPM. It must be built with CMake to avoid dependency cycles.
mkSwiftPackage.override { build-system = "cmake"; } (finalAttrs: {
  pname = "swift-build";
  version = swift_release;

  outputs = [
    "out"
    "lib"
    "include"
  ];

  src = fetchFromGitHub {
    owner = "swiftlang";
    repo = "swift-build";
    tag = "swift-${finalAttrs.version}-RELEASE";
    hash = "sha256-uwxnn9B/79mCyceKDIdM+iqxKoCHh8dgEijU4NM2MnM=";
  };

  patches = [
    # Remove as many impure paths as possible.
    (replaceVars ./patches/0001-replace-impure-paths.patch {
      inherit (xcbuild) xcrun;
      inherit graphics_cmds;
      coreutils = lib.getBin coreutils;
      diffutils = lib.getBin diffutils;
      gnused = lib.getBin gnused;
      libiconv = lib.getBin libiconv;
      libtool = lib.getBin llvm_libtool;
      llvm = lib.getBin llvmPackages_current.llvm;
      shell_cmds = lib.getBin darwin.shell_cmds;
      sigtool = lib.getBin darwin.sigtool;
    })
    # Swift Build checks whether the SDK is Xcode by looking at the `DEVELOPER_DIR` path for Xcode.
    # Have it treat store paths as being Xcode SDKs so that the nixpkgs SDK is treated as a Darwin platform.
    (replaceVars ./patches/0002-treat-nixpkgs-sdk-as-xcode.patch {
      store-dir = builtins.storeDir;
    })
    # Don’t look in the build directory for bundles. Look only in the store.
    ./patches/0003-find-bundles-in-store.patch
  ];

  # FIXME: Make this a patch
  postPatch = ''
    # Allow Swift Build to find `SWBBuildServiceBundle` in `$out/libexec`.
    substituteInPlace Sources/SwiftBuild/SWBBuildServiceConnection.swift \
      --replace-fail 'Bundle(for: SWBBuildServiceConnection.self).bundleURL.deletingLastPathComponent()' 'URL(filePath: "@lib@/libexec")' \
      --replace-fail 'Bundle.main.executableURL?.deletingLastPathComponent()' '.some(URL(filePath: "@lib@/libexec"))?' \
      --replace-fail '@lib@' "''${!outputLib}"
  '';

  cmakeFlags = [
    # The CMake hook doesn’t set `${CMAKE_INSTALL_DATADIR}` to a store path, so it needs to be specified manually.
    (lib.cmakeFeature "CMAKE_INSTALL_DATADIR" "${placeholder "lib"}/share")
  ];

  buildInputs = [
    sqlite
    (lib.getInclude swift-argument-parser)
    (lib.getInclude swift-driver)
    (lib.getInclude swift-llbuild)
    (lib.getInclude swift-system)
    (lib.getInclude swift-tools-support-core)
  ];

  # Needed for `fixDarwinDylibNames` to work.
  env.NIX_LDFLAGS = lib.optionalString stdenv.hostPlatform.isDarwin "-headerpad_max_install_names";

  postInstall = ''
    mkdir -p "''${!outputLib}/libexec"
    mv "''${!outputBin}/bin/SWBBuildServiceBundle" "''${!outputLib}/libexec/SWBBuildServiceBundle"

    # Install the swiftmodules.
    mkdir -p "''${!outputInclude}/lib/swift/${swiftPlatform}"
    cp -v swift/*.swiftmodule "''${!outputInclude}/lib/swift/${swiftPlatform}"

    # Install the C module
    mkdir -p "''${!outputInclude}/include"
    cp -v "$NIX_BUILD_TOP/$sourceRoot/Sources/SWBCLibc/include"/*.h "''${!outputInclude}/include"
    cp -v "$NIX_BUILD_TOP/$sourceRoot/Sources/SWBCSupport"/*.h "''${!outputInclude}/include"
    cat \
      "$NIX_BUILD_TOP/$sourceRoot/Sources/SWBCLibc/include/module.modulemap" \
      "$NIX_BUILD_TOP/$sourceRoot/Sources/SWBCSupport/module.modulemap" \
      > "''${!outputInclude}/include/module.modulemap"

    # Install CMake config file for the Swift Build library.
    mkdir -p mkdir -p "''${!outputInclude}/lib/cmake/SwiftBuild"
    substitute ${./files/SwiftBuildConfig.cmake} "''${!outputInclude}/lib/cmake/SwiftBuild/SwiftBuildConfig.cmake" \
      --replace-fail '@buildType@' ${if stdenv.hostPlatform.isStatic then "STATIC" else "SHARED"} \
      --replace-fail '@include@' "''${!outputInclude}" \
      --replace-fail '@lib@' "''${!outputLib}" \
      --replace-fail '@swiftPlatform@' ${swiftPlatform}
  '';

  meta = {
    homepage = "https://github.com/apple/swift-build";
    description = "High-level build system based on llvbuild";
    license = lib.licenses.asl20;
    teams = [ lib.teams.swift ];
  };
})
