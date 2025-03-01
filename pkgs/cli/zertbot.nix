{ fetchFromGitHub
, fetchPypi
, lib
, python311
, python3 ? python311
}:

let
  python = python3.override {
    self = python;
    packageOverrides = final: prev:
      let
        inherit (final) buildPythonPackage;
      in
      {
        josepy = prev.josepy.overridePythonAttrs (old: rec {
          version = "1.15.0";
          src = fetchFromGitHub {
            owner = "certbot";
            repo = "josepy";
            tag = "v${version}";
            hash = "sha256-fK4JHDP9eKZf2WO+CqRdEjGwJg/WNLvoxiVrb5xQxRc=";
          };
          dependencies = with final; [
            pyopenssl
            cryptography
          ];
        });
        certbot-dns-route53 = prev.certbot-dns-route53.overridePythonAttrs (old: {
          pytestFlagsArray = old.pytestFlagsArray ++ [ "-W ignore::DeprecationWarning" ];
        });
        certbot-dns-cloudflare-latest = buildPythonPackage
          rec {
            pname = "certbot-dns-cloudflare";
            version = "3.1.0";
            pyproject = true;

            src = fetchPypi {
              pname = "certbot_dns_cloudflare";
              inherit version;
              hash = "sha256-oktsloLV/CwzYLJ+y19NKfMYjOgAm3miTBnkfK6jzgM=";
            };

            build-system = with final; [
              setuptools
              wheel
            ];

            dependencies = with final; [
              acme
              certbot
              (buildPythonPackage rec {
                pname = "cloudflare";
                version = "2.19.4";
                pyproject = true;

                src = fetchPypi {
                  inherit pname version;
                  hash = "sha256-O2AAoBojfCO8z99tICVupREex0qCaunnT58OW7WyOD8=";
                };

                build-system = [
                  setuptools
                  wheel
                ];

                dependencies = [
                  anyio
                  distro
                  httpx
                  jsonlines
                  pydantic
                  pyyaml
                  requests
                  sniffio
                  typing-extensions
                ];

                pythonImportsCheck = [
                  "CloudFlare"
                ];

                meta = {
                  description = "The official Python library for the cloudflare API";
                  homepage = "https://pypi.org/project/cloudflare/2.19.4/";
                  license = lib.licenses.mit;
                  maintainers = with lib.maintainers; [ jpetrucciani ];
                };
              })
            ];

            optional-dependencies = with final; {
              docs = [
                sphinx
                sphinx-rtd-theme
              ];
              test = [
                pytest
              ];
            };

            pythonImportsCheck = [
              "certbot_dns_cloudflare"
            ];

            meta = {
              description = "Cloudflare DNS Authenticator plugin for Certbot";
              homepage = "https://pypi.org/project/certbot-dns-cloudflare/#history";
              license = lib.licenses.asl20;
              maintainers = with lib.maintainers; [ jpetrucciani ];
            };
          };

        pkb-client = buildPythonPackage rec {
          pname = "pkb-client";
          version = "2.0.0";
          pyproject = true;

          src = fetchFromGitHub {
            owner = "infinityofspace";
            repo = "pkb_client";
            rev = "refs/tags/v${version}";
            hash = "sha256-crV4Yi2UO5G+6N/dU07FoUFGA1pBRd2ef1ytTptHTl8=";
          };

          build-system = with final; [
            setuptools
            wheel
          ];

          dependencies = with final; [
            dnspython
            requests
            setuptools
          ];

          pythonImportsCheck = [
            "pkb_client"
          ];

          meta = {
            description = "Python client for the Porkbun API";
            homepage = "https://pypi.org/project/pkb-client/";
            license = lib.licenses.mit;
            maintainers = with lib.maintainers; [ jpetrucciani ];
          };
        };

        certbot-dns-porkbun = buildPythonPackage rec {
          pname = "certbot-dns-porkbun";
          version = "0.9";
          pyproject = true;

          src = fetchFromGitHub {
            owner = "infinityofspace";
            repo = "certbot_dns_porkbun";
            rev = "refs/tags/v${version}";
            hash = "sha256-I19NtwoPg5GiFgFkCXI78tApx1xd5Yqv/NlTOsa6tz4=";
          };

          build-system = with final; [
            setuptools
            wheel
          ];

          dependencies = with final; [
            certbot
            dnspython
            pkb-client
            setuptools
            tldextract
          ];

          pythonImportsCheck = [
            "certbot_dns_porkbun"
          ];

          meta = {
            description = "Plugin for certbot to obtain certificates using a DNS TXT record for Porkbun domains";
            homepage = "https://pypi.org/project/certbot-dns-porkbun/";
            license = lib.licenses.mit;
            maintainers = with lib.maintainers; [ jpetrucciani ];
          };
        };
      };
  };
in
with python.pkgs;
toPythonApplication certbot
