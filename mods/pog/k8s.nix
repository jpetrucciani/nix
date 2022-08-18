final: prev:
with prev;
rec {
  kex = pog {
    name = "kex";
    description = "a quick and easy way to exec into a k8s pod!";
    flags = [
      _.flags.k8s.namespace
      {
        name = "pod";
        description = "the id of the pod to exec into";
        prompt = ''
          ${_.k} --namespace "$namespace" get pods |
          ${_.fzfq} --header-lines=1 |
          ${_.k8s.get_id}
        '';
        promptError = "you must specify a pod id!";
      }
    ];
    script = ''
      ${_.k} --namespace "$namespace" exec -it "$pod" -- sh -c "${_.globals.hacks.bash_or_sh}"
    '';
  };

  krm = pog {
    name = "krm";
    description = "a quick and easy way to delete one or more pods on k8s!";
    flags = [
      _.flags.k8s.namespace
      _.flags.common.force
    ];
    script = ''
      ${_.k} --namespace "$namespace" get pods |
        ${_.fzfqm} --header-lines=1 |
        ${_.k8s.get_id} |
        ${_.xargs} --no-run-if-empty ${_.k} --namespace "$namespace" delete pods ''${force:+--grace-period=0 --force}
    '';
  };

  klist = pog {
    name = "klist";
    description = "list out all the images in use on this k8s cluster!";
    script = ''
      ${_.k} get pods --all-namespaces -o jsonpath='{..image}' |
        ${_.tr} -s '[[:space:]]' '\\n' |
        ${_.sort} |
        ${_.uniq} -c
    '';
  };

  kshell = pog {
    name = "kshell";
    description = "a quick and easy way to pop a shell on k8s!";
    flags = [
      _.flags.k8s.namespace
      _.flags.docker.image
    ];
    script = ''
      debug "''${GREEN}running image '$image' on the '$namespace' namespace!''${RESET}"
      pod_name="$(echo "''${USER:-user}-kshell-''$(${_.uuid} | ${_.head} -c 8)" | tr -cd '[:alnum:]-')"
      ${_.k} run \
        --stdin \
        --tty \
        --rm \
        --restart Never \
        --namespace "$namespace" \
        --image-pull-policy=Always \
        --image="$image" \
        "$pod_name" \
        -- \
        sh -c "${_.globals.hacks.bash_or_sh}"
    '';
  };

  kroll = pog {
    name = "kroll";
    description = "a quick and easy way to roll a deployment's pods!";
    flags = [
      _.flags.k8s.namespace
      {
        name = "deployment";
        description = "the deployment to roll. if not passed in, a dialog will pop up to select from";
        prompt = ''${_.k} --namespace "$namespace" get deployment -o wide | ${_.fzfq} --header-lines=1 | ${_.k8s.get_id}'';
        promptError = "you must specify a deployment to roll!";
        completion = ''${_.k} get deployment | ${_.sed} '1d' | ${_.awk} '{print $1}' '';
      }
    ];
    script = ''
      ${_.k} --namespace "$namespace" \
        patch deployment "$deployment" \
        --patch "''$(${_.refresh_patch})"
      ${_.k} --namespace "$namespace" rollout status deployment/"$deployment"
    '';
  };

  kdesc = pog {
    name = "kdesc";
    description = "a quick and easy way to describe k8s objects!";
    flags = [
      _.flags.k8s.namespace
      {
        name = "object";
        description = "the object to describe";
        prompt = ''${_.k} --namespace "$namespace" get all | ${_.fzfq} | ${_.k8s.get_id}'';
        promptError = "you must specify an object to describe!";
      }
    ];
    script = ''
      debug "''${GREEN}describing object '$object' in the '$namespace' namespace!''${RESET}"
      ${_.k} --namespace "$namespace" describe "$object"
    '';
  };

  kdrain = pog {
    name = "kdrain";
    description = "a quick and easy way to drain one or more nodes on k8s!";
    flags = [
      _.flags.common.force
      _.flags.k8s.nodes
    ];
    script = ''
      for node in $nodes; do
        green "draining node '$node'"
        ${_.k} drain ''${force:+--delete-emptydir-data --ignore-daemonsets} "$node"
      done
    '';
  };

  klog = pog {
    name = "klog";
    description = "a quick and easy way to log one or more pods!";
    flags = [
      _.flags.k8s.all_namespaces
      _.flags.k8s.namespace
      {
        name = "containers";
        description = "one or more containers to tail";
        prompt = ''${_.k} get pods --namespace "$namespace" ''${all_namespaces:+-A} ${_.k8s.fmt.pod} | ${_.fzfqm} --header-lines=1 | ${_.k8s.get_id}'';
        promptError = "you must specify one or more pods to get logs from!";
        completion = ''${_.k} get pods | ${_.sed} '1d' | ${_.awk} '{print $1}' '';
      }
    ];
    script = helpers: ''
      container_regex="($(echo "$containers" | tr '\n' '|' | ${_.sed} 's#.$##'))"
      debug "stern ''${all_namespaces:+-A} --namespace $namespace --timestamps $container_regex"
      # shellcheck disable=SC2046
      ${prev.stern}/bin/stern ''${all_namespaces:+-A} --namespace "$namespace" --timestamps "$container_regex"
    '';
  };

  k8s_pog_scripts = [
    kdesc
    kdrain
    kex
    klog
    krm
    kroll
    kshell
  ];
}
