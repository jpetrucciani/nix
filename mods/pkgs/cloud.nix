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
        version = "0.31.8";

        # additional compile-time data
        commit = "200d203146dee0db2f5ed3852f20fd6a2585554d";
        date = "2022-07-14";

        src = fetchFromGitHub {
          owner = "cloudquery";
          repo = "cloudquery";
          rev = "v${version}";
          sha256 = "sha256-6lS0rS6+EbuXJjvSki5U6WHybsdheDqJrNk1TsPB11k=";
        };

        vendorSha256 = "sha256-MWG1LLsZLUphwr+juPxDhVOkLIxf+2HHDNiAzx7IHR8=";

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

  aliyun-cli = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        pname = "aliyun-cli";
        version = "3.0.123";

        src = fetchFromGitHub {
          owner = "aliyun";
          repo = "aliyun-cli";
          rev = "v${version}";
          sha256 = "sha256-68u31s7SsRRT9OQpTqlhAs5Dx+ggbTTSeKYBByiqn6g=";
          fetchSubmodules = true;
        };

        # don't run check as it deletes directories relative to this dir
        doCheck = false;

        # move the output 'main' to the name of the executable
        postInstall = ''
          mv $out/bin/main $out/bin/aliyun
        '';

        vendorSha256 = "sha256-X5r89aI7UdVlzEJi8zaOzwTETwb+XH8dKO6rVe//FNs=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description =
            "A tool to manage and use Alibaba Cloud resources through a command line interface";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

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
