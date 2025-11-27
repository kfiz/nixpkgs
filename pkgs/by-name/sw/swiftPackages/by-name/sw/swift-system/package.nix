{
  lib,
  fetchFromGitHub,
  mkSwiftPackage,
  stdenv,
}:

mkSwiftPackage.override { build-system = "cmake"; } (finalAttrs: {
  pname = "swift-system";
  version = "1.6.3";

  outputs = [
    "out"
    "include"
  ];

  src = fetchFromGitHub {
    owner = "apple";
    repo = "swift-system";
    tag = finalAttrs.version;
    hash = "sha256-d6j5CDFQLKtjzqfykNgwC0sDKywkQVFlxlG3YyawBwo=";
  };

  patches = [ ./patches/0001-gnu-install-dirs.patch ];

  postInstall = ''
    # Install CMake config file for Swift System.
    mkdir -p mkdir -p "''${!outputInclude}/lib/cmake/SwiftSystem"
    substitute ${./files/SwiftSystemConfig.cmake} "''${!outputInclude}/lib/cmake/SwiftSystem/SwiftSystemConfig.cmake" \
      --replace-fail '@include@' "''${!outputInclude}" \
      --replace-fail '@lib@' "''${!outputLib}" \
      --replace-fail '@swiftPlatform@' ${stdenv.hostPlatform.swift.platform}
  '';

  meta = {
    homepage = "https://github.com/apple/swift-system";
    description = "Low-level APIs and types for Swift";
    license = lib.licenses.asl20;
    teams = [ lib.teams.swift ];
  };
})
