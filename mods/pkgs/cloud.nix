# cloud related experimental tools
final: prev:
let
  inherit (final) callPackage;
in
{
  regula = callPackage
    ({ lib, buildGo124Module, fetchFromGitHub }:
      buildGo124Module rec {
        pname = "regula";
        version = "2.9.0";
        commit = "5193f8781c63e5f79dc8981f7ee9dfa35585dd9e";

        src = fetchFromGitHub {
          owner = "fugue";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-Xls+I8rG11hJx+pacwvrNqZjKLZ5/LlqE4mEPtbnzuo=";
        };

        vendorHash = "sha256-nbEp+U2E00olWZI24U0fsWkdnUtw5Yiz1hysF7ASYh4=";

        ldflags = [
          "-s"
          "-w"
          "-X github.com/fugue/regula/v2/pkg/version.Version=${version}"
          "-X github.com/fugue/regula/v2/pkg/version.GitCommit=${commit}"
        ];

        checkPhase = ''
          runHook preCheck
          for pkg in $(getGoDirs test); do
            echo "[---] $pkg"
            case "$pkg" in
            ./pkg/loader)
              echo "[---] skipping '$pkg' since it is broken"
              ;;
            *)
              buildGoDir test $checkFlags "$pkg"
              ;;
            esac
          done
          runHook postCheck
        '';

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "checks infrastructure as code templates (Terraform, CloudFormation, k8s manifests) for AWS, Azure, Google Cloud, and Kubernetes security and compliance using Open Policy Agent/Rego";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };
}
