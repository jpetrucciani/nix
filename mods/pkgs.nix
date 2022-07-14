final: prev:
with prev;
rec {
  inherit (prev.hax) isLinux isDarwin isM1;

  katafygio = pkgs.callPackage
    ({ stdenv, lib, buildGoModule, fetchFromGitHub }:
      buildGoModule rec {
        version = "0.8.3";
        pname = "katafygio";

        src = fetchFromGitHub {
          owner = "bpineau";
          repo = "katafygio";
          rev = "v${version}";
          sha256 = "1kpfgzplz1r04y6sdp2njvjy5ylrpybz780vcp7dxywi0y8y2j6i";
        };

        vendorSha256 = "641dqcjPXq+iLx8JqqOzk9JsKnmohqIWBeVxT1lUNWU=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Dump, or continuously backup Kubernetes objects as yaml files in git";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  horcrux = pkgs.callPackage
    ({ stdenv, lib, buildGoModule, fetchFromGitHub }:
      buildGoModule rec {
        version = "0.3";
        pname = "horcrux";

        src = fetchFromGitHub {
          owner = "jesseduffield";
          repo = "horcrux";
          rev = "v${version}";
          sha256 = "1r1gwzg6hlfdagbzqgbxdj4b7nbid9b6pdxyrgzy4mla65vcdk0p";
        };

        vendorSha256 = "pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Split your file into encrypted fragments so that you don't need to remember a passcode";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  s3-edit = pkgs.callPackage
    ({ stdenv, lib, buildGoModule, fetchFromGitHub }:
      buildGoModule rec {
        version = "0.0.15";
        pname = "s3-edit";

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

  q = pkgs.callPackage
    ({ stdenv, lib, buildGoModule, fetchFromGitHub }:
      let
        version = "0.8.0";
        commit = "";
        date = "2022-06-06";
      in
      buildGoModule rec {
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

  memzoom = pkgs.callPackage
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

  prospector-177 = (import
    (fetchFromGitHub {
      name = "frozen-prospector";
      owner = "jpetrucciani";
      repo = "nix";
      rev = "58e698a20ba4cc8b58a9e08e359cc413e2868a6b";
      sha256 = "02z5hmbh0zag6smzsyd1pxgzzw84vnrdiqww3jyk3iwk6abkzjh6";
    })
    { }).prospector-176; # i memed myself here, but this works for now


  # haproxy overrides
  haproxy-pin = { version, sha256 }: haproxy.overrideAttrs (attrs: rec {
    inherit version;
    src = fetchurl {
      inherit sha256;
      url = "https://www.haproxy.org/download/${lib.versions.majorMinor version}/src/${attrs.pname}-${version}.tar.gz";
    };
  });
  haproxy-2-2-24 = haproxy-pin {
    version = "2.2.24";
    sha256 = "sha256-DoBzENzjpSk9JFTZwbceuNFkcjBbZvB2s4S1CFix5/k=";
  };

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

  overflow = pkgs.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        version = "2.1.0";
        pname = "overflow";

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

  pocketbase = pkgs.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        version = "0.1.0";
        pname = "pocketbase";

        src = fetchFromGitHub {
          owner = "pocketbase";
          repo = "pocketbase";
          rev = "3d07f0211dc74710affd9154f61728d77cfb6f4c";
          sha256 = "sha256-jsZ07brePIr39mi37ZX3uUIjlWmViPwqU7g/jBqAkaw=";
        };

        doCheck = false;

        ldflags = [
          "-s"
          "-w"
        ];

        postBuild = ''
          go build ./examples/base/main.go
        '';
        postInstall = ''
          mkdir -p $out/bin
          mv ./main $out/bin/pocketbase
        '';
        vendorSha256 = "sha256-8IiY/gjK8m2ntOXyG84HMiyT4GK3CgDTRG1DB+v0jAs=";

        meta = with lib; {
          description = "open source realtime backend in 1 file";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  sherlock = pkgs.callPackage
    ({ stdenv, lib, fetchFromGitHub, python3 ? python310 }:
      let
        py = python3.withPackages (p: with p; [
          certifi
          colorama
          openpyxl
          pandas
          pysocks
          requests
          requests-futures
          stem
          torrequest
        ]);
      in
      stdenv.mkDerivation rec {
        pname = "sherlock";
        version = "a4c0fb05aa1873d06c3740b7f19df82c90a814d4";
        src = fetchFromGitHub {
          owner = "sherlock-project";
          repo = pname;
          rev = version;
          sha256 = "sha256-MLPtfV+ep/02Y9fG1F9YkaikpkhMoeb4bGpRMaQ6x/I=";
        };
        passAsFile = "script";
        script = ''
          ${py}/bin/python ${src}/sherlock $@
        '';
        installPhase = ''
          mkdir -p $out/bin
          echo '#!/bin/bash' >$out/bin/${pname}
          cat $scriptPath >>$out/bin/${pname}
          chmod +x $out/bin/${pname}
        '';
      })
    { };

  bun = pkgs.callPackage
    ({ stdenv, lib, autoPatchelfHook }:
      let
        pname = "bun";
        version = "0.1.4";
        arch = if isM1 then "darwin-aarch64" else if isDarwin then "darwin-x64" else "linux-x64";
        url = "https://github.com/Jarred-Sumner/bun/releases/download/${pname}-v${version}/${pname}-${arch}.zip";
        sha256 =
          if isM1 then "1wi7g07idr3h7kksxvwizw1zj3pq73w2kkr39934rhjx0bji2pas"
          else if isDarwin then "170ggr1sl2ip13xcrf5w4y4a82ms8vn4kzii7lj2h31wn79wh6ml"
          else "0sapwpfqm7br00g36md2fqi9faa9vl58a3bqb9m06hrnahzqwj49";
      in
      stdenv.mkDerivation rec {
        inherit pname version;
        src = builtins.fetchTarball {
          inherit url sha256;
        };
        nativeBuildInputs = [
          autoPatchelfHook
        ];
        installPhase = ''
          mkdir -p $out/bin
          mv ./bun $out/bin/bun
        '';
      })
    { };
}
