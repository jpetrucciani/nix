# [html-to-markdown](https://github.com/JohannesKaufmann/html-to-markdown) is a quick way to convert arbitrary html to markdown documents
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "html-to-markdown";
  version = "2.3.3";

  src = fetchFromGitHub {
    owner = "JohannesKaufmann";
    repo = "html-to-markdown";
    rev = "v${version}";
    hash = "sha256-B+ZJk86VJUscaf91tv5uuTeL6u9HN6cS+5+4TOiNC+E=";
  };

  vendorHash = "sha256-nMb4moiTMzLSWfe8JJwlH6H//cOHbKWfnM9SM366ey0=";

  ldflags = [ "-s" "-w" ];

  meta = {
    description = "Convert HTML to Markdown. Even works with entire websites and can be extended through rules";
    homepage = "https://github.com/JohannesKaufmann/html-to-markdown";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "html-to-markdown";
  };
}
