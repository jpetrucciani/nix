# [kubeshark](https://github.com/kubeshark/kubeshark) is a k8s traffic analyzers
{ stdenvNoCC, fetchurl, autoPatchelfHook, installShellFiles, lib }:
let
  dists = {
    aarch64-darwin = {
      arch = "arm64";
      short = "darwin";
      sha256 = "02nm3iwbwqh2w71hbfqjhfwns9j6014crg4y1m4gd9n3wpdjd5a0";
    };
    aarch64-linux = {
      arch = "arm64";
      short = "linux";
      sha256 = "1fpwg605j7w1r9zw35i8d4mz5126nhaipmhrhf91hj5p4v9aq2hv";
    };
    x86_64-darwin = {
      arch = "amd64";
      short = "darwin";
      sha256 = "1dn71d0is2j85z88zh2qv2z0dzk1i34msq0i4ac1vm850i34hbmp";
    };
    x86_64-linux = {
      arch = "amd64";
      short = "linux";
      sha256 = "11cqw8visi7ymw23ys6i9g8ndp5zywcrhrx9rrkhzgpkjyzghjzv";
    };
  };
  dist = dists.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
  pname = "kubeshark";
  owner = "kubeshark";
  version = "37.0";
in
stdenvNoCC.mkDerivation rec {
  inherit pname version;

  src = fetchurl {
    inherit (dist) sha256;
    url = "https://github.com/${owner}/${pname}/releases/download/${version}/${pname}_${dist.short}_${dist.arch}";
  };

  strictDeps = true;
  nativeBuildInputs = [ installShellFiles ] ++ (lib.optionals stdenvNoCC.isLinux [ autoPatchelfHook ]);

  dontConfigure = true;
  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/kubeshark
    chmod +x $out/bin/kubeshark
  '';

  postInstall = ''
    installShellCompletion --cmd kubeshark \
      --bash <($out/bin/kubeshark completion bash) \
      --fish <($out/bin/kubeshark completion fish) \
      --zsh  <($out/bin/kubeshark completion zsh)
  '';

  meta = with lib; {
    license = licenses.mit;
    mainProgram = "kubeshark";
  };
}
