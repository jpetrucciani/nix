# This overlay provides general CLI tools for use in text transformation and other use cases.
final: prev:
let
  inherit (final) fetchFromGitHub lib isLinux isDarwin;
  shardsDerivation = shards: builtins.toFile "shards.nix" (lib.generators.toPretty { } shards);
in
{
  memzoom = final.callPackage
    ({ stdenv, lib }: stdenv.mkDerivation rec {
      pname = "memzoom";
      version = "1.0";

      src = fetchFromGitHub {
        owner = "jart";
        repo = "cosmopolitan";
        rev = version;
        sha256 = "sha256-7oGtqz6YTJJqBoE4Ql/+qh+5VJ94RwfroCj5Zy8VdIo=";
      };

      buildPhase = ''
        make -j8 o//tool/viz/memzoom.com
      '';

      installPhase = ''
        mkdir -p $out/bin
        cp ./o//tool/viz/memzoom.com $out/bin/memzoom
        cp ./o//tool/viz/memzoom.com.dbg $out/bin/memzoom.com.dbg
        $out/bin/memzoom -h
        $out/bin/memzoom.com.dbg -h
      '';

      meta = with lib; {
        description = "like the less command except designed for binary data with live updates";
        license = licenses.isc;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    })
    { };

  watcher = final.callPackage
    ({ stdenv, clang13Stdenv, lib, fetchFromGitHub }:
      let
        name = "watcher";
        version = "0.5.5";
      in
      (if isLinux then stdenv else clang13Stdenv).mkDerivation {
        inherit name;

        src = fetchFromGitHub {
          owner = "e-dant";
          repo = name;
          rev = "release/${version}";
          sha256 = "sha256-s8MuSUC+TbzfadoiqW11Eh7ZTirFjEtVbIMofD0xRc8=";
        };

        nativeBuildInputs = [ final.cmake ];

        preConfigure = ''
          cd build/in
        '';

        postInstall = "mv $out/bin/{wtr.watcher,watcher}";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Filesystem watcher. Works anywhere. Simple, efficient and friendly.";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      })
    { };

  cgapp = final.callPackage
    ({ lib, buildGo124Module, fetchFromGitHub }:
      buildGo124Module rec {
        pname = "cgapp";
        version = "3.6.2";

        src = fetchFromGitHub {
          owner = "create-go-app";
          repo = "cli";
          rev = "v${version}";
          sha256 = "sha256-m/O2W8jVLJvy3J5Nb3DpcbVh4G2xkJWm0S7gBy+oi2k=";
        };

        ldflags = [
          "-s"
          "-w"
        ];

        vendorHash = "sha256-clAeO/J6dN6M2AT5agp2OCruApBIX7byBaUeEeusN4c=";

        nativeBuildInputs = [ final.installShellFiles ];

        postInstall = ''
          installShellCompletion --cmd cgapp \
            --bash <($out/bin/cgapp completion bash) \
            --fish <($out/bin/cgapp completion fish) \
            --zsh  <($out/bin/cgapp completion zsh)
        '';

        doCheck = false;

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Create a new production-ready project with backend, frontend and deploy automation";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  migrate-go = final.callPackage
    ({ lib, buildGo124Module, fetchFromGitHub }:
      buildGo124Module rec {
        pname = "migrate";
        version = "4.15.2";

        src = fetchFromGitHub {
          owner = "golang-migrate";
          repo = "migrate";
          rev = "v${version}";
          sha256 = "sha256-nVR6zMG/a4VbGgR9a/6NqMNYwFTifAZW3F6rckvOEJM=";
        };

        ldflags = [
          "-s"
          "-w"
          "-X main.Version=${version}"
          "-extldflags 'static'"
        ];

        tags = [
          "postgres"
          "mysql"
          "pgx"
          "mongodb"
        ];

        vendorHash = "sha256-lPNPl6fqBT3XLQie9z93j91FLtrMjKbHnXUQ6b4lDb4=";

        doCheck = false;

        postInstall = ''
          rm $out/bin/cli
        '';

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Database migrations. CLI and Golang library";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  buffalo = final.callPackage
    ({ lib, buildGo124Module, fetchFromGitHub }:
      buildGo124Module rec {
        pname = "buffalo";
        version = "0.18.14";

        src = fetchFromGitHub {
          owner = "gobuffalo";
          repo = "cli";
          rev = "v${version}";
          sha256 = "sha256-HNJE5TZgfStuX5fyZGAsiOBmE80Fv1uH2DUiBQ+2Geo=";
        };

        ldflags = [
          "-s"
          "-w"
        ];

        vendorHash = "sha256-7AZ78upxTn3wqsHlbyyhQfYqIcW/Op5sLUgqv4AkG9Y=";

        nativeBuildInputs = [ final.installShellFiles ];

        postInstall = ''
          installShellCompletion --cmd buffalo \
            --bash <($out/bin/buffalo completion bash) \
            --fish <($out/bin/buffalo completion fish) \
            --zsh  <($out/bin/buffalo completion zsh)
        '';

        meta = with lib; {
          description = "";
          homepage = "https://github.com/gobuffalo/cli";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  miniss = final.crystal.buildCrystalPackage rec {
    pname = "miniss";
    version = "0.0.2";

    src = fetchFromGitHub {
      owner = "noraj";
      repo = pname;
      rev = version;
      hash = "sha256-hsIuKAlJPCMU02MUm7SNAt4vR/ZT0B4oi8fdGOcdk7A=";
    };

    format = "shards";
    shardsFile = shardsDerivation {
      ameba = {
        url = "https://github.com/crystal-ameba/ameba.git";
        rev = "v1.4.3";
        sha256 = "0pjlnnz8p2qrry80jz7b2rrqqbzv4qwrqksxwr61hg3zajsndkx5";
      };
      docopt = {
        url = "https://github.com/chenkovsky/docopt.cr.git";
        rev = "cbfdc5f3f4d5934664d07513b1a701e1e5046b34";
        sha256 = "0bgnd8cngkqzzpkn5vdn80al4dnpq2sycmvf5in3jfbyisajjx94";
      };
    };

    crystalBinaries.miniss.src = "src/miniss.cr";
    installPhase = ''
      mkdir -p $out/bin
      mv ./bin/miniss $out/bin/.
    '';
  };

}
