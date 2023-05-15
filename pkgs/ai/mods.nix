{ lib, buildGo120Module, fetchFromGitHub }:
buildGo120Module rec {
  pname = "mods";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-r7j7iMkfkFsohguu2vkhyxUbaMwJQURfUJrnC6yUCFI=";
  };

  vendorHash = "sha256-+0yGFCGd/9bIBjXYp8UPGqKum2di5O1ALMyDSxcVujg=";

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "AI on the command line";
    homepage = "https://github.com/charmbracelet/mods";
    mainProgram = "mods";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
