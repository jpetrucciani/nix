final: prev:
with prev;
{
  s3-edit = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
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

        vendorSha256 = "sha256-ZM5Z3yLOwOYpOTyoXmSbyPFBE31F+Jvc6DN4rmHmyt0=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Edit directly a file on Amazon S3 in CLI";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  overflow = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "overflow";
        version = "2.1.0";

        src = fetchFromGitHub {
          owner = "sradley";
          repo = "overflow";
          rev = "v${version}";
          sha256 = "sha256-7grkSLpLpf9WKMXfXjj8F82L6qdlZsfASSXBslQVZeI=";
        };

        vendorSha256 = "sha256-CLJijtBf8iSBpLV2shkb5u5kHSfFXUGKagkwrsT9FJM=";

        meta = with lib; {
          description = "command-line tool for exploiting stack-based buffer overflow vulnerabilities";
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
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "horcrux";
        version = "0.3";

        src = fetchFromGitHub {
          owner = "jesseduffield";
          repo = "horcrux";
          rev = "v${version}";
          sha256 = "sha256-F8zGdjGKVuL/y763a1ZqcdmziGx9PfzXU81RaN7nL+Q=";
        };

        vendorSha256 = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";

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
        version = "1.7.5";
      in
      rustPlatform.buildRustPackage rec {
        inherit pname version;

        src = fetchFromGitHub {
          owner = "LyonSyonII";
          repo = "hunt-rs";
          rev = "v${version}";
          sha256 = "sha256-SIAJpJSRMLxmITE/5X0e+sOm17vnki1C7nPRXCpquic=";
        };

        cargoSha256 = "sha256-HU3gbsYm0dVZfwrXie8QCs5+a925/YildFVO41+YSaI=";

        meta = with lib; {
          description = "simplified find command made with rust";
          # license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      })
    { };

  jaq = prev.callPackage
    ({ lib, stdenv, fetchFromGitHub, rustPlatform }:
      let
        pname = "jaq";
        version = "0.7.0";
      in
      rustPlatform.buildRustPackage rec {
        inherit pname version;

        src = fetchFromGitHub {
          owner = "01mf02";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-lVpNe93/rtEzoeFxlR+bC01SHpHKxBb+fE2yQqUuE9o=";
        };

        cargoSha256 = "sha256-WLI/zZv9dciY9Nx9xqMUjkxzcXVw0tafxRejos8J5v8=";

        meta = with lib; {
          description = "a jq clone focussed on correctness, speed, and simplicity";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      })
    { };

  rare = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "rare";
        version = "0.2.2";

        src = fetchFromGitHub {
          owner = "zix99";
          repo = "rare";
          rev = version;
          sha256 = "sha256-5MSAbFtPgMhE7x/p/9smEU25RCokXQffAhOKCI1zxCM=";
        };

        vendorSha256 = "sha256-mswPEdhuHLjsLFXMczdHiK30Gn4whDrigees4pqUDC4=";

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

        vendorSha256 = "sha256-AruaKBvPmHw13NTr0folQW1HouRVMW5M3gbFWT1tF/s=";

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
        version = "0.2.9";
      in
      (if isLinux then stdenv else clang13Stdenv).mkDerivation {
        inherit name;

        src = fetchFromGitHub {
          owner = "e-dant";
          repo = name;
          rev = "release/${version}";
          sha256 = "sha256-qmFTq3Ue3w+Wti8hjbGXvWLp/I2PEu2zwv5ii18RlH4=";
        };

        nativeBuildInputs = [ cmake ] ++ lib.optional isDarwin darwin.apple_sdk.frameworks.AppKit;

        preConfigure = ''
          cd build/in
        '';

        postInstall = "mv $out/bin/{water.watcher,watcher}";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Filesystem watcher. Works anywhere. Simple, efficient and friendly.";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      })
    { };

  tlsh-go = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      let
        version = "0.3.0";
        date = "2022-12-12";
      in
      buildGo119Module rec {
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

        vendorSha256 = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";

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
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "ov";
        version = "0.13.0";

        src = fetchFromGitHub {
          owner = "noborus";
          repo = "ov";
          rev = "v${version}";
          sha256 = "sha256-vBPhCSor3wGCawz+097Lw29xgW6z5fV5PAMAq7TBiNM=";
        };

        ldflags = [
          "-s"
          "-w"
          "-X main.Version=${version}"
        ];

        vendorSha256 = "sha256-y3oSL1W2cjt6oUVbglHhun3XNCidqb7LTXtoA25+mpo=";

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
    ({ lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
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

        vendorSha256 = "sha256-clAeO/J6dN6M2AT5agp2OCruApBIX7byBaUeEeusN4c=";

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
    ({ lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
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

        vendorSha256 = "sha256-lPNPl6fqBT3XLQie9z93j91FLtrMjKbHnXUQ6b4lDb4=";

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

}
