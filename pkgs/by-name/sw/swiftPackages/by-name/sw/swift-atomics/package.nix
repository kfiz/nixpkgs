{
  fetchFromGitHub,
  mkSwiftPackage,
}:

mkSwiftPackage (finalAttrs: {
  pname = "swift-atomics";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "apple";
    repo = "swift-atomics";
    tag = finalAttrs.version;
    hash = "sha256-SGalN8YFd/3DtU9tr+vK0pqytRB1a8y6NNAgggrjZW4=";
  };
})
