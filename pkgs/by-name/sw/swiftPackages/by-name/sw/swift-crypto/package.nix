{
  lib,
  fetchFromGitHub,
  mkSwiftPackage,
  stdenv,
  swift-asn1,
}:

let
  swiftPlatform = stdenv.hostPlatform.swift.platform;
in

mkSwiftPackage.override { build-system = "cmake"; } (finalAttrs: {
  pname = "swift-crypto";
  version = "4.2.0";

  outputs = [
    "out"
    "include"
  ];

  src = fetchFromGitHub {
    owner = "apple";
    repo = "swift-crypto";
    tag = finalAttrs.version;
    hash = "sha256-fdWNuaECRf317rhqTyB7xUTxncYQAd9NwfH3ZGtOflA=";
  };

  patches = [
    # Install _CryptoExtras and CryptoBoringWrapper
    ./patches/0001-install-missing-modules.patch
  ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail '/usr/bin/ar' '$ENV{AR}' \
      --replace-fail '/usr/bin/ranlib' '$ENV{RANLIB}'
  '';

  buildInputs = [ (lib.getInclude swift-asn1) ];

  postInstall = ''
    # Install CMake config file for the Swift Crypto library.
    mkdir -p mkdir -p "''${!outputInclude}/lib/cmake/SwiftCrypto"
    substitute ${./files/SwiftCryptoConfig.cmake} "''${!outputInclude}/lib/cmake/SwiftCrypto/SwiftCryptoConfig.cmake" \
      --replace-fail '@buildType@' ${if stdenv.hostPlatform.isStatic then "STATIC" else "SHARED"} \
      --replace-fail '@include@' "''${!outputInclude}" \
      --replace-fail '@lib@' "''${!outputLib}" \
      --replace-fail '@swiftPlatform@' ${swiftPlatform}
  '';

  meta = {
    homepage = "https://github.com/apple/swift-crypto";
    description = "Open-source implementation of most of CryptoKit for Swift";
    license = lib.licenses.asl20;
    teams = [ lib.teams.swift ];
  };
})
