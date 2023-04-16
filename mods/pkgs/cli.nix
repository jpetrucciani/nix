final: prev:
with prev;
let
  shardsDerivation = shards: builtins.toFile "shards.nix" (lib.generators.toPretty { } shards);
in
{
  s3-edit = prev.callPackage
    ({ stdenv, lib, buildGo120Module, fetchFromGitHub }:
      buildGo120Module rec {
        pname = "s3-edit";
        version = "0.0.16";

        src = fetchFromGitHub {
          owner = "tsub";
          repo = "s3-edit";
          rev = "v${version}";
          sha256 = "sha256-BNFbg3IRsLOdakh8d53P0FSOGaGXYJuexECPlCMWCC0=";
        };

        ldflags = [
          "-s"
          "-w"
          "-X cmd.version=${version}"
        ];

        vendorHash = "sha256-ZM5Z3yLOwOYpOTyoXmSbyPFBE31F+Jvc6DN4rmHmyt0=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Edit directly a file on Amazon S3 in CLI";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  memzoom = prev.callPackage
    ({ stdenv, lib, fetchFromGithub }: stdenv.mkDerivation rec {
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

  horcrux = prev.callPackage
    ({ stdenv, lib, buildGo120Module, fetchFromGitHub }:
      buildGo120Module rec {
        pname = "horcrux";
        version = "0.3";

        src = fetchFromGitHub {
          owner = "jesseduffield";
          repo = "horcrux";
          rev = "v${version}";
          sha256 = "sha256-F8zGdjGKVuL/y763a1ZqcdmziGx9PfzXU81RaN7nL+Q=";
        };

        vendorHash = null;

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Split your file into encrypted fragments so that you don't need to remember a passcode";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  hunt = prev.callPackage
    ({ lib, stdenv, fetchFromGitHub, rustPlatform }:
      let
        pname = "hunt";
        version = "1.7.6";
      in
      rustPlatform.buildRustPackage rec {
        inherit pname version;

        src = fetchFromGitHub {
          owner = "LyonSyonII";
          repo = "hunt-rs";
          rev = "v${version}";
          sha256 = "sha256-mNQY2vp4wNDhVqrFNVS/RBXVi9EMbTZ6pE0Z79dLUeM=";
        };

        cargoSha256 = "sha256-hjvJ9E5U6zGSWUXNDdu0GwUcd7uZeconfjiCSaEzZXU=";

        meta = with lib; {
          description = "simplified find command made with rust";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      })
    { };

  rare = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "rare";
        version = "0.3.0";

        src = fetchFromGitHub {
          owner = "zix99";
          repo = "rare";
          rev = version;
          sha256 = "sha256-TL+oqi/q0ObJN08jJur0aaSqey3p/B7bb57vQYYHnF0=";
        };

        vendorHash = "sha256-4+yvgOGlJ33RV0WNJlYUFf/8ergTflMhSn13EJUmVSk=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description =
            "Realtime regex-extraction and aggregation into common formats such as histograms, bar graphs, numerical summaries, tables, and more";
          license = licenses.gpl3Only;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  comcast = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "comcast";
        version = "1.0.1";

        # this is forked to fix go mod stuff
        src = fetchFromGitHub {
          owner = "jpetrucciani";
          repo = "comcast";
          rev = "93b2589b3e677c4f351c2ee7bf8709ce762ca697";
          sha256 = "sha256-jfVxoKkZscemOdlyQNFXckhlEcl7UZ+MPoIQu2lcUaE=";
        };

        vendorHash = "sha256-AruaKBvPmHw13NTr0folQW1HouRVMW5M3gbFWT1tF/s=";

        # disable checks because they need networking
        doCheck = false;

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Simulating shitty network connections so you can build better systems";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  watcher = prev.callPackage
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

        nativeBuildInputs = [ cmake ] ++ lib.optional isDarwin darwin.apple_sdk.frameworks.AppKit;

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

  tlsh-go = prev.callPackage
    ({ stdenv, lib, buildGo120Module, fetchFromGitHub }:
      let
        version = "0.3.0";
        date = "2022-12-12";
      in
      buildGo120Module rec {
        inherit version;
        pname = "tlsh-go";

        src = fetchFromGitHub {
          owner = "glaslos";
          repo = "tlsh";
          rev = "v${version}";
          sha256 = "sha256-fDFMF7ajhJ0veylJPoSxOtkkdwcRmR9G7MJgk5fnAdY=";
        };

        ldflags = [
          "-s"
          "-w"
          "-X main.VERSION=${version}"
          "-X main.BUILDDATE=${date}"
        ];

        postInstall = ''
          mv $out/bin/app $out/bin/tlsh
        '';

        vendorHash = null;

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "TLSH lib in Golang";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  ov = prev.callPackage
    ({ stdenv, lib, buildGo120Module, fetchFromGitHub }:
      buildGo120Module rec {
        pname = "ov";
        version = "0.14.1";

        src = fetchFromGitHub {
          owner = "noborus";
          repo = "ov";
          rev = "v${version}";
          sha256 = "sha256-ow2tIML7+x0X3FSpr4UQ8bzzYhZJZ9pZL8eNReEjitQ=";
        };

        ldflags = [
          "-s"
          "-w"
          "-X main.Version=${version}"
        ];

        vendorHash = "sha256-X2/kcXxdGwFvdiTu1MGyv90OngWmR/xR2YtjvmLkiVE=";

        nativeBuildInputs = [ installShellFiles ];

        postInstall = ''
          installShellCompletion --cmd ov \
            --bash <($out/bin/ov --completion bash) \
            --fish <($out/bin/ov --completion fish) \
            --zsh  <($out/bin/ov --completion zsh)
        '';

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Feature-rich terminal-based text viewer";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  cgapp = prev.callPackage
    ({ lib, buildGo120Module, fetchFromGitHub }:
      buildGo120Module rec {
        pname = "cli";
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

        nativeBuildInputs = [ installShellFiles ];

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

  migrate-go = prev.callPackage
    ({ lib, buildGo120Module, fetchFromGitHub }:
      buildGo120Module rec {
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

  lastresort = prev.callPackage
    ({ lib, stdenv, fetchFromGitHub, rustPlatform }:
      let
        pname = "lastresort";
        version = "0.4.0";
      in
      rustPlatform.buildRustPackage rec {
        inherit pname version;

        src = fetchFromGitHub {
          owner = "ctsrc";
          repo = "Base256";
          rev = "v${version}";
          sha256 = "sha256-wwwm7x42Fk7Hsf1rE+dKLQJGTkmZnbFGDl5OX3gJ1rU=";
        };

        cargoSha256 = "sha256-tt5B8jt3DSb7LWCCDWITpe9XD/EmFbGubUmlysFqRuM=";

        meta = with lib; {
          description = "Encode and decode data in base 256 easily typed words";
          license = licenses.isc;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      })
    { };

  terraform-cloud-exporter = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "terraform-cloud-exporter";
        version = "2.3.0";

        src = fetchFromGitHub {
          owner = "pacoguzman";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-77ns9cBKr/d7gCZRdizuJm+adkk0WNeCVtKMZMLXmQA=";
        };

        vendorHash = "sha256-aw2Hv3utc/sIZC1E3RDsQcmT+FVIhTWkdU0+dB0/4ho=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Prometheus exporter for Terraform Cloud metrics";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  buffalo = prev.callPackage
    ({ lib, buildGo120Module, fetchFromGitHub }:
      buildGo120Module rec {
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

        nativeBuildInputs = [ installShellFiles ];

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

  miniss = crystal.buildCrystalPackage rec {
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

  bkt = prev.callPackage
    ({ lib, stdenv, fetchFromGitHub, rustPlatform }:
      let
        pname = "bkt";
        version = "0.6.1";
      in
      rustPlatform.buildRustPackage rec {
        inherit pname version;

        src = fetchFromGitHub {
          owner = "dimo414";
          repo = "bkt";
          rev = version;
          sha256 = "sha256-NgNXuTpI1EzgmxKRsqzxTOlQi75BHCcbjFnouhnfDDM=";
        };

        cargoSha256 = "sha256-PvcKviyXtiHQCHgJLGR2Mr+mPpTd06eKWQ5h6eGdl40=";

        meta = with lib; {
          description = "subprocess caching utility";
          homepage = "https://github.com/dimo414/bkt";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      })
    { };
}
