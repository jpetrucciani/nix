# [genai-toolbox](https://github.com/googleapis/genai-toolbox) is an open source MCP server for databases, designed and built with enterprise-quality and production-grade usage in mind
{ lib
, buildGoModule
, fetchFromGitHub
}:
buildGoModule rec {
  pname = "genai-toolbox";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "googleapis";
    repo = "genai-toolbox";
    rev = "v${version}";
    hash = "sha256-hA0eiYcNtSFZQXx6Mo1bN+zuFDxn2wr85btxUVsvmTo=";
    fetchSubmodules = true;
  };

  postPatch = ''
    # they default to binding to port 5000, which is no longer usable on darwin!
    sed -i -E 's#5000#5001#g' ./internal/server/server_test.go
  '';

  vendorHash = "sha256-kyHWZ2OXf3w4RX2ywwNGPPFAOoNIC2RK2tlrnInvizo=";
  ldflags = [ "-s" "-w" ];

  meta = {
    description = "MCP Toolbox for Databases is an open source MCP server for databases, designed and built with enterprise-quality and production-grade usage in mind";
    homepage = "https://github.com/googleapis/genai-toolbox";
    changelog = "https://github.com/googleapis/genai-toolbox/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "genai-toolbox";
  };
}
