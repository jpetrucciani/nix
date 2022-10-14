final: prev:
with prev;
rec {
  jiracurl = pog {
    name = "jiracurl";
    description = "a wrapper for curl to allow access tokens with bearer auth!";
    flags = [
      {
        name = "token";
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
