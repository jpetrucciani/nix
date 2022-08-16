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
  gcp_pog_scripts = [
    glist
    gke_config
  ];
}
