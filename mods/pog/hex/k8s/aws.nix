{ hex, services, ... }:
let
  inherit (hex) toYAML concatStringsSep;
  inherit (services) components;
  defaults = {
    region = "us-east-2";
    image = "ghcr.io/jpetrucciani/k8s-aws";
  };
in
{
  aws_auth = { account_id, node_role_name, admins ? [ ] }:
    let
      admin_entry = user: ''
        - userarn: arn:aws:iam::${account_id}:user/${user}
          username: ${user}
          groups:
            - system:masters
      '';
      auth_map = {
        apiVersion = "v1";
        data = {
          mapRoles = ''
            - groups:
              - system:bootstrappers
              - system:nodes
              rolearn: arn:aws:iam::${account_id}:role/${node_role_name}
              username: system:node:{{EC2PrivateDNSName}}
          '';
          mapUsers = concatStringsSep "\n" (map admin_entry admins);
        };
        kind = "ConfigMap";
        metadata = {
          name = "aws-auth";
          namespace = "kube-system";
        };
      };
    in
    ''
      ---
      ${toYAML auth_map}
    '';
  ecr_cron = { account_id, region ? defaults.region, image ? defaults.image, image_tag ? "latest", aws_secret ? "aws-ecr-creds", schedule ? "0 */8 * * *" }:
    let
      name = "ecr-login";
      namespace = "default";
      sa = components.service-account { inherit name; };
      role = components.role { inherit name; rules = [{ apiGroups = [ "" ]; resources = [ "secrets" ]; verbs = [ "get" "list" "create" "patch" "update" "delete" ]; }]; };
      rb = {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "RoleBinding";
        metadata = {
          inherit name namespace;
        };
        roleRef = {
          inherit name;
          apiGroup = "rbac.authorization.k8s.io";
          kind = "Role";
        };
        subjects = [{ inherit namespace; kind = "ServiceAccount"; name = "${name}-sa"; }];
      };
      secret_name = "aws-registry";
      secret_opts = concatStringsSep " " [
        "--docker-server=https://${account_id}.dkr.ecr.${region}.amazonaws.com}"
        "--docker-username=AWS"
        "--docker-password=$(aws ecr get-login-password --region ${region})"
        "--docker-email=no@email.local"
      ];
      script = concatStringsSep " && " [
        "kubectl delete secret ${secret_name} || true"
        "kubectl create secret docker-registry ${secret_name} ${secret_opts}"
      ];
      cron = hex.k8s.cron.build {
        inherit name schedule;
        image = "${image}:${image_tag}";
        sa = "${name}-sa";
        command = "/bin/bash";
        args = [ "-c" script ];
        envFrom = [{
          secretRef = {
            name = aws_secret;
          };
        }];
      };
    in
    ''
      ---
      ${toYAML sa}
      ---
      ${toYAML role}
      ---
      ${toYAML rb}
      ---
      ${cron}
    '';
}
