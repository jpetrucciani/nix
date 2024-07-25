# This module creates some `pog` tools that help make you more productive in Kubernetes!
final: prev:
let
  inherit (final) _ pog;
in
rec {
  ka = pog {
    name = "ka";
    version = "0.0.1";
    description = "a shorthand to see all pods";
    flags = [
      _.flags.k8s.namespace
      { name = "allnamespaces"; short = "A"; description = "load from all namespaces"; bool = true; }
      { name = "json"; description = "shorthand for json output"; bool = true; }
    ];
    script = h: with h; ''
      ns="--namespace $namespace"
      ${flag "allnamespaces"} && ns="--all-namespaces"
      if ${flag "json"}; then
        # shellcheck disable=SC2086
        ${_.k} get $ns pods --output json
      else
        # shellcheck disable=SC2086
        ${_.k} get $ns pods 
      fi
    '';
  };

  kex = pog {
    name = "kex";
    version = "0.0.1";
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
    version = "0.0.1";
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
    version = "0.0.1";
    description = "a quick and easy way to pop into an ephemeral shell on k8s!";
    flags = [
      _.flags.k8s.namespace
      _.flags.k8s.serviceaccount
      _.flags.docker.image
      {
        name = "podtimeout";
        default = "1m";
        description = "The length of time (like 5s, 2m, or 3h, higher than zero) to wait until at least one pod is running";
      }
    ];
    script = ''
      debug "''${GREEN}running image '$image' on the '$namespace' namespace!''${RESET}"
      pod_name="$(echo "''${USER:-user}-kshell-''$(${_.uuid} | ${_.head} -c 8)" | tr -cd '[:alnum:]-')"
      overrides="$(echo "json.spec.serviceAccount = \"$serviceaccount\";" | gron -u | tr -d '\n')"
      ${_.k} run \
        --stdin \
        --tty \
        --rm \
        --restart Never \
        --overrides="$overrides" \
        --namespace "$namespace" \
        --image-pull-policy=Always \
        --image="$image" \
        --pod-running-timeout="$podtimeout" \
        "$pod_name" \
        -- \
        sh -c "${_.globals.hacks.bash_or_sh}"
    '';
  };

  kroll = pog {
    name = "kroll";
    version = "0.0.1";
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
    version = "0.0.1";
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

  kedit = pog {
    name = "kedit";
    version = "0.0.1";
    description = "a quick and easy way to edit k8s objects!";
    flags = [
      _.flags.k8s.namespace
      {
        name = "object";
        description = "the object to edit";
        prompt = ''${_.k} --namespace "$namespace" get all | ${_.fzfq} | ${_.k8s.get_id}'';
        promptError = "you must specify an object to edit!";
      }
    ];
    script = ''
      debug "''${GREEN}describing object '$object' in the '$namespace' namespace!''${RESET}"
      ${_.k} --namespace "$namespace" edit "$object"
    '';
  };

  kdrain = pog {
    name = "kdrain";
    version = "0.0.1";
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
    version = "0.0.1";
    description = "a quick and easy way to log one or more pods!";
    arguments = [{ name = "FILTER"; }];
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
      {
        name = "since";
        description = "Return logs newer than a relative duration like 52, 2m, or 3h";
        default = "10m";
      }
    ];
    script = helpers: ''
      container_regex="($(echo "$containers" | tr '\n' '|' | ${_.sed} 's#.$##'))"
      debug "stern ''${all_namespaces:+-A} --namespace $namespace --timestamps $container_regex"
      # shellcheck disable=SC2046
      ${final.stern}/bin/stern ''${all_namespaces:+-A} --namespace "$namespace" --since "$since" --timestamps "$container_regex"
    '';
  };

  kdiff = pog {
    name = "kdiff";
    version = "0.0.1";
    description = "view a pretty diff of the file against the live cluster";
    arguments = [{ name = "KUBESPEC"; }];
    flags = [
      _.flags.k8s.namespace
      {
        name = "clientside";
        description = "run the diff on the clientside instead of serverside";
        short = "";
        bool = true;
      }
    ];
    script = helpers: with helpers; ''
      spec="$1"
      ${file.notExists "spec"} && die "the file to render ('$spec') does not exist!"
      side="true"
      ${flag "clientside"} && side="false"
      ${_.k} diff --namespace "$namespace" --server-side="$side" -f "$spec" | ${final.delta}/bin/delta
    '';
  };

  ksecedit = pog {
    name = "ksecedit";
    version = "0.0.1";
    description = "edit a k8s secret quickly and easily, inline!";
    flags = [
      _.flags.k8s.namespace
      {
        name = "secret";
        description = "the secret to edit. if not passed in, a dialog will pop up to select from";
        prompt = ''${_.k} --namespace "$namespace" get secret | ${_.fzfq} --header-lines=1 | ${_.k8s.get_id}'';
        promptError = "you must specify a secret to edit!";
        completion = ''${_.k} get secret | ${_.sed} '1d' | ${_.awk} '{print $1}' '';
      }
    ];
    script = helpers: with helpers; ''
      ${_.k} --namespace "$namespace" get secret "$secret" -o yaml | \
        ${_.yq} '.dataStrings = (.data | map_values(@base64d)) | del(.data)' | \
        ${final.moreutils}/bin/vipe | \
        ${_.yq} '.data = (.dataStrings | map_values(@base64)) | del(.dataStrings)' | \
        ${_.k} apply -f --server-side=true -
    '';
  };

  refresh_secret = pog {
    name = "refresh_secret";
    description = "a quick and easy way to refresh external secrets!";
    flags = [
      _.flags.k8s.namespace
      {
        name = "secret";
        description = "the secret to refresh";
        prompt = ''
          ${_.k} --namespace "$namespace" get externalsecret.external-secrets.io |
            ${_.fzfqm} --header-lines=1 |
            ${_.awk} '{ print $1 }'
        '';
        promptError = "you must specify an external secret to refresh!";
      }
    ];
    script = ''
      echo "''${secret}" | ${_.xargs} -I {} --no-run-if-empty \
        ${_.k} annotate --overwrite externalsecret.external-secrets.io {} refresh="$(${_.date} +%s)"
    '';
  };

  k8s_pog_scripts = [
    ka
    kdesc
    kdiff
    kdrain
    kedit
    ksecedit
    kex
    klog
    krm
    kroll
    kshell
    refresh_secret
  ];
}
