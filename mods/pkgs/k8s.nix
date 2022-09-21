final: prev:
with prev;
let
  inherit (stdenv) isLinux isDarwin isAarch64;
  isM1 = isDarwin && isAarch64;
in
rec {
  katafygio = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "katafygio";
        version = "0.8.3";

        src = fetchFromGitHub {
          owner = "bpineau";
          repo = "katafygio";
          rev = "v${version}";
          sha256 = "sha256-fRMXRKr620l7Y6uaYur3LbCGgLeSJ27zEGK0Zq7LZEY=";
        };

        vendorSha256 = "sha256-4hf6OueNHkReXdn9RuO4G4Zrpghp45YkuEwmci4wjz8=";

        ldflags = [
          "-s"
          "-w"
          "-X github.com/bpineau/katafygio/cmd.version=${version}"
        ];

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Dump, or continuously backup Kubernetes objects as yaml files in git";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  goldilocks = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "goldilocks";
        version = "4.3.3";

        src = fetchFromGitHub {
          owner = "FairwindsOps";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-M6SRXkr9hPXKwO+aQ1xYj5NUrRRo4g4vMi19XwINDXw=";
        };

        vendorSha256 = "sha256-pz+gjNvXsaFGLYWCPaa5zOc2TUovNaTFrvT/dW49KuQ=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Get your resource requests 'Just Right'";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  cyclonus = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "cyclonus";
        version = "0.5.0";

        src = fetchFromGitHub {
          owner = "mattfenwick";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-Q6FFSb2iczJQKFx6AVs3nsZfNE6qJ9YKgajeU7MmMfI=";
        };

        vendorSha256 = "sha256-/IQC1vJ4MebuNp+3hvTz85w1guq5e58XM/KMQKWWQoI=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "tools for understanding, measuring, and applying network policies effectively in kubernetes";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  rbac-tool = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "rbac-tool";
        version = "1.9.0";

        src = fetchFromGitHub {
          owner = "alcideio";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-EujU0Ljr+VhGQ3VMhpdP/mikHFKVARR2vRl94/tZ7As=";
        };

        vendorSha256 = "sha256-nADcFaVdC3UrZxqrwqjcNho/80n856Co2KG0AknflWM=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Visualize, Analyze, Generate & Query RBAC policies in Kubernetes";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  kubectl = prev.kubectl.override {
    kubernetes = (prev.kubernetes.override { buildGoModule = buildGo119Module; }).overrideAttrs (old: rec {
      version = "1.25.2";

      src = fetchFromGitHub {
        owner = "kubernetes";
        repo = "kubernetes";
        rev = "v${version}";
        sha256 = "sha256-L69lm0gfixVKILjyDfC6XXWUiEcPZJyl6hvG2QxJOQQ=";
      };
    });
  };

  gke-gcloud-auth-plugin = prev.callPackage
    ({ stdenvNoCC, callPackage, fetchurl, autoPatchelfHook, openssl, lib }:
      let
        dists = {
          aarch64-darwin = {
            arch = "arm";
            short = "darwin";
            sha256 = "0kgzzqvvc7i0yixfzgdal9ya1d0ylhds4kkvqz2i3rpjm6dmhv7n";
          };

          aarch64-linux = {
            arch = "arm";
            short = "linux";
            sha256 = "1kh31r2k3pw3nwzmirdg6xswbj3hg7kg7vi8zhac5fykkq2jli7c";
          };

          x86_64-darwin = {
            arch = "x86_64";
            short = "darwin";
            sha256 = "01d4h40fhbwddsdpm2vd0xkwaa7wi0pl96wkxgciwi8v4yfz9ia9";
          };

          x86_64-linux = {
            arch = "x86_64";
            short = "Linux";
            sha256 = "1ia9xrxk92qkv113f6a0h9h36sgdhniah0f3f1qdpwd4xrndc61r";
          };
        };
        dist = dists.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
        pname = "gke-gcloud-auth-plugin";
        owner = "google";
        version = "0.0.1";
        ts = "20220812141601";
      in
      stdenvNoCC.mkDerivation rec {
        inherit pname version;

        src = fetchurl {
          inherit (dist) sha256;
          url = "https://dl.google.com/dl/cloudsdk/channels/rapid/components/google-cloud-sdk-gke-gcloud-auth-plugin-${dist.short}-${dist.arch}-${ts}.tar.gz";
        };

        strictDeps = true;
        nativeBuildInputs = lib.optionals stdenvNoCC.isLinux [ autoPatchelfHook ];

        dontConfigure = true;
        dontBuild = true;

        unpackPhase = ''
          tar xzvf ${src}
        '';
        installPhase = ''
          mkdir -p $out/bin
          mv ./bin/gke-gcloud-auth-plugin $out/bin/gke-gcloud-auth-plugin
        '';
      }
    )
    { };

}
