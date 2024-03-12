{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "slack-notifier";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "cloudposse";
    repo = "slack-notifier";
    rev = version;
    hash = "sha256-7xtZV1X9Zn3Orv601q3pY3tedTDsFcmpwHTlNjO3ENE=";
  };

  vendorHash = null;

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Command line utility to send messages with attachments to Slack channels via Incoming Webhooks";
    homepage = "https://github.com/cloudposse/slack-notifier";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "slack-notifier";
  };
}
