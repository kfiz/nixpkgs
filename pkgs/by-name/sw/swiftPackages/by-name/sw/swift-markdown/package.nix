{
  fetchFromGitHub,
  mkSwiftPackage,
  swift-cmark,
  swift-docc-plugin,
}:

mkSwiftPackage (finalAttrs: {
  pname = "swift-markdown";
  version = "0.7.3";

  src = fetchFromGitHub {
    owner = "apple";
    repo = "swift-markdown";
    tag = finalAttrs.version;
    hash = "sha256-sqo0M5+nLOM2rtHpgwxVFXq1pseTr5bK1cTP8a4ewsg=";
  };

  buildInputs = [
    swift-cmark
    swift-docc-plugin
  ];
})
