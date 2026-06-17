{ lib
, buildDotnetModule
, dotnetCorePackages
, fetchFromGitHub
, perl
}:

let
  dotnet-sdk = dotnetCorePackages.sdk_10_0;
in
buildDotnetModule (finalAttrs: {
  pname = "roslyn-mcp";
  version = "0-unstable-2025-06-24";

  src = fetchFromGitHub {
    owner = "carquiza";
    repo = "RoslynMCP";
    rev = "4691f95d52b6c7b29f120659aa564e8abef48e46";
    hash = "sha256-YrGRtl/q1KEHnNpEsef8VB/nhtF6Cu+bXrh6inEQlII=";
  };

  projectFile = "RoslynMcpServer/RoslynMcpServer.csproj";
  nugetDeps = ./deps.json;

  postPatch = ''
    # Three upstream .cs files are checked in as JSON-escaped text.
    perl -0pi -e 's/\\\\/\x01/g; s/\\n/\n/g; s/\\"/"/g; s/\x01/\\/g; s/"\z/\n/' \
      RoslynMcpServer/Services/IncrementalAnalyzer.cs \
      RoslynMcpServer/Services/SymbolSearchService.cs \
      RoslynMcpServer/Tools/CodeNavigationTools.cs

    substituteInPlace RoslynMcpServer/Services/SecurityValidator.cs \
      --replace-fail 'private readonly Regex _safePath = new(@"^[a-zA-Z]:[\\/][^<>:|?*]+$");' \
      'private readonly Regex _safePath = new(@"^([a-zA-Z]:[\\/][^<>:|?*]+|/[^<>:|?*]+)$");'

    substituteInPlace RoslynMcpServer/RoslynMcpServer.csproj \
      --replace-fail '<TargetFramework>net8.0</TargetFramework>' \
      '<TargetFramework>net10.0</TargetFramework>'

    cat > RoslynMcpServer/Services/CodeAnalysisService.cs <<'CSHARP'
    using Microsoft.CodeAnalysis;
    using Microsoft.CodeAnalysis.CSharp.Syntax;
    using Microsoft.CodeAnalysis.MSBuild;
    using Microsoft.Extensions.Logging;
    using RoslynMcpServer.Models;
    using System.Collections.Concurrent;

    namespace RoslynMcpServer.Services
    {
        public class CodeAnalysisService
        {
            private readonly ILogger<CodeAnalysisService> _logger;
            private readonly ConcurrentDictionary<string, Solution> _solutionCache = new();
            private readonly ConcurrentDictionary<string, MSBuildWorkspace> _workspaces = new();

            public CodeAnalysisService(ILogger<CodeAnalysisService> logger)
            {
                _logger = logger;
            }

            public async Task<Solution> GetSolutionAsync(string solutionPath)
            {
                var fullPath = Path.GetFullPath(solutionPath);
                if (_solutionCache.TryGetValue(fullPath, out var cachedSolution))
                {
                    return cachedSolution;
                }

                if (!File.Exists(fullPath))
                {
                    throw new FileNotFoundException("Solution or project file not found.", fullPath);
                }

                var workspace = MSBuildWorkspace.Create();
                workspace.WorkspaceFailed += (_, args) =>
                {
                    _logger.LogWarning("MSBuild workspace diagnostic: {Diagnostic}", args.Diagnostic.Message);
                };

                Solution solution;
                var extension = Path.GetExtension(fullPath);
                if (extension.Equals(".sln", StringComparison.OrdinalIgnoreCase))
                {
                    solution = await workspace.OpenSolutionAsync(fullPath);
                }
                else if (extension.Equals(".csproj", StringComparison.OrdinalIgnoreCase))
                {
                    var project = await workspace.OpenProjectAsync(fullPath);
                    solution = project.Solution;
                }
                else
                {
                    throw new NotSupportedException("Only .sln and .csproj files are supported.");
                }

                _workspaces[fullPath] = workspace;
                _solutionCache[fullPath] = solution;
                return solution;
            }

            public async Task<DependencyAnalysis> AnalyzeDependenciesAsync(string solutionPath, int maxDepth)
            {
                var solution = await GetSolutionAsync(solutionPath);
                var analysis = new DependencyAnalysis
                {
                    ProjectName = Path.GetFileNameWithoutExtension(solutionPath)
                };
                var namespaceUsages = new Dictionary<string, NamespaceUsage>(StringComparer.Ordinal);
                var dependencies = new Dictionary<string, ProjectDependency>(StringComparer.Ordinal);

                foreach (var project in solution.Projects.Where(project => project.SupportsCompilation))
                {
                    foreach (var projectReference in project.ProjectReferences)
                    {
                        var referencedProject = solution.GetProject(projectReference.ProjectId);
                        AddDependency(dependencies, referencedProject?.Name ?? projectReference.ProjectId.Id.ToString(), "ProjectReference");
                    }

                    foreach (var metadataReference in project.MetadataReferences)
                    {
                        if (!string.IsNullOrEmpty(metadataReference.Display))
                        {
                            AddDependency(dependencies, Path.GetFileNameWithoutExtension(metadataReference.Display), "MetadataReference");
                        }
                    }

                    var compilation = await project.GetCompilationAsync();
                    if (compilation != null)
                    {
                        var symbols = GetSymbols(compilation.Assembly.GlobalNamespace).ToList();
                        analysis.TotalSymbols += symbols.Count;
                        analysis.PublicSymbols += symbols.Count(symbol => symbol.DeclaredAccessibility == Accessibility.Public);
                        analysis.InternalSymbols += symbols.Count(symbol => symbol.DeclaredAccessibility == Accessibility.Internal);
                    }

                    foreach (var document in project.Documents)
                    {
                        var root = await document.GetSyntaxRootAsync();
                        if (root == null)
                        {
                            continue;
                        }

                        foreach (var usingDirective in root.DescendantNodes().OfType<UsingDirectiveSyntax>())
                        {
                            var namespaceName = usingDirective.Name?.ToString();
                            if (!string.IsNullOrWhiteSpace(namespaceName))
                            {
                                AddNamespaceUsage(namespaceUsages, namespaceName);
                            }
                        }
                    }
                }

                analysis.Dependencies = dependencies.Values
                    .OrderByDescending(dependency => dependency.UsageCount)
                    .ThenBy(dependency => dependency.Name)
                    .Take(Math.Max(1, maxDepth) * 20)
                    .ToList();
                analysis.NamespaceUsages = namespaceUsages.Values
                    .OrderByDescending(namespaceUsage => namespaceUsage.UsageCount)
                    .ThenBy(namespaceUsage => namespaceUsage.Namespace)
                    .ToList();

                return analysis;
            }

            private static IEnumerable<ISymbol> GetSymbols(INamespaceOrTypeSymbol container)
            {
                foreach (var member in container.GetMembers())
                {
                    yield return member;

                    if (member is INamespaceOrTypeSymbol nestedContainer)
                    {
                        foreach (var nestedMember in GetSymbols(nestedContainer))
                        {
                            yield return nestedMember;
                        }
                    }
                }
            }

            private static void AddDependency(Dictionary<string, ProjectDependency> dependencies, string name, string type)
            {
                var key = type + ":" + name;
                if (!dependencies.TryGetValue(key, out var dependency))
                {
                    dependency = new ProjectDependency
                    {
                        Name = name,
                        Type = type,
                        Version = string.Empty
                    };
                    dependencies[key] = dependency;
                }

                dependency.UsageCount++;
            }

            private static void AddNamespaceUsage(Dictionary<string, NamespaceUsage> namespaceUsages, string namespaceName)
            {
                if (!namespaceUsages.TryGetValue(namespaceName, out var namespaceUsage))
                {
                    namespaceUsage = new NamespaceUsage
                    {
                        Namespace = namespaceName
                    };
                    namespaceUsages[namespaceName] = namespaceUsage;
                }

                namespaceUsage.UsageCount++;
            }
        }
    }
    CSHARP
  '';

  nativeBuildInputs = [ perl ];

  inherit dotnet-sdk;
  dotnet-runtime = dotnet-sdk;

  executables = [ "RoslynMcpServer" ];

  postFixup = ''
    ln -s "$out/bin/RoslynMcpServer" "$out/bin/roslyn-mcp"
  '';

  meta = {
    description = "MCP server for C# code analysis and navigation using Roslyn";
    homepage = "https://github.com/carquiza/RoslynMCP";
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
