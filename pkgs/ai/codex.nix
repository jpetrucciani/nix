# [codex](https://github.com/openai/codex) is a lightweight coding agent that runs in your terminal
{ lib, fetchFromGitHub, buildNpmPackage, bash }:
let
  src = (fetchFromGitHub {
    owner = "openai";
    repo = "codex";
    rev = "24e86da575fd3c975f23f4c17b6c7fd0c1c62c52";
    hash = "sha256-gauZzSJa9URNhcntz33vezwDkNfL8xc+Bdg4qF+cc8Q=";
  }) + "/codex-cli";
in
buildNpmPackage {
  inherit src;
  pname = "codex";
  version = "0.0.0";
  npmDepsHash = "sha256-QdfO/p8oQnwIANeNRD0vD55v5lc9dHeaScpnpLqWdxc=";
  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "codex";
    platforms = lib.platforms.all;
  };
}
