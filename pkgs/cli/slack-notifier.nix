# [slack-notifier](https://github.com/cloudposse/slack-notifier) is a cli util to send slack messages
{ lib
, buildGoModule
, fetchFromGitHub
, nix-update-script
}:

buildGoModule rec {
  pname = "slack-notifier";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "cloudposse";
    repo = "slack-notifier";
    rev = version;
    hash = "sha256-tggrpcnIdPOgjbtM8ph4K8sLIg0lJaQjUrAj9ChW+kE=";
  };

  vendorHash = null;

  ldflags = [ "-s" "-w" ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Command line utility to send messages with attachments to Slack channels via Incoming Webhooks";
    homepage = "https://github.com/cloudposse/slack-notifier";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "slack-notifier";
  };
}
