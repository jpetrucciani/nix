# This module makes some GCP related tools with `pog`.
final: prev:
with prev;
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
      }
      {
        name = "cluster";
        description = "the cluster to load a kubeconfig for";
        envVar = "CLOUDSDK_CONTAINER_CLUSTER";
        prompt = ''
          ${_.gcloud} container clusters list 2>/dev/null |
          ${_.fzfqm} --header-lines=1 |
          ${_.awk} '{print $1}'
        '';
      }
    ];
    script = helpers: ''
      debug "getting cluster config for '$cluster' in '$region'"
      region="$(${_.gcloud} container clusters list --project "$project" 2>/dev/null | grep -E "^$cluster " | ${_.awk} '{print $2}')"

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

  gcp_get_gke_build =
    let
      inherit (final._) curl head jq;
      nurl = "${final._._nix}/bin/nix-prefetch-url";
      base_url = "https://dl.google.com/dl/cloudsdk/channels/rapid/components/google-cloud-sdk-gke-gcloud-auth-plugin-";
    in
    pog {
      name = "gcp_get_gke_build";
      description = "a way for us to get the build number and version of 'gke-gcloud-auth-plugin' because google hates us";
      flags = [
        {
          name = "gversion";
          description = "the version of gcloud we want to check resources for";
          default = "452.0.1";
        }
      ];
      script = ''
        channel="https://dl.google.com/dl/cloudsdk/channels/rapid/components-v$gversion.json"
        data=$(${curl} -s "$channel" | ${jq} -c '.components[] | select(.id|contains("gke-gcloud-auth-plugin-darwin")) | .version' | ${head} -1)
        version=$(echo "$data" | ${jq} -r '.build_number')
        echo "pulled data for: $data"
        echo "arm64 darwin"
        ${nurl} "${base_url}darwin-arm-$version.tar.gz" 2>/dev/null
        echo "arm64 linux"
        ${nurl} "${base_url}linux-arm-$version.tar.gz" 2>/dev/null
        echo "x86_64 darwin"
        ${nurl} "${base_url}darwin-x86_64-$version.tar.gz" 2>/dev/null
        echo "x86_64 linux"
        ${nurl} "${base_url}linux-x86_64-$version.tar.gz" 2>/dev/null
      '';
    };

  gcp_pog_scripts = [
    glist
    gcp_perm
    gke_config
    gcp_get_gke_build
  ];
}
