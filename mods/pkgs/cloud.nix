final: prev:
with prev;
let
  inherit (stdenv) isLinux isDarwin isAarch64;
  isM1 = isDarwin && isAarch64;
in
rec {
  cloudquery = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub, disableTelemetry ? true }:
      buildGo118Module rec {
        pname = "cloudquery";
        version = "0.32.1";

        # additional compile-time data
        commit = "d324b37050836c6533a7d208d8e54960fb04e386";
        date = "2022-07-27";

        src = fetchFromGitHub {
          owner = "cloudquery";
          repo = "cloudquery";
          rev = "v${version}";
          sha256 = "sha256-DUaM0x3zzsDU9lAKIpCTP7zF4t1O7J4Lz7oqbmoWKDU=";
        };

        vendorSha256 = "sha256-lBhjCywwAfQRttLLoS4Xsa6KC4abVkeV7J+vbPz9dK0=";

        ldflags = [
          "-s"
          "-w"
          "-X github.com/cloudquery/cloudquery/pkg/core.version=v${version}"
          "-X github.com/cloudquery/cloudquery/cmd.Commit=${commit}"
          "-X github.com/cloudquery/cloudquery/cmd.Date=${date}"
        ];

        preBuild =
          if disableTelemetry then ''
            substituteInPlace ./cmd/root.go \
              --replace '"no-telemetry", false' '"no-telemetry", true' \
              --replace '"no-provider-update", false' '"no-provider-update", true'
          '' else "";

        checkPhase = ''
          runHook preCheck
          for pkg in $(getGoDirs test); do
            echo "[---] $pkg"
            case "$pkg" in
            ./pkg/client|./pkg/policy|./internal/file|./pkg/core/database/postgres)
              echo "[---] skipping '$pkg' test which requires postgres"
              ;;
            ./pkg/ui/console|./internal/getter|./pkg/core|./pkg/core/state|./pkg/plugin/registry)
              echo "[---] skipping '$pkg' test which requires internet"
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
          description = "the open-source cloud asset inventory powered by SQL";
          license = licenses.mpl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      })
    { };

  awscli2 = prev.awscli2.override {
    python3 = prev.awscli2.python // {
      override = args: prev.awscli2.python.override (args // {
        packageOverrides = self: super: args.packageOverrides self super // (
          if stdenv.isDarwin
          then {
            twisted = super.twisted.overrideAttrs (_: { doInstallCheck = false; });
            pyopenssl = super.pyopenssl.overrideAttrs (_: { meta.broken = false; });
          }
          else { }
        );
      });
    };
  };

  regula = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        pname = "regula";
        version = "2.9.0";

        src = fetchFromGitHub {
          owner = "fugue";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-Xls+I8rG11hJx+pacwvrNqZjKLZ5/LlqE4mEPtbnzuo=";
        };

        vendorSha256 = "sha256-nbEp+U2E00olWZI24U0fsWkdnUtw5Yiz1hysF7ASYh4=";
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
