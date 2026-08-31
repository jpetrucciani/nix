# [hermes-agent](https://github.com/NousResearch/hermes-agent) is a self-improving AI agent CLI
{ stdenv
, lib
, python311
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
  version = "2026.8.31";

  src = uv-nix.fetchGitHubWorkspace {
    owner = "NousResearch";
    repo = name;
    rev = "refs/tags/v${version}";
    hash = "0mvjvlbvq3cmwbsr2lgnhbw9jw43fh9bp685fg19nlnacwzp2br2";
  };

  uvEnv = uv-nix.mkEnv {
    inherit name;
    gitignore = false;
    python = python311;
    workspaceRoot = src;
    pyprojectOverrides =
      final: prev:
      let
        addBuildInputs = buildInputs: pkg: pkg.overrideAttrs (old: {
          buildInputs = (old.buildInputs or [ ]) ++ buildInputs;
        });
        hatchBuildInputs = with final; [
          hatchling
          packaging
          pathspec
          pluggy
          trove-classifiers
        ];
      in
      {
        atroposlib = addBuildInputs hatchBuildInputs prev.atroposlib;
        "hermes-agent" = prev."hermes-agent".overrideAttrs (_: {
          HERMES_NIX_BUILD = "1";
        });
        "sherpa-onnx" =
          if stdenv.hostPlatform.isLinux then
            prev."sherpa-onnx".overrideAttrs
              (old: {
                buildInputs = (old.buildInputs or [ ]) ++ [ final.onnxruntime ];
                preFixup = (old.preFixup or "") + ''
                  mkdir -p "$out/lib"
                  ln -s \
                    ${final.onnxruntime}/${python311.sitePackages}/onnxruntime/capi/libonnxruntime.so.${final.onnxruntime.version} \
                    "$out/lib/libonnxruntime.so"
                  addAutoPatchelfSearchPath "$out/lib"
                '';
              })
          else
            prev."sherpa-onnx";
        tinker = addBuildInputs
          (hatchBuildInputs ++ [
            final."hatch-fancy-pypi-readme"
          ])
          prev.tinker;
        "yc-bench" = addBuildInputs hatchBuildInputs prev."yc-bench";
      };
  };

  hermesDataDirs = [
    "skills"
    "optional-skills"
  ];

  hermesSupportFiles = [
    ".env.example"
    "cli-config.yaml.example"
  ];

  site = python311.sitePackages;
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
    if [ -f "$out/${site}/gateway/platforms/discord.py" ]; then
      chmod u+w "$out/${site}/gateway/platforms/discord.py"
      substituteInPlace "$out/${site}/gateway/platforms/discord.py" \
        --replace-fail \
        '            opus_path = ctypes.util.find_library("opus")' \
        '            opus_path = os.environ.get("HERMES_OPUS_LIBRARY") or ctypes.util.find_library("opus")'
    elif [ -f "$out/${site}/plugins/platforms/discord/adapter.py" ]; then
      chmod u+w "$out/${site}/plugins/platforms/discord/adapter.py"
      substituteInPlace "$out/${site}/plugins/platforms/discord/adapter.py" \
        --replace-fail \
        '            opus_path = ctypes.util.find_library("opus")' \
        '            opus_path = os.environ.get("HERMES_OPUS_LIBRARY") or ctypes.util.find_library("opus")'
    fi
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
