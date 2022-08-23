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
            sha256 = "1s95j6j44vgxa3qlf1vhlxhx5a5rn8pwj2qvcan6g4i7xyqm8hnz";
          };

          aarch64-linux = {
            arch = "arm64";
            short = "Linux";
            sha256 = "1aq1za1y3sk57m6xv4rm8fhdhy2fxlwg9bd79rsc7d1nmd4mdqhs";
          };

          x86_64-darwin = {
            arch = "x86_64";
            short = "Darwin";
            sha256 = "06w673irqd73lxr2xzdlzgi3453iqpnq6phfx1v0fhgwbs6qfkap";
          };

          x86_64-linux = {
            arch = "x86_64";
            short = "Linux";
            sha256 = "0w3az5ydwgfj2f9v1ikwbhwin7b4jry26l67fb0i3j32c3273w5g";
          };
        };
        dist = dists.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
        pname = "zinc";
        owner = "zinclabs";
        version = "0.3.0";
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
