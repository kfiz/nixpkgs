{ stdenv, callPackage, lib, sasl, boost, Security, CoreFoundation, cctools }:

let
  buildMongoDB = callPackage ./mongodb.nix {
    inherit sasl boost Security CoreFoundation cctools stdenv;
  };
in
buildMongoDB {
  version = "5.0.12";
  sha256 = "00z2qaxhrwwl7rvz9c4zimc2wh15rfbg1bq055l9w7389jkkhyqd";
  patches = [
    ./forget-build-dependencies-4-4.patch
    ./asio-no-experimental-string-view-4-4.patch
    ./fix-build-with-boost-1.79-5_0.patch
    ./fix-gcc-Wno-exceptions-5.0.patch
  ];
}
