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
    ({ stdenvNoCC, callPackage, fetchurl, autoPatchelfHook, lib }:
      let
        dists = {
          aarch64-darwin = {
            arch = "arm64";
            short = "Darwin";
            sha256 = "1i7jlayar9zqy7y2zd43jcwilk0d4kah8h1f01rp99r3bsyvgrpk";
          };

          aarch64-linux = {
            arch = "arm64";
            short = "Linux";
            sha256 = "0yynqxj1d807izy4vyiywqchfmllyxh187dcr8v5m8mlr92zvqks";
          };

          x86_64-darwin = {
            arch = "x86_64";
            short = "Darwin";
            sha256 = "0pp7nbwrvayazvmx9l1k2hhdh61n1wqr0jd800xl94fsc0aiwrf2";
          };

          x86_64-linux = {
            arch = "x86_64";
            short = "Linux";
            sha256 = "0xn1jaln9wjkjcf3h4w34m4n47ixy77bijfs9car3w0f27aiq5ph";
          };
        };
        dist = dists.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
        pname = "zinc";
        owner = "zinclabs";
        version = "0.3.5";
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

  poglets = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "poglets";
        version = "0.0.3";
        commit = "0e96c5f5887cd317cd92e6e51eb366929cee3ed1";

        src = fetchFromGitHub {
          owner = "jpetrucciani";
          repo = pname;
          rev = version;
          sha256 = "sha256-owWLviFu/Y+365XZEw7vjmJMmz8wAYMkvGonVJDJ9rU=";
        };

        vendorSha256 = "sha256-Hjdv2Fvl1S52CDs4TAR3Yt9pEFUIvs5N5sVhZY+Edzo=";

        ldflags = [
          "-s"
          "-w"
          "-X main.Version=${version}"
          "-X main.GitCommit=${commit}"
        ];

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  planar-ally = prev.callPackage
    ({ stdenvNoCC, callPackage, fetchurl, autoPatchelfHook, python310, bashInteractive_5, lib }:
      let
        pname = "planarally";
        owner = "Kruptein";
        version = "2022.2.3";
        sha256 = "sha256-u6mTMDAmjUVIbE2l7QZEU9FGXTuwJrVutDhNrI6yLG0=";
        python = python310.withPackages (p: with p; [
          aiohttp
          aiohttp-security
          aiohttp-session
          bcrypt
          cryptography
          python-socketio
          peewee
          typing-extensions
        ]);
        run = writeShellScriptBin "planar-ally" ''
          ${python} 
        '';
      in
      stdenvNoCC.mkDerivation rec {
        inherit pname version;

        src = fetchurl {
          inherit sha256;
          url = "https://github.com/${owner}/${pname}/releases/download/${version}/${pname}-bin-${version}.tar.gz";
        };

        strictDeps = true;
        dontConfigure = true;
        dontBuild = true;

        unpackPhase = ''
          ${gnutar}/bin/tar xzvf ${src}
        '';
        installPhase = ''
          mkdir -p $out/bin
          mv ./server/* $out

          # patch directories

          cat <<EOF >$out/bin/planar-ally
          #!${bashInteractive}/bin/bash
          cd $out
          ${python}/bin/python ./src/planarserver.py "$@"
          EOF
          chmod +x $out/bin/planar-ally
        '';

        meta = with lib; {
          license = licenses.mit;
        };
      }
    )
    { };

}
