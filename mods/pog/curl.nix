# this file provides some pog wrappers around curl to make it a bit more ergonomic
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

  gitlabcurl = pog {
    name = "gitlabcurl";
    description = "a wrapper for curl to allow access tokens with bearer auth!";
    flags = [
      {
        name = "token";
        description = "the gitlab token to use for bearer auth [also passable via env with 'GITLAB_TOKEN']";
        envVar = "GITLAB_TOKEN";
      }
      {
        name = "url";
        description = "the gitlab url to hit";
        envVar = "GITLAB_URL";
        default = "https://gitlab.com";
      }
    ];
    script = ''
      path="$1"
      shift 1
      ${curl}/bin/curl -H "Authorization: Bearer $token" "$@" "$url$path"
    '';
  };

  baymaxcurl = pog {
    name = "baymaxcurl";
    description = "a wrapper for curl to allow access tokens with baymax auth!";
    flags = [
      {
        name = "token";
        description = "the baymax token to use for auth [also passable via env with 'BAYMAX_TOKEN']";
        envVar = "BAYMAX_TOKEN";
      }
      {
        name = "url";
        description = "the baymax url to hit";
        envVar = "BAYMAX_URL";
        default = "https://baymax.medable.tech";
      }
    ];
    script = ''
      path="$1"
      shift 1
      ${curl}/bin/curl -H "x-baymax: $token" "$@" "$url$path"
    '';
  };

  curl_pog_scripts = [
    baymaxcurl
    gitlabcurl
    jiracurl
  ];
}

