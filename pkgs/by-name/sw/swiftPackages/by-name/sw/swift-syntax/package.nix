{
  lib,
  fetchFromGitHub,
  mkSwiftPackage,
  stdenv,
  swift-no-testing,
  swift_release,
}:

# The build for Swift Syntax extracts the shared libraries from the compiler, which will be re-linked against this
# derivation. This allows macro-based packages to use the libraries from the compiler.
#stdenvNoCC.mkDerivation
mkSwiftPackage.override
  {
    build-system = "cmake";
    swift = swift-no-testing;
  }
  (finalAttrs: {
    pname = "swift-syntax";
    version = swift_release;

    outputs = [
      "out"
      "include"
    ];

    src = fetchFromGitHub {
      owner = "swiftlang";
      repo = "swift-syntax";
      tag = "swift-${finalAttrs.version}-RELEASE";
      hash = "sha256-DMMVJQj590RGGBkTgA89u01ZP2B8kbJTmfu+oxzYPds=";
    };

    patches = [ ./patches/0001-gnu-install-dirs.patch ];

    cmakeFlags = [
      # Defaults to static, but we want shared libraries by default.
      (lib.cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
      # Build and install the modules.
      (lib.cmakeBool "SWIFTSYNTAX_EMIT_MODULE" true)
    ];

    postBuild = ''
      # This library is inexplicably not built, but it’s part of the install target.
      ninja libSwiftCompilerPlugin${stdenv.hostPlatform.extensions.library}
    '';

    postInstall = ''
      # Install CMake config file for the Swift Collections library.
      mkdir -p mkdir -p "''${!outputInclude}/lib/cmake/SwiftSyntax"
      substitute ${./files/SwiftSyntaxConfig.cmake} "''${!outputInclude}/lib/cmake/SwiftSyntax/SwiftSyntaxConfig.cmake" \
        --replace-fail '@buildType@' ${if stdenv.hostPlatform.isStatic then "STATIC" else "SHARED"} \
        --replace-fail '@include@' "''${!outputInclude}" \
        --replace-fail '@lib@' "''${!outputLib}"
    '';

    meta = {
      homepage = "https://github.com/swiftlang/swift-syntax";
      description = "Swift libraries for parsing Swift source code";
      license = lib.licenses.asl20;
      teams = [ lib.teams.swift ];
    };
  })
