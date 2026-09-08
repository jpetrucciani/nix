{ cctools, darwin, lib, libiconv, mkG7cBinaryRelease, stdenvNoCC }:
let
  release = lib.importJSON ./geode.json;
in
mkG7cBinaryRelease {
  pname = "geode";
  inherit (release) hashes version;
  dataFile = "pkgs/ai/geode.json";

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isDarwin [
    cctools
    darwin.autoSignDarwinBinariesHook
  ];
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isDarwin [ libiconv ];
  binaryFixup = lib.optionalString stdenvNoCC.hostPlatform.isDarwin ''
    old_libiconv="$(otool -L "$out/bin/geode" | awk '/libiconv\.2\.dylib/{print $1; exit}')"
    if [ -n "$old_libiconv" ] && [ "$old_libiconv" != "${libiconv}/lib/libiconv.2.dylib" ]; then
      install_name_tool -change "$old_libiconv" "${libiconv}/lib/libiconv.2.dylib" "$out/bin/geode"
    fi
  '';

  meta = {
    description = "local-first semantic index toolkit";
    homepage = "https://github.com/gemologic/geode";
    platforms = [ "x86_64-linux" "aarch64-darwin" ];
  };
}
