# This module creates some `pog` tools that help make you more productive in Docker!
final: prev:
with prev;
rec {
  da = pog {
    name = "da";
    description = "a shorthand to see all containers on a host";
    flags = [
      { name = "json"; description = "shorthand for json output"; bool = true; }
      { name = "wide"; description = "show more columns"; bool = true; }
    ];
    script = h: with h; ''
      if ${flag "json"}; then 
        ${_.d} ps -a --format json
      else
        extra="\t{{.CreatedAt}}\t{{.Size}}"
        ${_.d} container ls -a --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}''${wide:+$extra}"
      fi
    '';
  };

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
      {
        name = "user";
        description = "user to run as inside the container";
      }
    ];
    script = ''
      debug "''${GREEN}running image '$image' docker!''${RESET}"
      container_name="$(echo "''${USER:-user}-dshell-''$(${_.uuid} | ${_.head} -c 8)" | tr -cd '[:alnum:]-')"
      # shellcheck disable=SC2086
      ${_.d} run \
        --interactive \
        --tty \
        --rm \
        ''${port:+--publish $port:$port} \
        ''${nix:+--volume /nix:/nix:ro} \
        ''${user:+--user $user} \
        --name "$container_name" \
        "$image" \
        sh -c "$command"
    '';
  };

  dlog = pog {
    name = "dlog";
    description = "a quick and easy way to log one or more containers!";
    flags = [
      {
        name = "container";
        description = "the containers to tail logs from";
        prompt = ''
          ${_.d} ps -a | ${_.fzfqm} --header-lines=1 | ${_.k8s.get_id}
        '';
        promptError = "you must specify one or more containers to log from!";
      }
      {
        name = "since";
        description = "Return logs newer than a relative duration like 52, 2m, or 3h";
        default = "10m";
      }
    ];
    script = helpers: ''
      # shellcheck disable=SC2086
      ${final.ahab}/bin/ahab --since "$since" $container
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
    # dlint
    _dex
    da
    dlog
    drm
    drmi
    dshell
  ];
}
