final: prev:
with prev;
let
  inherit (stdenv) isLinux isDarwin isAarch64;
  isM1 = isDarwin && isAarch64;
in
rec {
  katafygio = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        pname = "katafygio";
        version = "0.8.3";

        src = fetchFromGitHub {
          owner = "bpineau";
          repo = "katafygio";
          rev = "v${version}";
          sha256 = "sha256-0UjhkQeR+97OZRug85e/mfri5ZZW3KaNJyCHT+9/7s4=";
        };

        vendorSha256 = "sha256-641dqcjPXq+iLx8JqqOzk9JsKnmohqIWBeVxT1lUNWU=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Dump, or continuously backup Kubernetes objects as yaml files in git";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  kube-linter = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        pname = "kube-linter";
        version = "0.4.0";

        src = fetchFromGitHub {
          owner = "stackrox";
          repo = "kube-linter";
          rev = version;
          sha256 = "sha256-XAsPbl9fqYk2nhDxRg5wyPwciwSpfigoBZ4hzdWAVgw=";
        };

        vendorSha256 = "sha256-0bjAIHSjw0kHrh9CzJHv1UAaBJDn6381055eOHufvCw=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description =
            "static analysis tool that checks Kubernetes YAML files and Helm charts to ensure the applications represented in them adhere to best practices";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  pluto = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        pname = "pluto";
        version = "5.9.0";

        src = fetchFromGitHub {
          owner = "FairwindsOps";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-Rwilj6+HEAriYO+zlErSN0dDMZIKFq/z5oSoSlCLZFg=";
        };

        vendorSha256 = "sha256-l2EO1L64ldhinGRGFY13A2ftT/ho6fYrA0dFG6jUX2Q=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "A cli tool to help discover deprecated apiVersions in Kubernetes";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  goldilocks = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        pname = "goldilocks";
        version = "4.3.3";

        src = fetchFromGitHub {
          owner = "FairwindsOps";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-M6SRXkr9hPXKwO+aQ1xYj5NUrRRo4g4vMi19XwINDXw=";
        };

        vendorSha256 = "sha256-pz+gjNvXsaFGLYWCPaa5zOc2TUovNaTFrvT/dW49KuQ=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Get your resource requests 'Just Right'";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  polaris = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        pname = "polaris";
        version = "6.0.0";

        src = fetchFromGitHub {
          owner = "FairwindsOps";
          repo = pname;
          rev = version;
          sha256 = "sha256-Q0jDySEmzCrjCmc4H9ap/AmopNtdAq4zOAh/6LZ/dFo=";
        };

        vendorSha256 = "sha256-SC86x2vE1TNZBxDNxyxjOPILdQbGAfSz5lmaC9qCkoE=";
        doCheck = false;

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "Validation of best practices in your Kubernetes clusters";
          license = licenses.asl20;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  cyclonus = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        pname = "cyclonus";
        version = "0.5.0";

        src = fetchFromGitHub {
          owner = "mattfenwick";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-Q6FFSb2iczJQKFx6AVs3nsZfNE6qJ9YKgajeU7MmMfI=";
        };

        vendorSha256 = "sha256-/IQC1vJ4MebuNp+3hvTz85w1guq5e58XM/KMQKWWQoI=";

        meta = with lib; {
          inherit (src.meta) homepage;
          description = "tools for understanding, measuring, and applying network policies effectively in kubernetes";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };

  rbac-tool = prev.callPackage
    ({ stdenv, lib, buildGo118Module, fetchFromGitHub }:
      buildGo118Module rec {
        pname = "rbac-tool";
        version = "1.8.0";

        src = fetchFromGitHub {
          owner = "alcideio";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-QbGIoU3tVH726t+Vn59KM+jbnPQ/u0aujvjrzE+94rk=";
        };

        vendorSha256 = "sha256-nADcFaVdC3UrZxqrwqjcNho/80n856Co2KG0AknflWM=";

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
