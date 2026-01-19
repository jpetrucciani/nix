# this file provides some pog wrappers around curl to make it a bit more ergonomic
final: prev:
let
  inherit (final) _ pog curl;
in
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
        -d "{\"tag_name\":\"$tag\",\"name\":\"$tag\",\"body\":\"\",\"draft\":false,\"prerelease\":false,\"generate_release_notes\":false}"
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

  ntfy_publish = pog {
    name = "ntfy_publish";
    description = "publish a message to an ntfy topic with headers mapped to flags";
    shortDefaultFlags = false;
    flags = [
      { name = "url"; envVar = "NTFY_URL"; description = "ntfy publish api URL"; required = true; }
      { name = "topic"; envVar = "NTFY_TOPIC"; description = "the topic to publish to"; required = true; short = ""; }
      { name = "message"; envVar = "NTFY_MESSAGE"; description = "message body to send"; required = true; }
      { name = "title"; envVar = "NTFY_TITLE"; description = "message title"; short = ""; }
      { name = "priority"; envVar = "NTFY_PRIORITY"; description = "message priority (1-5)"; short = ""; }
      { name = "tags"; envVar = "NTFY_TAGS"; description = "comma-separated tags or emojis"; }
      { name = "delay"; envVar = "NTFY_DELAY"; description = "delivery delay (e.g., 10m, 2024-01-01T00:00:00Z)"; }
      { name = "actions"; envVar = "NTFY_ACTIONS"; description = "actions JSON array or short format"; short = ""; }
      { name = "click"; envVar = "NTFY_CLICK"; description = "URL to open on click"; }
      { name = "attach"; envVar = "NTFY_ATTACH"; description = "attachment URL"; short = ""; }
      { name = "markdown"; envVar = "NTFY_MARKDOWN"; bool = true; description = "enable markdown formatting"; short = ""; }
      { name = "icon"; envVar = "NTFY_ICON"; description = "icon URL"; }
      { name = "filename"; envVar = "NTFY_FILENAME"; description = "attachment filename"; }
      { name = "email"; envVar = "NTFY_EMAIL"; description = "email address for notifications"; }
      { name = "call"; envVar = "NTFY_CALL"; description = "phone number for call notifications"; short = ""; }
      { name = "no_cache"; envVar = "NTFY_NO_CACHE"; bool = true; description = "disable message caching"; short = ""; }
      { name = "no_firebase"; envVar = "NTFY_NO_FIREBASE"; bool = true; description = "disable Firebase forwarding"; short = ""; }
      { name = "unifiedpush"; envVar = "NTFY_UNIFIEDPUSH"; bool = true; description = "enable UnifiedPush mode"; short = ""; }
      { name = "content_type"; envVar = "NTFY_CONTENT_TYPE"; description = "override Content-Type header"; short = ""; }
      { name = "token"; envVar = "NTFY_TOKEN"; description = "bearer token for Authorization header"; short = ""; }
      { name = "username"; envVar = "NTFY_USERNAME"; description = "basic auth username"; short = ""; }
      { name = "password"; envVar = "NTFY_PASSWORD"; description = "basic auth password"; short = ""; }
    ];
    script = h: ''
      curl_args=( -sS -X POST --data-binary "$message" )
      headers=()

      ${h.var.notEmpty "title"} && headers+=( -H "X-Title: $title" )
      ${h.var.notEmpty "priority"} && headers+=( -H "X-Priority: $priority" )
      ${h.var.notEmpty "tags"} && headers+=( -H "X-Tags: $tags" )
      ${h.var.notEmpty "delay"} && headers+=( -H "X-Delay: $delay" )
      ${h.var.notEmpty "actions"} && headers+=( -H "X-Actions: $actions" )
      ${h.var.notEmpty "click"} && headers+=( -H "X-Click: $click" )
      ${h.var.notEmpty "attach"} && headers+=( -H "X-Attach: $attach" )
      ${h.var.notEmpty "icon"} && headers+=( -H "X-Icon: $icon" )
      ${h.var.notEmpty "filename"} && headers+=( -H "X-Filename: $filename" )
      ${h.var.notEmpty "email"} && headers+=( -H "X-Email: $email" )
      ${h.var.notEmpty "call"} && headers+=( -H "X-Call: $call" )
      ${h.var.notEmpty "content_type"} && headers+=( -H "Content-Type: $content_type" )
      ''${markdown:+headers+=( -H "X-Markdown: 1" )}
      ''${no_cache:+headers+=( -H "X-Cache: no" )}
      ''${no_firebase:+headers+=( -H "X-Firebase: no" )}
      ''${unifiedpush:+headers+=( -H "X-UnifiedPush: 1" )}

      if ${h.var.notEmpty "token"}; then
        headers+=( -H "Authorization: Bearer $token" )
      elif ${h.var.notEmpty "username"} && ${h.var.notEmpty "password"}; then
        curl_args+=( -u "$username:$password" )
      fi

      ${_.curl} "''${headers[@]}" "''${curl_args[@]}" "$url"
    '';
  };

  curl_pog_scripts = [
    baymaxcurl
    githubcurl
    github_create_release
    gitlabcurl
    jiracurl
    ntfy_publish
  ];
}
