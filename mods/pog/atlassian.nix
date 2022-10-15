final: prev:
with prev;
rec {
  jiracurl = pog {
    name = "jiracurl";
    description = "a wrapper for curl to allow access tokens with bearer auth!";
    flags = [
      {
        name = "token";
        description = "the jira token to use for bearer auth [also passable via env with 'JIRA_TOKEN']";
        envVar = "JIRA_TOKEN";
      }
    ];
    script = ''
      ${curl}/bin/curl -H "Authorization: Bearer $token" "$@"
    '';
  };

  atlassian_pog_scripts = [
    jiracurl
  ];
}
