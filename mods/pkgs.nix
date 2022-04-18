prev: next:
with next;
rec {
  inherit (stdenv) isLinux isDarwin isAarch64;

  wordle = pkgs.callPackage
    ({ pkgs
     , lib
     , fetchFromGitHub
     , rustPlatform
     }:
      let src = fetchFromGitHub {
        owner = "mozilla";
        repo = "nixpkgs-mozilla";
        rev = "f233fdc4ff6ba2ffeb1e3e3cd6d63bb1297d6996";
        sha256 = "1rzz03h0b38l5sg61rmfvzpbmbd5fn2jsi1ccvq22rb76s1nbh8i";
      };
      in
      with import "${src.out}/rust-overlay.nix" pkgs pkgs;
      rustPlatform.buildRustPackage rec {
        pname = "wordle";
        version = "0.1.7";

        nativeBuildInputs = [
          (rustChannelOf {
            date = "2022-02-07";
            channel = "nightly";
            sha256 = "sha256-JhZoPsscpTcw2T/gpeXCMhT/y4nx7EJZ/+1U+Ea5c88=";
          }).rust
        ];

        src = fetchFromGitHub {
          owner = "conradludgate";
          repo = pname;
          rev = "208c80bb3f15f4adf9c740611a612ef65df988ac";
          sha256 = "sha256-2iAtx8C5YJxwacl6JoITS46+zV1oyWnOqbdh72/Cmgs=";
        };

        cargoSha256 = "sha256-ioj2m1DjTnwWVaqVqKP9NBLg82SX763ypEBNBfG3rRg=";
        doCheck = false;

        meta = with lib; {
          description = "Wordle TUI in Rust";
        };
      }
    )
    { };

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

        # vendorSha256 = lib.fakeSha256;
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

        # vendorSha256 = lib.fakeSha256;
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
        version = "0.5.7";
        commit = "dac93ed3b58341fbff3464d5a570d0fec0ad3432";
        date = "2022-04-17";
      in
      buildGoModule rec {
        inherit version;
        pname = "q";

        src = fetchFromGitHub {
          owner = "natesales";
          repo = "q";
          rev = "v${version}";
          sha256 = "06vax2cl1kj8myml0vc6rlibirshh1f3sjxwnlcnqsg9bii68k27";
        };

        ldflags = [
          "-s"
          "-w"
          "-X main.version=${version}"
          "-X main.commit=${commit}"
          "-X main.date=${date}"
        ];

        vendorSha256 = "sha256-onggtOs2ri4VxCPDSehkfiAf6xMjKZHKh8qeNN4tf4A=";
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

  _caddy_plugins = [
    { name = "github.com/greenpau/caddy-security"; version = "v1.0.16"; }
    { name = "github.com/lindenlab/caddy-s3-proxy"; version = "v0.5.6"; }
  ];
  _caddy_patch_main = prev.lib.strings.concatMapStringsSep "\n"
    ({ name, version }: ''
      sed -i '/plug in Caddy modules here/a\\t_ "${name}"' cmd/caddy/main.go
    '')
    _caddy_plugins;
  _caddy_patch_goget = prev.lib.strings.concatMapStringsSep "\n"
    ({ name, version }: ''
      go get ${name}@${version}
    '')
    _caddy_plugins;
  xcaddy = caddy.override {
    buildGoModule = args: buildGoModule (args // {
      vendorSha256 = "sha256-QYbVQfvmWQtaakNoa5B7e4XdyQfPaCrZyEUt6kYPKXs=";
      overrideModAttrs = _: {
        preBuild = ''
          ${_caddy_patch_main}
          ${_caddy_patch_goget}
        '';
        postInstall = "cp go.mod go.sum $out/";
      };
      postInstall = ''
        ${args.postInstall}
        sed -i -E '/Group=caddy/aEnvironmentFile=/etc/default/caddy' $out/lib/systemd/system/caddy.service
      '';
      postPatch = _caddy_patch_main;
      preBuild = "cp vendor/go.mod vendor/go.sum .";
    });
  };

  semgrep-core = pkgs.callPackage
    ({ lib, fetchzip, stdenvNoCC, isDarwin }:
      stdenvNoCC.mkDerivation rec {
        pname = "semgrep";
        version = "0.83.0";

        _arch = if isDarwin then "osx.zip" else "ubuntu-16.04.tgz";
        _sha256 = if isDarwin then "sha256-6l5cqbyXSU2GECeMScNuJi8v2uFCNoApCyd71ANokBU=" else "sha256-HTCvxliuCvRuv4OnyKSvfGiNARv1v4l26aR9KAAsGAA=";

        src = fetchzip {
          url = "https://github.com/returntocorp/semgrep/releases/download/v${version}/semgrep-v${version}-${_arch}";
          sha256 = _sha256;
        };

        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          cp * $out/bin
          runHook postInstall
        '';

        meta = with lib; {
          description = "Lightweight static analysis for many languages";
          homepage = "https://semgrep.dev";
          license = licenses.lgpl21Only;
          mainProgram = "semgrep-core";
        };
      }
    )
    { };

  prospector-176 = prev.python39Packages.prospector;
}
