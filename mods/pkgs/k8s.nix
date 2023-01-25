final: prev:
with prev;
{
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

  gke-gcloud-auth-plugin = prev.callPackage
    ({ stdenvNoCC, callPackage, fetchurl, autoPatchelfHook, openssl, lib }:
      let
        dists = {
          aarch64-darwin = {
            arch = "arm";
            short = "darwin";
            sha256 = "1jr5fp5ilkslf1x37nyzkk3w895i5mx6sx2x35dqdczkai5hf9d3";
          };

          aarch64-linux = {
            arch = "arm";
            short = "linux";
            sha256 = "1why4cpp23kjryk2hhnfg5zvwcv6zbhp8w537c75av6cfqgm59pn";
          };

          x86_64-darwin = {
            arch = "x86_64";
            short = "darwin";
            sha256 = "0g38w0yniy08w9f202a1vixqpf6m5g09qwzzm0m81c9cpc5f5ic0";
          };

          x86_64-linux = {
            arch = "x86_64";
            short = "Linux";
            sha256 = "1y7s1078m8l3pypgg0z447pv8i2ka7gblzi0dwm00kjyb5sgzmdz";
          };
        };
        dist = dists.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
        pname = "gke-gcloud-auth-plugin";
        version = "0.4.0";
        ts = "20221014224505";
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

  murre = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "murre";
        version = "0.0.3";

        src = fetchFromGitHub {
          owner = "groundcover-com";
          repo = "murre";
          rev = "v${version}";
          sha256 = "sha256-GTOnNubjIwazj9P65wcD7NtYzx7xGPZTeJ+mLuLgZjw=";
        };

        vendorSha256 = "sha256-d1djlrtFm16ofpaRqPZ0loCLb38RgkopIl/woZr5OuE=";

        ldflags = [
          "-s"
          "-w"
        ];

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "on-demand, scaleable source of container resource metrics for K8s";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  kubeshark = prev.callPackage
    ({ stdenvNoCC, callPackage, fetchurl, autoPatchelfHook, lib }:
      let
        dists = {
          aarch64-darwin = {
            arch = "arm64";
            short = "darwin";
            sha256 = "02nm3iwbwqh2w71hbfqjhfwns9j6014crg4y1m4gd9n3wpdjd5a0";
          };
          aarch64-linux = {
            arch = "arm64";
            short = "linux";
            sha256 = "1fpwg605j7w1r9zw35i8d4mz5126nhaipmhrhf91hj5p4v9aq2hv";
          };
          x86_64-darwin = {
            arch = "amd64";
            short = "darwin";
            sha256 = "1dn71d0is2j85z88zh2qv2z0dzk1i34msq0i4ac1vm850i34hbmp";
          };
          x86_64-linux = {
            arch = "amd64";
            short = "linux";
            sha256 = "11cqw8visi7ymw23ys6i9g8ndp5zywcrhrx9rrkhzgpkjyzghjzv";
          };
        };
        dist = dists.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
        pname = "kubeshark";
        owner = "kubeshark";
        version = "37.0";
      in
      stdenvNoCC.mkDerivation rec {
        inherit pname version;

        src = fetchurl {
          inherit (dist) sha256;
          url = "https://github.com/${owner}/${pname}/releases/download/${version}/${pname}_${dist.short}_${dist.arch}";
        };

        strictDeps = true;
        nativeBuildInputs = [ installShellFiles ] ++ (lib.optionals stdenvNoCC.isLinux [ autoPatchelfHook ]);

        dontConfigure = true;
        dontBuild = true;
        dontUnpack = true;

        installPhase = ''
          mkdir -p $out/bin
          cp $src $out/bin/kubeshark
          chmod +x $out/bin/kubeshark
        '';

        postInstall = ''
          installShellCompletion --cmd kubeshark \
            --bash <($out/bin/kubeshark completion bash) \
            --fish <($out/bin/kubeshark completion fish) \
            --zsh  <($out/bin/kubeshark completion zsh)
        '';

        meta = with lib; {
          license = licenses.mit;
        };
      }
    )
    { };

}
