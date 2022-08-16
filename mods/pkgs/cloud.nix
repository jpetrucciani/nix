final: prev:
with prev;
let
  inherit (stdenv) isLinux isDarwin isAarch64;
  isM1 = isDarwin && isAarch64;
in
rec {
  cloudquery = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub, disableTelemetry ? true }:
      buildGo119Module rec {
        pname = "cloudquery";
        version = "0.32.7";

        # additional compile-time data
        commit = "9bf0e274118569a54f91695266ca3e743fe2e88e";
        date = "2022-08-15";

        src = fetchFromGitHub
          {
            owner = "cloudquery";
            repo = "cloudquery";
            rev = "cli/v${version}";
            sha256 = "sha256-eKnNGPewWcr1A9wGpLjpI8nuLJaPZhhthAGv/aFirhs=";
          } + "/cli";

        vendorSha256 = "sha256-Q3FsNQ3dUSKzH2Zd5Nba0pcv/H39BpICDJcJyMulPbs=";

        ldflags = [
          "-s"
          "-w"
          "-X github.com/cloudquery/cloudquery/cli/pkg/core.Version=${version}"
          "-X github.com/cloudquery/cloudquery/cli/cmd.Commit=${commit}"
          "-X github.com/cloudquery/cloudquery/cli/cmd.Date=${date}"
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

        postInstall = ''
          mv $out/bin/cli $out/bin/cloudquery
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
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "regula";
        version = "2.9.0";
        commit = "5193f8781c63e5f79dc8981f7ee9dfa35585dd9e";

        src = fetchFromGitHub {
          owner = "fugue";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-Xls+I8rG11hJx+pacwvrNqZjKLZ5/LlqE4mEPtbnzuo=";
        };

        vendorSha256 = "sha256-nbEp+U2E00olWZI24U0fsWkdnUtw5Yiz1hysF7ASYh4=";

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

  trivy = prev.callPackage
    ({ lib, stdenv, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "trivy";
        version = "0.31.0";

        src = fetchFromGitHub {
          owner = "aquasecurity";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-ggYJVi5miBAHMVb+c750HYCUfOcOsE/9g8LzdCcku5o=";
        };
        vendorSha256 = "sha256-cvDDtWfoc23xHbQRCUu2RuXIA/7rw/jda1p+FSIZwHo=";

        excludedPackages = "misc";

        ldflags = [
          "-s"
          "-w"
          "-X main.version=v${version}"
        ];

        # Tests require network access
        doCheck = false;
        doInstallCheck = true;

        installCheckPhase = ''
          runHook preInstallCheck
          $out/bin/trivy --help
          $out/bin/trivy --version | grep "v${version}"
          runHook postInstallCheck
        '';

        meta = with lib; {
          homepage = "https://github.com/aquasecurity/trivy";
          changelog = "https://github.com/aquasecurity/trivy/releases/tag/v${version}";
          description = "A simple and comprehensive vulnerability scanner for containers, suitable for CI";
          longDescription = ''
            Trivy is a simple and comprehensive vulnerability scanner for containers
            and other artifacts. A software vulnerability is a glitch, flaw, or
            weakness present in the software or in an Operating System. Trivy detects
            vulnerabilities of OS packages (Alpine, RHEL, CentOS, etc.) and
            application dependencies (Bundler, Composer, npm, yarn, etc.).
          '';
          license = licenses.asl20;
          maintainers = with maintainers; [ jk ];
        };
      }
    )
    { };

}
