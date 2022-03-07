{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.2.5";
  pname = "kube-linter";

  src = fetchFromGitHub {
    owner = "stackrox";
    repo = "kube-linter";
    rev = version;
    sha256 = "0yq0ydcdilifbsm1h0hb29lgm7wfyfffmf6gj4l4i5w2kikvlx13";
  };

  vendorSha256 = "sha256-TRZsdsaOtoAsoKsOxPbtVqpWZGFuaGmudIkuj0QGj5k=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description =
      "static analysis tool that checks Kubernetes YAML files and Helm charts to ensure the applications represented in them adhere to best practices";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
