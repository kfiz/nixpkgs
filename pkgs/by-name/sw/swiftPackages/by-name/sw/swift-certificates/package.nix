{
  lib,
  fetchFromGitHub,
  mkSwiftPackage,
  stdenv,
  swift-asn1,
  swift-crypto,
}:

mkSwiftPackage.override { build-system = "cmake"; } (finalAttrs: {
  pname = "swift-certificates";
  version = "1.17.0";

  outputs = [
    "out"
    "include"
  ];

  src = fetchFromGitHub {
    owner = "apple";
    repo = "swift-certificates";
    tag = finalAttrs.version;
    hash = "sha256-e68pm5Qn+7NjvFJMvLwi4uJ9XlX+99IdIkmPHlGirAc=";
  };

  buildInputs = [
    (lib.getInclude swift-asn1)
    (lib.getInclude swift-crypto)
  ];

  postInstall = ''
    # Install CMake config file for the Swift Certificates library.
    mkdir -p mkdir -p "''${!outputInclude}/lib/cmake/SwiftCertificates"
    substitute ${./files/SwiftCertificatesConfig.cmake} "''${!outputInclude}/lib/cmake/SwiftCertificates/SwiftCertificatesConfig.cmake" \
      --replace-fail '@buildType@' ${if stdenv.hostPlatform.isStatic then "STATIC" else "SHARED"} \
      --replace-fail '@include@' "''${!outputInclude}" \
      --replace-fail '@lib@' "''${!outputLib}" \
      --replace-fail '@swiftPlatform@' ${stdenv.hostPlatform.swift.platform}
  '';

  meta = {
    homepage = "https://github.com/apple/swift-certificates";
    description = "An implementation of X.509 for Swift";
    license = lib.licenses.asl20;
    teams = [ lib.teams.swift ];
  };
})
