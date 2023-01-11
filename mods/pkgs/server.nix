final: prev:
with prev;
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

        nativeBuildInputs = [ installShellFiles ];

        ldflags = [
          "-s"
          "-w"
          "-X main.Version=${version}"
          "-X main.GitCommit=${commit}"
        ];

        postInstall = ''
          installShellCompletion --cmd poglets \
            --bash <($out/bin/poglets completion bash) \
            --fish <($out/bin/poglets completion fish) \
            --zsh  <($out/bin/poglets completion zsh)
        '';

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  bigquery-emulator = prev.callPackage
    ({ lib, buildGo119Module, fetchFromGitHub, clangStdenv }:
      (buildGo119Module.override { stdenv = clangStdenv; }) rec {
        pname = "bigquery-emulator";
        version = "0.2.10";
        commit = "fdf32e7e7db6b22829cd8366d6768ef5acd64a11";

        src = fetchFromGitHub {
          owner = "goccy";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-Vl6l0qfdKhKPF2WhgUmVNgPXIOGB1FaAm4dqdoBT4P0=";
        };

        vendorSha256 = "sha256-saIbb5CAmxFkAR/kxQxKdgL1Vnx7XaCox0V3SM6Ngus=";

        CGO_ENABLED = 1;

        nativeBuildInputs = [ ];
        subPackages = [
          "./cmd/bigquery-emulator"
        ];

        ldflags = [
          "-s"
          "-w"
          "-X main.version=${version}"
          "-X main.revision=${commit}"
          "-linkmode external"
        ];

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "BigQuery emulator server implemented in Go";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

}
