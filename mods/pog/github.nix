# This module provides some tools that interact with GitHub
final: prev:
let
  inherit (final) _ pog;
in
rec {
  github_tags = pog {
    name = "github_tags";
    description = "a nice wrapper for getting github tags for a repo!";
    flags = [
      {
        name = "latest";
        description = "fetch only the latest tag";
        bool = true;
      }
      _.flags.github.owner
      _.flags.github.repo
    ];
    script =
      let
        _curl = "${_.curl} -Ls";
        _jq = "${final.jq}/bin/jq -r";
      in
      helpers: ''
        api_url="https://api.github.com/repos/$owner/$repo"
        if ${helpers.flag "latest"}; then
          ${_curl} "$api_url/releases/latest" | ${_jq} '.tag_name'
        else
          ${_curl} "$api_url/tags" | ${_jq} '.[].name'
        fi
      '';
  };

  github_actions = pog {
    name = "github_actions";
    description = "a nice wrapper for running github actions locally!";
    flags = [
      {
        name = "arch";
        default = "amd64";
        description = "the underlying arch to use in the docker images [amd64/arm64]";
      }
      {
        name = "flags";
        default = "";
        description = "additional flags to pass to act";
      }
    ];
    script = ''
      # shellcheck disable=SC2155
      export DOCKER_HOST="$(${final.docker-client}/bin/docker context inspect --format '{{.Endpoints.docker.Host}}')"
      # shellcheck disable=SC2086
      ${final.act}/bin/act --container-architecture "linux/$arch" -r --rm $flags
    '';
  };

  github_automerge =
    let
      gh = "${final.gh}/bin/gh";
      grep = "${final.gnugrep}/bin/grep";
    in
    pog {
      name = "github_automerge";
      description = "";
      flags = [
        { name = "maxattempts"; description = "max retry attempts to merge"; default = "5"; }
        { name = "pr"; envVar = "PR_URL"; description = "the url for the PR to merge"; }
      ];
      script = ''
        attempt=1
        while (( attempt <= maxattempts )); do
          echo "attempt $attempt/$maxattempts: ${gh} pr merge --auto --squash $pr"
          out="$(mktemp)"
          err="$(mktemp)"
          if ${gh} pr merge --auto --squash "$pr" >"$out" 2>"$err"; then
            echo "merge succeeded"
            cat "$out"
            exit 0
          fi
          echo "merge failed"
          cat "$err" >&2
          if ${grep} -q "Base branch was modified" "$err"; then
            echo "detected base-branch race. rebase-updating PR branch then retrying"
            ${gh} pr update-branch --rebase "$pr" || true
          elif ${grep} -q "Protected branch rules not configured for this branch" "$err"; then
            echo "detected transient branch-rules evaluation error. waiting and retrying"
            ${gh} pr view "$pr" --json mergeable,mergeStateStatus >/dev/null || true
          elif ${grep} -q "Pull request is in unstable status" "$err"; then
            echo "detected transient unstable status. waiting and retrying"
            ${gh} pr view "$pr" --json mergeable,mergeStateStatus >/dev/null || true
          else
            echo "non-retryable failure."
            exit 1
          fi
          sleep_time=$(( 3 + RANDOM % 6 ))  # 3-8s
          echo "sleeping ''${sleep_time}s before retry"
          ${final.coreutils}/bin/sleep "$sleep_time"
          attempt=$(( attempt + 1 ))
        done
        die "exceeded retries ($maxattempts)"
      '';
    };

  github_pog_scripts = [
    github_tags
    github_actions
    github_automerge
  ];
}
