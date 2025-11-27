{
  lib,
  fetchFromGitHub,
  mkSwiftPackage,
  stdenv,
}:

# Swift-ASN1 is a dependency of SwiftPM. It must be built with CMake to avoid dependency cycles.
mkSwiftPackage.override { build-system = "cmake"; } (finalAttrs: {
  pname = "swift-asn1";
  version = "1.5.1";

  outputs = [ "out" "include" ];

  src = fetchFromGitHub {
    owner = "apple";
    repo = "swift-asn1";
    tag = finalAttrs.version;
    hash = "sha256-K9w13dGuw05eNIznbuWB+De067ZotX3yALc5Fit7geQ=";
  };

  postInstall = ''
    # Install CMake config file for the SwiftASN1 library.
    mkdir -p mkdir -p "''${!outputInclude}/lib/cmake/SwiftASN1"
    substitute ${./files/SwiftASN1Config.cmake} "''${!outputInclude}/lib/cmake/SwiftASN1/SwiftASN1Config.cmake" \
      --replace-fail '@buildType@' ${if stdenv.hostPlatform.isStatic then "STATIC" else "SHARED"} \
      --replace-fail '@include@' "''${!outputInclude}" \
      --replace-fail '@lib@' "''${!outputLib}" \
      --replace-fail '@swiftPlatform@' ${stdenv.hostPlatform.swift.platform}
  '';

  meta = {
    homepage = "https://github.com/apple/swift-asn1";
    description = "An implementation of ASN.1 for Swift";
    license = lib.licenses.asl20;
    teams = [ lib.teams.swift ];
  };
})
