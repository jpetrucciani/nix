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
            sha256 = "1bzrqhiij6j1qcw7vfwac8fkfpvcvmnfdi1pxy6av9ll2dbxwm1s";
          };

          aarch64-linux = {
            arch = "arm64";
            short = "Linux";
            sha256 = "0gwi2k3rba1kakbb4ihbvkz0fggx2vsv7nvh7fqcj90qdic8zqcv";
          };

          x86_64-darwin = {
            arch = "x86_64";
            short = "Darwin";
            sha256 = "15dl9ls71vza6mzdb7wvgld7mwix68qwfb1ijgvwdinalgwvja1m";
          };

          x86_64-linux = {
            arch = "x86_64";
            short = "Linux";
            sha256 = "0yjlp8xrw48nwkkky3bglsp14bg7n9yg6fkskans8nnzsm5m3rsd";
          };
        };
        dist = dists.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
        pname = "zinc";
        owner = "zinclabs";
        version = "0.3.3";
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
        version = "0.0.2";
        commit = "7510189b70b0c39986200f0c36a6a81bd278b904";

        src = fetchFromGitHub {
          owner = "jpetrucciani";
          repo = pname;
          rev = version;
          sha256 = "sha256-ubHOLlpwjqnAQ12sng/a0CCXYyREA+M68Gt0vZQQj4c=";
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
          #!${bashInteractive_5}/bin/bash
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
