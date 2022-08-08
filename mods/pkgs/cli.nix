final: prev:
with prev;
let
  inherit (stdenv) isLinux isDarwin isAarch64;
  isM1 = isDarwin && isAarch64;
in
rec {
  gum = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      let
        version = "0.1.0";
        commit = "e0beb050fdc3c1c5073cf7cf2c918980a9a31774";
        date = "2022-07-28";
      in
      buildGo118Module rec {
        inherit version;
        pname = "gum";

        src = fetchFromGitHub {
          owner = "charmbracelet";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-od0jJPfvczlru9hhO8ravGou6yYP91L2k37NYm2hD+k=";
        };

        ldflags = [
          "-s"
          "-w"
          "-X main.Version=${version}"
          "-X main.CommitSHA=${commit}"
        ];

        vendorSha256 = "sha256-uX0CQRqrM0/fj14owcUUpYph2j5ZwJITG53na31N6kg=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "A tool for glamorous shell scripts";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  charm = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      let
        version = "0.12.1";
        commit = "24b4bbdd7ee0a98f2b68973999f47f79799bd368";
        date = "2021-05-06";
      in
      buildGo118Module rec {
        inherit version;
        pname = "charm";

        src = fetchFromGitHub {
          owner = "charmbracelet";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-vNy2ai1s7TKCymYznvT0Wo6lg9qEyDzz8l3SYzScz8g=";
        };

        ldflags = [
          "-s"
          "-w"
          "-X main.Version=${version}"
          "-X main.CommitSHA=${commit}"
        ];

        vendorSha256 = "sha256-6PGdM7aa1BGNZc3M35PJpmrlPUqkykxfTELdgeKcJD4=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "The Charm Tool and Library";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  glow = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      let
        version = "1.4.1";
        commit = "4863f57cea794c62b6667b9d6aec478e9a49080c";
        date = "2021-04-08";
      in
      buildGo118Module rec {
        inherit version;
        pname = "glow";

        src = fetchFromGitHub {
          owner = "charmbracelet";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-qJtZbNvmfN8/YUDUpR81cuHIdxtQe5QalC/hY1wfx1Q=";
        };

        ldflags = [
          "-s"
          "-w"
          "-X main.Version=${version}"
          "-X main.CommitSHA=${commit}"
        ];

        vendorSha256 = "sha256-BANKOeleIz4OHSAKQ0HIEfzOxv+dugdQherHGpnT6lk=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Render markdown on the CLI, with pizzazz!";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  s3-edit = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        pname = "s3-edit";
        version = "0.0.15";

        src = fetchFromGitHub {
          owner = "tsub";
          repo = "s3-edit";
          rev = "v${version}";
          sha256 = "0zhnr0j3a465xd1ck88bhjp7akks821gbln34zyadfik68r8h9wi";
        };

        vendorSha256 = "sha256-zTGti5yUGhD9K/PO3D8mtVqxoeZCR7JdVZjo+UoQRhk=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Edit directly a file on Amazon S3 in CLI";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  q = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      let
        version = "0.8.0";
        commit = "9b19bfd77a2db9e9e8e7f99780cc36a00c70a3ef";
        date = "2022-06-06";
      in
      buildGo118Module rec {
        inherit version;
        pname = "q";

        src = fetchFromGitHub {
          owner = "natesales";
          repo = "q";
          rev = "v${version}";
          sha256 = "sha256-Fh91SeyXFTXQS1E0w0Lb98mm5gas3xjpo3rSzUGKK1E=";
        };

        ldflags = [
          "-s"
          "-w"
          "-X main.version=${version}"
          "-X main.commit=${commit}"
          "-X main.date=${date}"
        ];

        vendorSha256 = "sha256-jBPCZ2vnI6gnRdnKkWzrh8mYwxp3Xfvyd28ZveAYZdc=";
        doCheck = false;

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "A tiny command line DNS client with support for UDP, TCP, DoT, DoH, DoQ and ODoH";
          license = licenses.gpl3Only;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  overflow = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
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

  prospector-177 = (import
    (fetchFromGitHub {
      name = "frozen-prospector";
      owner = "jpetrucciani";
      repo = "nix";
      rev = "58e698a20ba4cc8b58a9e08e359cc413e2868a6b";
      sha256 = "02z5hmbh0zag6smzsyd1pxgzzw84vnrdiqww3jyk3iwk6abkzjh6";
    })
    { }).prospector-176; # i memed myself here, but this works for now

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
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
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
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
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
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
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

  spacectl = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        pname = "spacectl";
        version = "0.10.0";

        src = fetchFromGitHub {
          owner = "spacelift-io";
          repo = "spacectl";
          rev = "v${version}";
          sha256 = "sha256-Mba8So8VJAxZ2VSH9T6iI2wUV1eRlGnP1V5COfjN/NE=";
        };

        vendorSha256 = "sha256-87uMH7w8XA4WB485nnkEQ6sJDXy8NRECPEUGv80dAhg=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Spacelift client and CLI";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

}
