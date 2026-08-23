# This module makes some GCP related tools with `pog`.
final: prev:
let
  inherit (final) _ pog;
  completion = pog.completions;
  gcpProjectCompletion = completion.dynamic {
    runtimeInputs = [ final.google-cloud-sdk ];
    script = ''
      gcloud --quiet projects list --format='value(projectId)' 2>/dev/null || true
    '';
    cache = {
      ttlSeconds = 300;
      by = [{ env = "CLOUDSDK_CONFIG"; }];
    };
  };
  gkeClusterCompletion = completion.dynamic {
    runtimeInputs = [ final.google-cloud-sdk ];
    script = ''
      project="''${POG_COMPLETION_FLAG_PROJECT-}"
      [ -n "$project" ] || project="''${GCP_PROJECT-}"
      [ -n "$project" ] || project="''${CLOUDSDK_CORE_PROJECT-}"

      args=(--quiet container clusters list --format='value(name,location)')
      [ -z "$project" ] || args+=(--project "$project")
      gcloud "''${args[@]}" 2>/dev/null || true
    '';
    cache = {
      ttlSeconds = 60;
      by = [
        { flag = "project"; }
        { env = "GCP_PROJECT"; }
        { env = "CLOUDSDK_CORE_PROJECT"; }
        { env = "CLOUDSDK_CONFIG"; }
      ];
    };
  };
  gcpSecretCompletion = completion.dynamic {
    runtimeInputs = [ final.google-cloud-sdk ];
    script = ''
      project="''${POG_COMPLETION_FLAG_PROJECT-}"
      [ -n "$project" ] || project="''${GCP_PROJECT-}"
      [ -n "$project" ] || project="''${CLOUDSDK_CORE_PROJECT-}"

      args=(--quiet secrets list --format='value(name,createTime)')
      [ -z "$project" ] || args+=(--project "$project")
      gcloud "''${args[@]}" 2>/dev/null || true
    '';
    cache = {
      ttlSeconds = 60;
      by = [
        { flag = "project"; }
        { env = "GCP_PROJECT"; }
        { env = "CLOUDSDK_CORE_PROJECT"; }
        { env = "CLOUDSDK_CONFIG"; }
      ];
    };
  };
in
rec {
  glist = pog {
    name = "glist";
    description = "list out the gcloud projects that we can see!";
    script = ''
      ${_.gcloud} projects list
    '';
  };

  gke_config = pog {
    name = "gke_config";
    description = "fetch a kubeconfig for the given cluster";
    flags = [
      {
        name = "project";
        description = "the project to load the cluster from";
        envVar = "GCP_PROJECT";
        required = true;
        completion = gcpProjectCompletion;
      }
      {
        name = "cluster";
        description = "the cluster to load a kubeconfig for";
        envVar = "CLOUDSDK_CONTAINER_CLUSTER";
        completion = gkeClusterCompletion;
        prompt = ''
          ${_.gcloud} container clusters list --project "$project" 2>/dev/null |
          ${_.fzfqm} --header-lines=1 |
          ${_.awk} '{print $1}'
        '';
      }
    ];
    script = helpers: ''
      region="$(${_.gcloud} container clusters list \
        --project "$project" \
        --filter="name=$cluster" \
        --format='value(location)' \
        2>/dev/null | ${_.head} -n 1)"
      debug "getting cluster config for '$cluster' in '$region'"

      ${_.gcloud} \
        container clusters get-credentials \
        "$cluster" \
        --project "$project" \
        --region "$region"
    '';
  };

  gcp_perm = pog {
    name = "gcp_perm";
    description = "a quick and easy way to get gcp permissions for a user";
    flags = [
      {
        name = "project";
        description = "the project to load permissions for";
        envVar = "GCP_PROJECT";
        required = true;
        completion = gcpProjectCompletion;
      }
      {
        name = "email";
        description = "the email of the user or service account to search for iam bindings";
        required = true;
      }
    ];
    script = helpers: ''
      ${_.gcloud} projects get-iam-policy "$project" \
        --flatten="bindings[].members" \
        --format='table(bindings.role)' \
        --filter="bindings.members:''${email}"
    '';
  };

  gcp_edit_json_secret =
    let
      mktemp = "${final.coreutils}/bin/mktemp --suffix=.json";
      gcloud = ''${final.google-cloud-sdk}/bin/gcloud --project "$project"'';
      first = ''${final.gawk}/bin/awk '{ print $1 }' '';
      jq = "${final.jq}/bin/jq";
      grep = "${final.gnugrep}/bin/grep";
      dyff = "${final.dyff}/bin/dyff between --omit-header";
    in
    pog {
      name = "gcp_edit_json_secret";
      description = "";
      flags = [
        { name = "project"; envVar = "GCP_PROJECT"; completion = gcpProjectCompletion; }
        {
          name = "secret";
          envVar = "GCP_SECRET";
          completion = gcpSecretCompletion;
          prompt = ''${gcloud} secrets list | ${_.fzfq} --header-lines=1 | ${first}'';
          promptError = "you must specify a secret to edit!";
        }
      ];
      script = h: ''
        EDITOR="''${EDITOR:-${final.nano}/bin/nano}"
        TEMP_FILE="$(${mktemp})"
        TEMP_FILE_ORIG="$(${mktemp})"
        ERROR_FILE="$(${mktemp})"
        trap 'rm -f "$TEMP_FILE" "$TEMP_FILE_ORIG" "$ERROR_FILE"' EXIT

        debug "fetching latest secret version for '$secret'"
        if ! ${gcloud} secrets versions access latest --secret="$secret" >"$TEMP_FILE" 2>/dev/null; then
          die "failed to fetch secret. please check if the secret exists and you have proper permissions!"
        fi

        cp "$TEMP_FILE" "$TEMP_FILE_ORIG"

        if ${jq} . "$TEMP_FILE" >/dev/null 2>&1; then
          ${jq} . "$TEMP_FILE" >"$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"
        fi

        while true; do
          if [ -s "$ERROR_FILE" ]; then
              # Create a temporary file with error messages and original content
              {
                  echo "# if you want to cancel editing, exit the editor without making changes"
                  echo "#"
                  echo "# error messages:"
                  while IFS= read -r line; do
                      echo "# $line"
                  done < "$ERROR_FILE"
                  echo "#"
                  cat "$TEMP_FILE"
              } > "$TEMP_FILE.tmp"
              mv "$TEMP_FILE.tmp" "$TEMP_FILE"
          else
              # First run or no errors - add basic instructions
              {
                  echo "# edit the secret content below."
                  echo "# if you want to cancel editing, exit the editor without making changes"
                  echo "#"
                  cat "$TEMP_FILE"
              } > "$TEMP_FILE.tmp"
              mv "$TEMP_FILE.tmp" "$TEMP_FILE"
          fi

          eval "$EDITOR" "$TEMP_FILE"

          # Remove any comment lines starting with #
          ${grep} -v '^#' "$TEMP_FILE" > "$TEMP_FILE.tmp"
          mv "$TEMP_FILE.tmp" "$TEMP_FILE"

          ${grep} -v '^#' "$TEMP_FILE_ORIG" > "$TEMP_FILE_ORIG.tmp"

          JSON_ERROR=$(jq . "$TEMP_FILE" 2>&1 >/dev/null)
          # shellcheck disable=SC2181
          if [ $? -ne 0 ]; then
              red "invalid JSON formatting!"
              red "$JSON_ERROR"
              echo "$JSON_ERROR" >"$ERROR_FILE"
              echo '---'
              ${h.confirm {prompt="retry editing?";}}
              continue
          fi

          break
        done

        ${jq} . "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"
        ${dyff} --set-exit-code "$TEMP_FILE_ORIG" "$TEMP_FILE"
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
          green "no changes made - exiting!"
          exit 0
        fi

        echo "---"
        ${h.confirm {prompt="Would you like to apply these changes to the secret '$secret'?";}}
        echo "---"

        debug "adding new version of secret '$secret'"
        if ! ${gcloud} secrets versions add "$secret" --data-file="$TEMP_FILE"; then
            die "failed to add new version of secret"
        fi
      '';
    };

  gcp_pog_scripts = [
    glist
    gcp_perm
    gke_config
    gcp_edit_json_secret
  ];
}
