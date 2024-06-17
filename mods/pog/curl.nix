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
    description = "a gitlab wrapper for curl to allow access tokens with bearer auth!";
    arguments = [{ name = "PATH"; }];
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
      ${curl}/bin/curl \
        -H "Authorization: Bearer $token" \
        "$@" "$url/$path"
    '';
  };

  githubcurl = pog {
    name = "githubcurl";
    description = "a github wrapper for curl to allow access tokens with bearer auth!";
    arguments = [{ name = "PATH"; }];
    flags = [
      {
        name = "token";
        description = "the github token to use for bearer auth [also passable via env with 'GITHUB_TOKEN']";
        envVar = "GITHUB_TOKEN";
      }
      {
        name = "url";
        description = "the github api url to hit";
        envVar = "GITHUB_URL";
        default = "https://api.github.com";
      }
      {
        name = "apiversion";
        description = "the github api version to use in the request";
        default = "2022-11-28";
      }
    ];
    script = ''
      path="$1"
      shift 1
      ${curl}/bin/curl \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: $apiversion" \
        "$@" "$url/$path"
    '';
  };

  # note - this is intentionally a naive implementation
  github_create_release = pog {
    name = "github_create_release";
    description = "a wrapper around curl to quickly create github releases from an existing tag. docs here: https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#create-a-release";
    flags = [
      { name = "owner"; description = "the owner of the repo"; }
      { name = "repo"; description = "the repo name"; }
      { name = "tag"; description = "the tag to create a release for"; }
      # {
      #   name = "token";
      #   short = "";
      #   description = "the github token to use for bearer auth [also passable via env with 'GITHUB_ACTIONS_RELEASE_TOKEN']";
      #   envVar = "GITHUB_ACTIONS_RELEASE_TOKEN";
      # }
    ];
    script = ''
      ${githubcurl}/bin/githubcurl "repos/$owner/$repo/releases" \
        -- \
        -X POST \
        -d "{\"tag_name\":\"$tag\",\"target_commitish\":\"main\",\"name\":\"$tag\",\"body\":\"\",\"draft\":false,\"prerelease\":false,\"generate_release_notes\":false}"
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
    githubcurl
    github_create_release
    gitlabcurl
    jiracurl
  ];
}

