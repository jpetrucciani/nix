{ lib
, stdenv
, fetchFromGitHub
, git
, openssl
, liburing
, perl
}:
let
  onlyDarwin = value: if stdenv.isDarwin then value else null;
in
stdenv.mkDerivation rec {
  pname = "pogocache";
  version = "1.0.2";

  src = fetchFromGitHub {
    owner = "tidwall";
    repo = "pogocache";
    rev = version;
    hash = "sha256-Vg5OTkoJ5NE/Z3Owa6FSKbnKgdhoE2kpEolH+wj/BpA=";
  };

  ${onlyDarwin "NOURING"} = "1";
  ${onlyDarwin "NOOPENSSL"} = "1";

  buildInputs = [ git ] ++ (lib.optionals stdenv.isLinux [ perl liburing openssl ]);

  postPatch = lib.optionals stdenv.isLinux ''
    sed -i -e '/download.sh/,+7d' ./deps/build-openssl.sh
    tar -xzf ${openssl.src}
    mv openssl-* deps/openssl

    substituteInPlace ./deps/build-uring.sh \
      --replace-fail './download.sh https://github.com/axboe/liburing liburing $vers liburing-$vers' ""
    cp -r ${liburing.src} ./deps/liburing

    patchShebangs ./deps/*.sh ./deps/openssl/Configure
    chmod -R +w ./deps
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ./pogocache $out/bin/.
  '';

  meta = {
    description = "Fast caching software with a focus on low latency and cpu efficiency";
    homepage = "https://github.com/tidwall/pogocache";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "pogocache";
    platforms = lib.platforms.all;
  };
}
