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
}
