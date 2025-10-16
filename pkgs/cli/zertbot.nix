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
          version = "2.2.0";
          pyproject = true;

          src = fetchFromGitHub {
            owner = "infinityofspace";
            repo = "pkb_client";
            rev = "refs/tags/v${version}";
            hash = "sha256-CmEDmKRTvqY/OmvxNGbin96SES5ZCOq6tQNAQpdNRUU=";
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
          version = "0.11.0";
          pyproject = true;

          src = fetchFromGitHub {
            owner = "infinityofspace";
            repo = "certbot_dns_porkbun";
            rev = "refs/tags/v${version}";
            hash = "sha256-lJG4QU4VwxhgA9OkFqAW38iqT4pwRVs0PjDE27xjb1I=";
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
  _certbot = python.pkgs.toPythonApplication python.pkgs.certbot;
in
_certbot.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    withAll = _certbot.withPlugins (p: with p; [
      certbot-dns-route53
      certbot-dns-cloudflare-latest
      certbot-dns-google
      certbot-dns-porkbun
    ]);
  };
})
