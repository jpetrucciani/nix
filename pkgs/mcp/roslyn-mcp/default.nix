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
    rev = "54a8b6db99cc1fcf73568bd89636e1ddbc04a406";
    hash = "sha256-jvuZhh2jXlFnq5HhUGkR4bs39hBLw+j+utt7UADOeSI=";
  };

  projectFile = "RoslynMcpServer/RoslynMcpServer.csproj";
  nugetDeps = ./deps.json;

  postPatch = ''
    substituteInPlace RoslynMcpServer/RoslynMcpServer.csproj \
      --replace-fail '<TargetFramework>net8.0</TargetFramework>' \
      '<TargetFramework>net10.0</TargetFramework>'
  '';

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
