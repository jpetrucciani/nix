# [`maestro`](https://github.com/pluja/maestro) converts natural language instructions into cli commands with LLMs
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "maestro-go";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "pluja";
    repo = "maestro";
    rev = "v${version}";
    hash = "sha256-shdUdCsQyeCv9ihfYSzjNBakRm0sJuN3Zm30hBGbVRI=";
  };

  vendorHash = "sha256-o1FZPYZ4K3TFqkIsMaAcRGSh1IdpHspZbbE3W1fIRiI=";

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Turn natual language into commands. Your CLI tasks, now as easy as a conversation. Run it 100% offline, or use OpenAI's models";
    homepage = "https://github.com/pluja/maestro";
    license = licenses.unfree; # FIXME: nix-init did not found a license
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "maestro";
  };
}
