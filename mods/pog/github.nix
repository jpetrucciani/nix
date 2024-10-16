# This module provides some tools that interact with GitHub
final: prev:
let
  inherit (final) _ pog lib jaq;
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
    script = ''
      tags="$(${_.curl} -Ls "https://api.github.com/repos/''${owner}/''${repo}/tags" |
        ${lib.getExe jaq} -r '.[].name')"
      if [ -n "''${latest}" ]; then
        echo "$tags" | ${_.head} -n 1
      else
        echo "$tags"
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
