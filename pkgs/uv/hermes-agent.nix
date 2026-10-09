# [hermes-agent](https://github.com/NousResearch/hermes-agent) is a self-improving AI agent CLI
{ stdenv
, lib
, python314
, rsync
, makeWrapper
, ffmpeg
, git
, libopus
, nodejs_22
, ripgrep
, uv-nix
}:
let
  name = "hermes-agent";
  version = "0.21.6";

  src = uv-nix.fetchGitHubWorkspace {
    owner = "NousResearch";
    repo = name;
    rev = "refs/tags/v${version}";
    hash = "12pcg3zis64mpq90jd28gk8pil74bdj86pgqqmw2chd5yvwghi4w";
  };

  uvEnv = uv-nix.mkEnv {
    inherit name;
    gitignore = false;
    python = python314;
    workspaceRoot = src;
    # Add common backends to upstream's runtime extras without pulling every opt-in stack and dev tools.
    _deps = { hermes-agent = [ "all" "messaging" "ddgs" "edge-tts" ]; };
    pyprojectOverrides = _: prev: {
      hermes-agent = prev.hermes-agent.overrideAttrs (_: {
        HERMES_NIX_BUILD = "1";
      });
    };
  };

  hermesDataDirs = [
    "skills"
    "optional-skills"
    "locales"
    "optional-mcps"
  ];

  hermesSupportFiles = [
    ".env.example"
    "cli-config.yaml.example"
    "pyproject.toml"
    "uv.lock"
  ];

  installStamp = builtins.toJSON {
    schemaVersion = 2;
    commit = "818c13be1dc4fd28987e1e881a9408224afd4535";
    baseVersion = version;
    displayVersion = version;
    distance = 0;
    source = "nix";
    distribution = "nix";
    updateMechanism = "external";
    payload = "bootstrap";
    tag = "v${version}";
    dirty = false;
  };

  site = python314.sitePackages;
  opusLibPath = "${lib.getLib libopus}/lib/libopus${stdenv.hostPlatform.extensions.sharedLibrary}.0";

  runtimePath = lib.makeBinPath [
    ffmpeg
    git
    nodejs_22
    ripgrep
  ];
  runtimeLibraryPath = lib.makeLibraryPath [ libopus ];
in
stdenv.mkDerivation {
  inherit version src;
  pname = name;

  nativeBuildInputs = [
    makeWrapper
    rsync
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    ${rsync}/bin/rsync -a --exclude='bin/' ${uvEnv}/ $out
    find $out/${site} -type d -exec chmod u+w '{}' +

    copy_source_dir() {
      local src_path="$1"
      local name
      name="$(basename "$src_path")"
      rm -rf "$out/${site}/$name"
      cp -r "$src_path" "$out/${site}/$name"
      find "$out/${site}/$name" -type d -exec chmod u+w '{}' +
    }

    for packagePath in ${src}/*; do
      if [ -d "$packagePath" ] && [ -e "$packagePath/__init__.py" ]; then
        copy_source_dir "$packagePath"
      fi
    done

    for modulePath in ${src}/*.py; do
      moduleName="$(basename "$modulePath")"
      rm -f "$out/${site}/$moduleName"
      install -Dm644 "$modulePath" "$out/${site}/$moduleName"
    done

    for dataDir in ${lib.escapeShellArgs hermesDataDirs}; do
      if [ -d "${src}/$dataDir" ]; then
        copy_source_dir "${src}/$dataDir"
      fi
    done

    for supportFile in ${lib.escapeShellArgs hermesSupportFiles}; do
      if [ -f "${src}/$supportFile" ]; then
        rm -f "$out/${site}/$supportFile"
        install -Dm644 "${src}/$supportFile" "$out/${site}/$supportFile"
      fi
    done

    chmod u+w $out/${site}/tools/terminal_tool.py
    chmod u+w "$out/${site}/plugins/platforms/discord/adapter.py"
    substituteInPlace "$out/${site}/plugins/platforms/discord/adapter.py" \
      --replace-fail \
      '    opus_path = ctypes.util.find_library("opus")' \
      '    opus_path = os.environ.get("HERMES_OPUS_LIBRARY") or ctypes.util.find_library("opus")'
    printf '%s\n' ${lib.escapeShellArg installStamp} > "$out/${site}/install-stamp.json"
    cp ${uvEnv}/bin/hermes $out/bin/hermes
    cp ${uvEnv}/bin/hermes-agent $out/bin/hermes-agent
    wrapProgram $out/bin/hermes \
      --prefix PATH : ${runtimePath} \
      --prefix LD_LIBRARY_PATH : ${runtimeLibraryPath} \
      --set-default HERMES_OPUS_LIBRARY ${opusLibPath} \
      --prefix PYTHONPATH : $out/${site}
    wrapProgram $out/bin/hermes-agent \
      --prefix PATH : ${runtimePath} \
      --prefix LD_LIBRARY_PATH : ${runtimeLibraryPath} \
      --set-default HERMES_OPUS_LIBRARY ${opusLibPath} \
      --prefix PYTHONPATH : $out/${site}
    runHook postInstall
  '';

  meta = {
    changelog = "https://github.com/NousResearch/hermes-agent/releases/tag/v${version}";
    description = "A self-improving AI agent CLI";
    homepage = "https://github.com/NousResearch/hermes-agent";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "hermes";
  };
}
