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
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        pname = "pocketbase";
        version = "0.4.2";

        src = fetchFromGitHub {
          owner = "pocketbase";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-uDseJmuK6SI3e2ICqr8SJ0iKOVCXONueZUJ6J8MKwYE=";
        };

        doCheck = false;

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
        vendorSha256 = "sha256-8IiY/gjK8m2ntOXyG84HMiyT4GK3CgDTRG1DB+v0jAs=";

        meta = with lib; {
          description = "open source realtime backend in 1 file";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

}
