final: prev:
let
  inherit (final) callPackage;
in
{
  goldilocks = callPackage
    ({ lib, buildGo122Module, fetchFromGitHub }:
      buildGo122Module rec {
        pname = "goldilocks";
        version = "4.3.3";

        src = fetchFromGitHub {
          owner = "FairwindsOps";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-M6SRXkr9hPXKwO+aQ1xYj5NUrRRo4g4vMi19XwINDXw=";
        };

        vendorHash = "sha256-pz+gjNvXsaFGLYWCPaa5zOc2TUovNaTFrvT/dW49KuQ=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Get your resource requests 'Just Right'";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  cyclonus = callPackage
    ({ lib, buildGo122Module, fetchFromGitHub }:
      buildGo122Module rec {
        pname = "cyclonus";
        version = "0.5.0";

        src = fetchFromGitHub {
          owner = "mattfenwick";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-Q6FFSb2iczJQKFx6AVs3nsZfNE6qJ9YKgajeU7MmMfI=";
        };

        vendorHash = "sha256-/IQC1vJ4MebuNp+3hvTz85w1guq5e58XM/KMQKWWQoI=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "tools for understanding, measuring, and applying network policies effectively in kubernetes";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  rbac-tool = callPackage
    ({ lib, buildGo122Module, fetchFromGitHub }:
      buildGo122Module rec {
        pname = "rbac-tool";
        version = "1.9.0";

        src = fetchFromGitHub {
          owner = "alcideio";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-EujU0Ljr+VhGQ3VMhpdP/mikHFKVARR2vRl94/tZ7As=";
        };

        vendorHash = "sha256-nADcFaVdC3UrZxqrwqjcNho/80n856Co2KG0AknflWM=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Visualize, Analyze, Generate & Query RBAC policies in Kubernetes";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };
}
