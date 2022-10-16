final: prev:
with prev;
rec {
  drm = pog {
    name = "drm";
    description = "quickly remove containers from your docker daemon!";
    flags = [
      _.flags.common.force
    ];
    script = ''
      ${_.docker.da} | ${_.fzfqm} --header-lines=1 | ${_.docker.get_container} | ${_.xargs} -r ${_.d} rm ''${force:+--force}
    '';
  };
  drmi = pog {
    name = "drmi";
    description = "quickly remove images from your docker daemon!";
    flags = [
      _.flags.common.force
    ];
    script = ''
      ${_.docker.di} | ${_.fzfqm} --header-lines=1 | ${_.docker.get_image} | ${_.xargs} -r ${_.d} rmi ''${force:+--force}
    '';
  };
  _dex = pog {
    name = "dex";
    description = "a quick and easy way to exec into a docker pod!";
    flags = [
      {
        name = "container";
        description = "the container to exec into";
        prompt = ''
          ${_.d} ps -a | ${_.fzfq} --header-lines=1 | ${_.k8s.get_id}
        '';
        promptError = "you must specify a container to exec into!";
      }
    ];
    script = ''
      debug "''${GREEN}exec'ing into '$container'!''${RESET}"
      ${_.d} exec --interactive --tty "$container" sh -c "${_.globals.hacks.bash_or_sh}"
    '';
  };
  dshell = pog {
    name = "dshell";
    description = "a quick and easy way to pop a shell on docker!";
    flags = [
      _.flags.docker.image
      {
        name = "port";
        description = "a port to expose to the host";
      }
      {
        name = "command";
        description = "the command to run within this shell";
        default = _.globals.hacks.bash_or_sh;
      }
      {
        name = "nix";
        description = "mount the /nix store as readonly in the container";
        bool = true;
      }
    ];
    script = ''
      debug "''${GREEN}running image '$image' docker!''${RESET}"
      pod_name="$(echo "''${USER:-user}-dshell-''$(${_.uuid} | ${_.head} -c 8)" | tr -cd '[:alnum:]-')"
      # shellcheck disable=SC2086
      ${_.d} run \
        --interactive \
        --tty \
        --rm \
        ''${port:+--publish $port:$port} \
        ''${nix:+--volume /nix:/nix:ro} \
        --name "$pod_name" \
        "$image" \
        sh -c "$command"
    '';
  };
  dlint = pog {
    name = "dlint";
    description = "a prescriptive hadolint dockerfile linter config";
    flags = [
      {
        name = "file";
        description = "the dockerfile to analyze";
        default = "./Dockerfile";
      }
    ];
    script = ''
      ${pkgs.hadolint}/bin/hadolint \
        --ignore DL3008 \
        --ignore DL3009 \
        --ignore DL3028 \
        --ignore DL3015 \
        --ignore DL4006 \
        "$file"
    '';
  };

  docker_pog_scripts = [
    drm
    drmi
    dshell
    dlint
    _dex
  ];
}
