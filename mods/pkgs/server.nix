final: prev:
with prev;
let
  inherit (stdenv) isLinux isDarwin isAarch64;
  isM1 = isDarwin && isAarch64;
in
rec {
  haproxy-pin = { version, sha256 }: haproxy.overrideAttrs (attrs: rec {
    inherit version;
    src = fetchurl {
      inherit sha256;
      url = "https://www.haproxy.org/download/${lib.versions.majorMinor version}/src/${attrs.pname}-${version}.tar.gz";
    };
  });

  haproxy-2-2-25 = haproxy-pin {
    version = "2.2.25";
    sha256 = "sha256-vrQH6wiyxpfRFaGMANagI/eg+yy5m/+cNMnf2dLFLys=";
  };

  haproxy-2-6-5 = haproxy-pin {
    version = "2.6.5";
    sha256 = "sha256-zp4Z6/zdQ+Ua+KYJDx341RLZct33QvpkimQ7uxkFZgU=";
  };

  zinc = prev.callPackage
    ({ stdenvNoCC, callPackage, fetchurl, autoPatchelfHook, unzip, openssl, lib }:
      let
        dists = {
          aarch64-darwin = {
            arch = "arm64";
            short = "Darwin";
            sha256 = "1gq28a043v5aaimbdl4siizxnmsp34672lza0yvas2lrdklxh8cz";
          };

          aarch64-linux = {
            arch = "arm64";
            short = "Linux";
            sha256 = "07kiw1k95xqb1aid8j7hvv96955hp185gdidmh0rllk3jgg5i1kn";
          };

          x86_64-darwin = {
            arch = "x86_64";
            short = "Darwin";
            sha256 = "1wzfw2vd37v6frpfhh61zzvw7vd1bq4kjd01c0zwi1pzlrg414zr";
          };

          x86_64-linux = {
            arch = "x86_64";
            short = "Linux";
            sha256 = "14n368hjmdfjpc28mkwjz1d3hrm3l6z5kzb9vma35nblj35iw5kc";
          };
        };
        dist = dists.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
        pname = "zinc";
        owner = "zinclabs";
        version = "0.3.1";
      in
      stdenvNoCC.mkDerivation rec {
        inherit pname version;

        src = fetchurl {
          inherit (dist) sha256;
          url = "https://github.com/${owner}/${pname}/releases/download/v${version}/${pname}_${version}_${dist.short}_${dist.arch}.tar.gz";
        };

        strictDeps = true;
        nativeBuildInputs = lib.optionals stdenvNoCC.isLinux [ autoPatchelfHook ];

        dontConfigure = true;
        dontBuild = true;

        unpackPhase = ''
          ${gnutar}/bin/tar xzvf ${src}
        '';
        installPhase = ''
          mkdir -p $out/bin
          mv ./zinc $out/bin/zinc
        '';

        meta = with lib; {
          license = licenses.mit;
        };
      }
    )
    { };

}
