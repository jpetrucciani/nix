final: prev:
let
  inherit (final) fetchFromGitHub stdenv darwin;
  inherit (final.lib) optional;
in
{
  ocamlPackages = prev.ocamlPackages.overrideScope
    (oself: osuper: with oself; {
      dream = buildDunePackage rec {
        pname = "dream";
        version = "1.0.0-alpha8";
        src = fetchFromGitHub {
          owner = "aantron";
          repo = pname;
          tag = version;
          hash = "sha256-AJBszLOUVwCXDqryNUkak4UlbmofCkxBIPEm4M0nHEI=";
        };
        propagatedBuildInputs = [
          camlp-streams
          yojson
          ssl
          magic-mime
          mirage-crypto-rng-lwt
          graphql-lwt
          lwt_ssl
          caqti-lwt
          httpun-ws
          httpun-lwt-unix
          h2-lwt-unix
          dream-httpaf
          multipart_form-lwt
          mirage-clock
          markup
          lambdasoup
        ];
      };
      dream-pure = buildDunePackage {
        pname = "dream-pure";
        inherit (dream) version src;
        propagatedBuildInputs = [ ptime lwt_ppx uri hmap base64 ];
      };
      httpun-lwt-unix = buildDunePackage {
        pname = "httpun-lwt-unix";
        inherit (httpun) version src;
        propagatedBuildInputs = [ lwt gluten-lwt-unix httpun-lwt ];
      };
      httpun-lwt = buildDunePackage {
        pname = "httpun-lwt";
        inherit (httpun) version src;
        propagatedBuildInputs = [ httpun gluten-lwt ];
      };
      dream-httpaf = buildDunePackage {
        pname = "dream-httpaf";
        inherit (dream) version src;
        propagatedBuildInputs = [ lwt_ppx httpun-ws dream-pure ];
      };
      multipart_form = buildDunePackage rec {
        pname = "multipart_form";
        version = "0.6.0";
        src = fetchFromGitHub {
          owner = "dinosaure";
          repo = pname;
          tag = "v${version}";
          hash = "sha256-aW8TOnzzJmuqN4ddUgoLbX8FefBC3nkPXiLn11C7QCs=";
        };
        propagatedBuildInputs = [ angstrom fmt uutf pecu prettym base64 unstrctrd logs ];
      };
      multipart_form-lwt = buildDunePackage {
        pname = "multipart_form-lwt";
        inherit (multipart_form) version src;
        propagatedBuildInputs = [ ke lwt multipart_form ];
      };
      # dream requires old version of httpun, nixpkgs uses httpun-types as base
      httpun-types = osuper.httpun-types.overrideAttrs (old: rec {
        version = "0.1.0";
        src = fetchFromGitHub {
          owner = "anmonteiro";
          repo = "httpun";
          tag = version;
          hash = "sha256-Sig6+EkMcoHeP4Z+qR0H9khwErX080etoNlI0Bs7+Fk=";
        };
      });
      # dream requires old version of h2, nixpkgs uses hpack as base
      hpack = osuper.hpack.overrideAttrs (old: rec {
        version = "0.12.0";
        src = fetchFromGitHub {
          owner = "anmonteiro";
          repo = "ocaml-h2";
          tag = version;
          hash = "sha256-BkivG6p2c+cUoJn8XsxM17NO9plkaEYa4FyogFkBfV4=";
        };
      });
      # darwin fixes
      caqti = osuper.caqti.overrideAttrs (old: {
        nativeBuildInputs = old.nativeBuildInputs ++ optional stdenv.isDarwin [ darwin.sigtool ];
      });
      mirage-crypto-rng = osuper.mirage-crypto-rng.overrideAttrs (old: {
        doCheck = false;
      });
    });
}
