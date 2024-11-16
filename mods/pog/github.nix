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
      export DOCKER_HOST="$(${prev.docker-client}/bin/docker context inspect --format '{{.Endpoints.docker.Host}}')"
      # shellcheck disable=SC2086
      ${prev.act}/bin/act --container-architecture "linux/$arch" -r --rm $flags
    '';
  };

  github_pog_scripts = [
    github_tags
    github_actions
  ];
}
