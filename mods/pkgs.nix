final: prev:
with prev;
rec {
  inherit (stdenv) isLinux isDarwin isAarch64;
  isM1 = isDarwin && isAarch64;

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

  _caddy_plugins = [
    { name = "github.com/greenpau/caddy-security"; version = "v1.1.14"; }
    { name = "github.com/lindenlab/caddy-s3-proxy"; version = "v0.5.6"; }
  ];
  _caddy_patch_main = final.lib.strings.concatMapStringsSep "\n"
    ({ name, version }: ''
      sed -i '/plug in Caddy modules here/a\\t_ "${name}"' cmd/caddy/main.go
    '')
    _caddy_plugins;
  _caddy_patch_goget = final.lib.strings.concatMapStringsSep "\n"
    ({ name, version }: ''
      go get ${name}@${version}
    '')
    _caddy_plugins;
  xcaddy = caddy.override {
    buildGoModule = args: buildGoModule (args // {
      vendorSha256 = "sha256-Et4DGfhpWXA05PEMxYaWCpulkicjuqaFKUS2JLrS3JM=";
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
    ({ stdenv, lib, buildGoModule, fetchFromGitHub }:
      buildGoModule rec {
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
          inherit (src.meta) homepage;
          description = "command-line tool for exploiting stack-based buffer overflow vulnerabilities";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

}
