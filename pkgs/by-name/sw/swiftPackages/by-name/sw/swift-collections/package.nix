{
  lib,
  fetchFromGitHub,
  mkSwiftPackage,
  stdenv,
}:

mkSwiftPackage.override { build-system = "cmake"; } (finalAttrs: {
  pname = "swift-collections";
  version = "1.3.0";

  outputs = [ "out" "include" ];

  src = fetchFromGitHub {
    owner = "apple";
    repo = "swift-collections";
    tag = finalAttrs.version;
    hash = "sha256-Bhfmf02JbmEdM1TFdM8UGxlouR8kr61WlU1uI2v67v8=";
  };

  postPatch = ''
    # Swift Collections has tweaked its `SwiftSupport.cmake`, which needs to be fixed separately.
    substituteInPlace cmake/modules/SwiftSupport.cmake \
      --replace-fail 'lib/''${swift}/''${COLLECTIONS_PLATFORM}$<$<BOOL:''${COLLECTIONS_INSTALL_ARCH_SUBDIR}>:/''${COLLECTIONS_ARCH}>' \''${CMAKE_INSTALL_LIBDIR}
  '';

  postInstall = ''
    # Install CMake config file for the Swift Collections library.
    mkdir -p mkdir -p "''${!outputInclude}/lib/cmake/SwiftCollections"
    substitute ${./files/SwiftCollectionsConfig.cmake} "''${!outputInclude}/lib/cmake/SwiftCollections/SwiftCollectionsConfig.cmake" \
      --replace-fail '@buildType@' ${if stdenv.hostPlatform.isStatic then "STATIC" else "SHARED"} \
      --replace-fail '@include@' "''${!outputInclude}" \
      --replace-fail '@lib@' "''${!outputLib}" \
      --replace-fail '@swiftPlatform@' ${stdenv.hostPlatform.swift.platform}
  '';

  meta = {
    homepage = "https://github.com/apple/swift-collections";
    description = "Commonly used data structures for Swift";
    license = lib.licenses.asl20;
    teams = [ lib.teams.swift ];
  };
})
