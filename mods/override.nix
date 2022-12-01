final: prev:
with prev;
let
  inherit (prev.stdenv) isLinux;
in
{
  docker = docker.override { withLvm = isLinux; };
}
