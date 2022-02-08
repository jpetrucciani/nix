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

}
