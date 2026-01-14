# [pogocache](https://github.com/pogocache/pogocache) is Fast caching software with a focus on low latency and cpu efficiency
{ lib
, stdenv
, fetchFromGitHub
, git
, autoconf
, cmake
, openssl
, liburing
, mimalloc
, jemalloc
, perl
}:
let
  onlyDarwin = value: if stdenv.isDarwin then value else null;
in
stdenv.mkDerivation rec {
  pname = "pogocache";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "tidwall";
    repo = "pogocache";
    rev = version;
    hash = "sha256-ZNpuOe7r0Wtj2JI9LZS2AV0Ymah3J1G8p3Mizm24avo=";
  };

  ${onlyDarwin "NOURING"} = "1";
  ${onlyDarwin "NOOPENSSL"} = "1";

  buildInputs = [ autoconf cmake git ] ++ (lib.optionals stdenv.isLinux [ perl liburing openssl ]);

  dontUseCmakeConfigure = true;

  postPatch = (if stdenv.isLinux then ''
    tar -xzf ${openssl.src}
    mv openssl-* deps/openssl

    cp -r ${liburing.src} ./deps/liburing
  '' else "") + ''
    cp -r ${mimalloc.src} ./deps/mimalloc
    cp -r ${jemalloc.src} ./deps/jemalloc

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
