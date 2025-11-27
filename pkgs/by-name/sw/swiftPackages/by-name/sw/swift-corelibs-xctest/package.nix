{
  lib,
  cmake,
  swift-driver,
  fetchFromGitHub,
  mkSwiftPackage,
  stdenv,
  swift_release,
  swift-no-testing,
}:

# FIXME: fix outputs to match other builds
# Build with CMake instead of SwiftPM to avoid SwiftPM and XCTest mutually depending on each other.
mkSwiftPackage.override { build-system = "cmake"; swift = swift-no-testing; } (finalAttrs: {
  pname = "swift-corelibs-xctest";
  version = swift_release;

  src = fetchFromGitHub {
    owner = "swiftlang";
    repo = "swift-corelibs-xctest";
    tag = "swift-${finalAttrs.version}-RELEASE";
    hash = "sha256-BbzY1kZUaHu7O29c8J7xDuelik6lhqmfSSskvvPZ7R4=";
  };

  cmakeFlags = [
    (lib.cmakeBool "USE_FOUNDATION_FRAMEWORK" true)
  ]
  # Otherwise, Darwin will default to the running macOS version for its deployment target.
  # TODO: Align all SwiftPM packages around a similar deployment target.
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    (lib.cmakeFeature "CMAKE_Swift_FLAGS" "-target arm64-apple-macosx${stdenv.hostPlatform.darwinMinVersion}")
  ];

  meta = {
    description = "Framework for writing unit tests in Swift";
    homepage = "https://github.com/swiftlang/swift-corelibs-xctest";
    platforms = with lib.platforms; darwin ++ linux ++ windows;
    license = lib.licenses.asl20;
    maintainers = lib.teams.swift.members;
  };
})
