{ lib
, buildDotnetModule
, dotnetCorePackages
, fetchFromGitHub
}:

let
  dotnet-sdk = dotnetCorePackages.sdk_10_0;
in
buildDotnetModule (finalAttrs: {
  pname = "roslyn-mcp";
  version = "0-unstable-2026-06-18";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "RoslynMCP";
    rev = "c3dacbf84363ab6ae916326ea1f9c68b98a267e3";
    hash = "sha256-fqh0RKJhJRD9HxUftjISh/nFAyKZSqphuj6aJAUHJmI=";
  };

  projectFile = "RoslynMcpServer/RoslynMcpServer.csproj";
  nugetDeps = ./deps.json;

  dotnetRestoreFlags = [ "-p:TargetFrameworks=net10.0" ];
  dotnetBuildFlags = [ "--framework" "net10.0" ];
  dotnetInstallFlags = [ "--framework" "net10.0" ];

  inherit dotnet-sdk;
  dotnet-runtime = dotnet-sdk;

  executables = [ "RoslynMcpServer" ];

  postFixup = ''
    ln -s "$out/bin/RoslynMcpServer" "$out/bin/roslyn-mcp"
  '';

  meta = {
    description = "MCP server for C# code analysis and navigation using Roslyn";
    homepage = "https://github.com/jpetrucciani/RoslynMCP";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "roslyn-mcp";
    platforms = dotnet-sdk.meta.platforms;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode
    ];
  };
})
