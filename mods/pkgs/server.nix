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

  haproxy-2-6-2 = haproxy-pin {
    version = "2.6.2";
    sha256 = "sha256-+bfcBuAusTtdlNxm4IZKcUruKvnfqxD6NT/58fUsggI=";
  };

  pocketbase = prev.callPackage
    ({ stdenv, lib, buildGo119Module, fetchFromGitHub }:
      buildGo119Module rec {
        pname = "pocketbase";
        version = "0.5.0";

        src = fetchFromGitHub {
          owner = "pocketbase";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-olU6462v67y4PIhOjUgYqAmqu7qiJr6q3G/j/hS9LEg=";
        };

        doCheck = false;

        CGO_ENABLED = 0;
        ldflags = [
          "-s"
          "-w"
          "-X github.com/pocketbase/pocketbase.Version=${version}"
        ];

        postBuild = ''
          go build ./examples/base/main.go
        '';
        postInstall = ''
          mkdir -p $out/bin
          mv ./main $out/bin/pocketbase
        '';
        vendorSha256 = "sha256-OGbfcKvPTSM9DGJ+u2fXBmHq0Sv/n8oMbHNoPZy854Q=";

        meta = with lib; {
          description = "open source realtime backend in 1 file";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  zinc = prev.callPackage
    ({ stdenvNoCC, callPackage, fetchurl, autoPatchelfHook, unzip, openssl, lib }:
      let
        dists = {
          aarch64-darwin = {
            arch = "arm64";
            short = "Darwin";
            sha256 = "1lf0rdcskm2mgjfb1mzgcg4g706n1cl1kchsxdx2limxxss6y2af";
          };

          aarch64-linux = {
            arch = "arm64";
            short = "Linux";
            sha256 = "1z97nbgghjabp4ywrgfz0xff3chk7gkmjry1l12l692926pjhn3n";
          };

          x86_64-darwin = {
            arch = "x86_64";
            short = "Darwin";
            sha256 = "05p9qcm3zbnkqm6fdj5w81pz8cf9a52587f74vvxalsn21bibqx1";
          };

          x86_64-linux = {
            arch = "x86_64";
            short = "Linux";
            sha256 = "196wxcbmkwzrq4rg0d5pzljjyxxj17b47dsl10x7xfl0yn8mbwkq";
          };
        };
        dist = dists.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
        pname = "zinc";
        owner = "zinclabs";
        version = "0.2.9";
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
