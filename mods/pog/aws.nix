# This module makes some AWS related tools with `pog`.
final: prev:
with prev;
rec {
  aws_id = pog {
    name = "aws_id";
    description = "a quick and easy way to get your AWS account ID";
    flags = [
      _.flags.aws.region
    ];
    script = ''
      ${_.aws} sts get-caller-identity --query Account --output text --region "$region"
    '';
  };
  ecr_login = pog {
    name = "ecr_login";
    description = "a quick helper script to facilitate login to AWS ECR";
    flags = [
      _.flags.aws.region
    ];
    script = ''
      ${_.aws} ecr get-login-password --region "''${region}" |
      ${_.d} login --username AWS \
        --password-stdin "$(${_.aws} sts get-caller-identity --query Account --output text).dkr.ecr.''${region}.amazonaws.com"
    '';
  };
  ecr_login_public = pog {
    name = "ecr_login_public";
    description = "a quick helper script to facilitate login to AWS public ECR";
    flags = [
      _.flags.aws.region
    ];
    script = ''
      ${_.aws} ecr-public get-login-password --region "''${region}" |
      ${_.d} login --username AWS \
          --password-stdin public.ecr.aws
    '';
  };

  ec2_spot_interrupt =
    let
      python = pkgs.python311.withPackages (p: with p; [ requests tabulate ]);
      spots.py = writeTextFile {
        name = "spots.py";
        text = ''
          import json
          import os
          import requests
          import sys
          from tabulate import tabulate
          from dataclasses import dataclass


          FREQ = ["<5%", "5-10%", "10-15%", "15-20%", ">20%"]


          def _get(name: str, default: str = "") -> str:
              return os.getenv(name, default)


          @dataclass
          class Spot:
              name: str
              cpu: int
              ram: float
              savings: float
              interrupt: int
              emr: bool = False

              @property
              def interrupt_frequency(self) -> str:
                  return FREQ[self.interrupt]

              def __lt__(self, other) -> bool:
                  return (self.interrupt < other.interrupt) or (
                      (self.interrupt == other.interrupt) and (self.savings > other.savings)
                  )


          if __name__ == "__main__":
              region = _get("region", default="us-east-1")
              min_ram = int(_get("min_ram", default="0"))
              min_cpu = int(_get("min_cpu", default="0"))
              response = requests.get(
                  "https://spot-bid-advisor.s3.amazonaws.com/spot-advisor-data.json"
              )
              data = json.loads(response.text)
              instance_data = data["instance_types"]
              regional_data = data["spot_advisor"][region]["Linux"]
              spots = []
              for instance in regional_data:
                  stats = instance_data[instance]
                  spots.append(
                      Spot(
                          name=instance,
                          cpu=stats["cores"],
                          ram=stats["ram_gb"],
                          emr=stats["emr"],
                          interrupt=regional_data[instance]["r"],
                          savings=regional_data[instance]["s"],
                      )
                  )
              spot_list = [
                  [x.name, x.cpu, x.ram, f"{x.savings}", x.interrupt_frequency]
                  for x in sorted(spots)
                  if x.ram >= min_ram and x.cpu >= min_cpu
              ]
              text = tabulate(
                  spot_list,
                  headers=[
                      "instance type",
                      "vCPU",
                      "RAM (GiB)",
                      "% savings over OD",
                      "freq of interruption",
                  ],
              )
              print(text)
        '';
      };
    in
    pog {
      name = "ec2_spot_interrupt";
      description = "a quick and easy way to lookup aws ec2 spot interruption rates";
      flags = [
        _.flags.aws.region
        {
          name = "min_cpu";
          short = "c";
          description = "the minimum amount of vCPUs for instance lookup";
          default = "0";
        }
        {
          name = "min_ram";
          short = "m";
          description = "the minimum amount of RAM for instance lookup";
          default = "0";
        }
      ];
      script = helpers: ''
        export region
        export min_cpu
        export min_ram
        ${python}/bin/python ${spots.py}
      '';
    };

  eks_config = pog {
    name = "eks_config";
    description = "fetch a kubeconfig for the given EKS cluster";
    flags = [
      {
        name = "profile";
        description = "the profile to load the cluster from";
        envVar = "AWS_PROFILE";
      }
      {
        name = "cluster";
        description = "the cluster to load a kubeconfig for";
        envVar = "EKS_CLUSTER";
        prompt = ''
          ${_.aws} eks list-clusters --region "$AWS_REGION" | ${_.jq} -r '.clusters[]' |
          ${_.fzfqm} |
          ${_.awk} '{print $1}'
        '';
      }
      {
        name = "region";
        description = "the region of the cluster to load";
        envVar = "AWS_REGION";
      }
    ];
    script = helpers: ''
      debug "getting cluster config for '$cluster' in '$region' from the '$profile' profile"
      ${_.aws} eks update-kubeconfig --name "$cluster" ''${profile:+--profile "$profile"} --region "$region"
    '';
  };

  wasabi = pog {
    name = "wasabi";
    description = "a wrapper for awscli s3 subcommand to interact with wasabi";
    flags = [
      {
        name = "profile";
        default = "wasabi";
        envVar = "WASABI_PROFILE";
        description = "the AWS profile to reference for wasabi";
      }
      {
        name = "region";
        envVar = "WASABI_REGION";
        default = "s3.wasabisys.com";
        description = "the s3 api endpoint to use";
      }
    ];
    script = ''
      # due to https://github.com/aws/aws-cli/issues/9214
      export AWS_REQUEST_CHECKSUM_CALCULATION=when_required
      export AWS_RESPONSE_CHECKSUM_VALIDATION=when_required
      ${awscli2}/bin/aws --endpoint-url="https://$region" --profile "$profile" s3 "$@"
    '';
  };

  cloudflare_r2 = pog {
    name = "cloudflare_r2";
    description = "a wrapper for awscli s3 subcommand to interact with cloudflare";
    flags = [
      {
        name = "profile";
        default = "cloudflare";
        envVar = "CLOUDFLARE_R2_PROFILE";
        description = "the AWS profile to reference for cloudflare";
      }
      {
        name = "endpoint";
        envVar = "CLOUDFLARE_R2_ENDPOINT";
        description = "the cloudflare r2 endpoint to use";
      }
    ];
    script = ''
      # due to https://github.com/aws/aws-cli/issues/9214
      export AWS_REQUEST_CHECKSUM_CALCULATION=when_required
      export AWS_RESPONSE_CHECKSUM_VALIDATION=when_required
      ${awscli2}/bin/aws --endpoint-url="$endpoint" --profile "$profile" s3 "$@"
    '';
  };

  awslocal = pog {
    name = "awslocal";
    description = "a wrapper for awscli to interact with localstack";
    flags = [
      {
        name = "endpoint";
        description = "the aws endpoint to use";
        default = "http://localhost:9000";
      }
    ];
    script = ''
      export AWS_ACCESS_KEY_ID="test"
      export AWS_SECRET_ACCESS_KEY="test"
      export AWS_DEFAULT_REGION="us-east-1"
      ${awscli2}/bin/aws --endpoint-url="$endpoint" "$@"
    '';
  };

  aws_pog_scripts = [
    aws_id
    ecr_login
    ecr_login_public
    ec2_spot_interrupt
    eks_config
    wasabi
    cloudflare_r2
    awslocal
  ];
}
