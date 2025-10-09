# this pog module includes tools to interact with notion
final: prev:
let
  inherit (final) curl pog;
in
rec {
  notioncurl = pog {
    name = "notioncurl";
    description = "a notion wrapper for curl to allow access tokens with bearer auth!";
    flags = [
      {
        name = "token";
        description = "the notion token to use for bearer auth [also passable via env with 'NOTION_TOKEN']";
        envVar = "NOTION_TOKEN";
      }
    ];
    script = ''
      ${curl}/bin/curl \
        -H "Authorization: Bearer $token" \
        -H 'Notion-Version: 2022-06-28' \
        -H "Content-Type: application/json" \
        "$@"
    '';
  };

  notion_pog_scripts = [
    notioncurl
  ];
}
