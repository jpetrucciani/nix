final: prev:
with prev;
{
  regula = prev.callPackage
    ({ lib, buildGo120Module, fetchFromGitHub }:
      buildGo120Module rec {
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

  gofakes3 = prev.callPackage
    ({ lib, buildGo120Module, fetchFromGitHub }:
      buildGo120Module rec {
        pname = "gofakes3";
        version = "0.0.0";

        src = fetchFromGitHub {
          owner = "johannesboyne";
          repo = pname;
          rev = "c0edf658332badad9eb3a69f44dbdcbfec487a68";
          sha256 = "sha256-aToCIEkjfoQzG5+RyiLCK5IyEYyj3rJ9OoSm8lRMiVc=";
        };

        ldflags = [
          "-s"
          "-w"
        ];

        vendorHash = "sha256-5Q2X0Wl/ltpP5SFr9TUbirISNL7IAyaDUkcESwqss/g=";

        meta = with lib; {
          description = "A simple fake AWS S3 object storage (used for local test-runs against AWS S3 APIs)";
          homepage = "https://github.com/johannesboyne/gofakes3";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  goaws = prev.callPackage
    ({ lib, buildGo120Module, fetchFromGitHub }:
      buildGo120Module rec {
        pname = "goaws";
        version = "0.4.1";

        src = fetchFromGitHub {
          owner = "Admiral-Piett";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-f0iEz/V/bnTxuXDo7X6yxQCBAhRyAEFzQoTC9ZB/9pM=";
        };

        vendorHash = "sha256-VqRRCQKtqhRtxG8uJrf332vXr1Lo0ivu8UNWf6y/K2s=";

        ldflags = [
          "-s"
          "-w"
        ];

        postInstall = ''
          mv $out/bin/cmd $out/bin/goaws
        '';

        meta = with lib; {
          description = "AWS (SQS/SNS) Clone for Development testing";
          homepage = "https://github.com/Admiral-Piett/goaws";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

}
