# [H2O-Lightning-4B](https://huggingface.co/h2oai/h2o-lightning-4b) serves Jev-compatible typed decisions over vLLM.
{ h2o-lightning-4b
, lib
, fetchurl
, pog
, python313
, vllm
, isWSL ? false
}:
let
  version = "1.2.1";
  modelId = "h2oai/h2o-lightning-4b";
  modelRev = "542e9eff5ce7e5d69eb457fbe54abb535992ab20";
  sourceUrl = "https://huggingface.co/${modelId}/resolve/${modelRev}";
  shimSource = fetchurl {
    name = "h2o_lightning_shim.py";
    url = "${sourceUrl}/h2o_lightning_shim.py";
    hash = "sha256-0X83mJp5uKEPG48VAFbQ9iJvA4YK1hjHD2iGOkdHJTk=";
  };
  serveConfig = fetchurl {
    name = "serve_config.json";
    url = "${sourceUrl}/serve_config.json";
    hash = "sha256-pCP9a5czNL1OyR0MGu6LG9lN8dfsSezADDxPxO6Oqig=";
  };
  licenseSource = fetchurl {
    name = "h2o-lightning-4b-LICENSE";
    url = "${sourceUrl}/LICENSE";
    hash = "sha256-u+3D/aMwWCC5dyZfAbhhnYdXCmc53jpVgsNGSEDx5Xo=";
  };
  vllmPackage = if isWSL then vllm.wsl else vllm;
in
(pog {
  inherit version;
  name = "h2o-lightning-4b";
  description = "serve H2O-Lightning-4B through the Jev decision API at /v1/systemone; pass extra vLLM arguments after --";
  strict = true;
  showDefaultFlags = true;
  flagPadding = 32;
  flags = map (flag: flag // { flagPadding = 32; }) [
    {
      name = "host";
      short = "";
      envVar = "SHIM_HOST";
      default = "127.0.0.1";
      description = "decision API bind address";
    }
    {
      name = "port";
      short = "";
      envVar = "SHIM_PORT";
      default = "8741";
      description = "decision API port";
    }
    {
      name = "vllm-port";
      short = "";
      envVar = "VLLM_PORT";
      default = "8000";
      description = "private vLLM backend port";
    }
    {
      name = "vllm-url";
      short = "";
      envVar = "SHIM_VLLM";
      description = "run only the shim against an existing vLLM backend";
    }
    {
      name = "model";
      short = "";
      envVar = "MODEL";
      default = modelId;
      description = "Hugging Face model ID or local model directory";
    }
    {
      name = "revision";
      short = "";
      envVar = "MODEL_REVISION";
      default = modelRev;
      description = "model revision, pinned to the shim and config by default";
    }
    {
      name = "max-model-len";
      short = "";
      envVar = "MAX_LEN";
      default = "40960";
      description = "vLLM context limit";
    }
    {
      name = "gpu-memory-utilization";
      short = "";
      envVar = "GPU_UTIL";
      default = "0.90";
      description = "fraction of GPU memory reserved by vLLM";
    }
    {
      name = "config";
      short = "";
      envVar = "SHIM_CONFIG";
      default = toString serveConfig;
      description = "decision prompt and calibration config";
    }
  ];
  beforeExit = ''
    if [[ -n "''${shim_pid:-}" ]]; then
      kill "$shim_pid" 2>/dev/null || true
      wait "$shim_pid" 2>/dev/null || true
    fi
    if [[ -n "''${vllm_pid:-}" ]]; then
      kill "$vllm_pid" 2>/dev/null || true
      wait "$vllm_pid" 2>/dev/null || true
    fi
  '';
  script = ''
    vllm_pid=""
    shim_pid=""
    shim_args=(--config "$config" --model ${lib.escapeShellArg modelId} --host "$host" --port "$port")
    if [[ -n "$vllm_url" ]]; then
      if (( $# > 0 )); then
        echo "extra vLLM arguments cannot be used with --vllm-url" >&2
        exit 1
      fi
      exec ${python313}/bin/python3 ${shimSource} "''${shim_args[@]}" --vllm "$vllm_url"
    fi

    # Decisions read log-probabilities without sampling, matching upstream serve.sh.
    export VLLM_USE_FLASHINFER_SAMPLER="''${VLLM_USE_FLASHINFER_SAMPLER:-0}"
    ${lib.getExe vllmPackage} serve "$model" \
      --revision "$revision" \
      --served-model-name ${lib.escapeShellArg modelId} \
      --host 127.0.0.1 --port "$vllm_port" \
      --max-model-len "$max_model_len" \
      --gpu-memory-utilization "$gpu_memory_utilization" \
      --limit-mm-per-prompt '{"image": 4, "video": 0}' \
      --mm-processor-kwargs '{"max_pixels": 1605632}' \
      "$@" &
    vllm_pid=$!
    ${python313}/bin/python3 ${shimSource} "''${shim_args[@]}" --vllm "http://127.0.0.1:$vllm_port" &
    shim_pid=$!

    # If either service stops, stop the other and propagate failures to the caller.
    status=0
    wait -n -p exited_pid "$vllm_pid" "$shim_pid" || status=$?
    if [[ "''${exited_pid:-}" == "$vllm_pid" ]]; then
      vllm_pid=""
      echo "vLLM exited" >&2
    elif [[ "''${exited_pid:-}" == "$shim_pid" ]]; then
      shim_pid=""
      echo "decision shim exited" >&2
    fi
    if (( status == 0 )); then
      status=1
    fi
    exit "$status"
  '';
}).overrideAttrs (old: {
  installPhase = old.installPhase + ''
    install -Dm644 ${licenseSource} "$out/share/licenses/h2o-lightning-4b/LICENSE"
  '';
  passthru = old.passthru // {
    inherit modelId modelRev shimSource serveConfig;
    wsl = h2o-lightning-4b.override { isWSL = true; };
  };
  meta = old.meta // {
    homepage = "https://huggingface.co/${modelId}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    skipBuild = true; # The vLLM dependency is too heavy for GitHub Actions.
  };
})
