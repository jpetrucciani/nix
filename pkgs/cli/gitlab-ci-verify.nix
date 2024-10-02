# [gitlab-ci-verify](https://github.com/timo-reymann/gitlab-ci-verify) is a tool to help validate/lint gitlab ci files
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "gitlab-ci-verify";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "timo-reymann";
    repo = "gitlab-ci-verify";
    rev = "v${version}";
    hash = "sha256-wqh9vqnwshXFyhr3LWISPtSq7cX9avnWGuf31cq6FRk=";
    fetchSubmodules = true;
  };

  vendorHash = "sha256-f9zgIlxj82jfmhRJ9LPb6OlEu4Xo7Vt36FFkkpUjcok=";

  ldflags = [ "-s" "-w" ];

  meta = {
    description = "Validate and lint your gitlab ci files using ShellCheck, the Gitlab API and curated checks";
    homepage = "https://github.com/timo-reymann/gitlab-ci-verify";
    changelog = "https://github.com/timo-reymann/gitlab-ci-verify/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "gitlab-ci-verify";
  };
}
