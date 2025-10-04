# This overlay is where I create wrappers around other tools to simplify using some of the attempts to simplify python tooling via nix
final: prev:
let
  inherit (final.lib) listToAttrs;
  inherit (final.lib.lists) remove;

  poetry-helpers = rec {
    add_propagated = pkg: propagated: pkg.overridePythonAttrs (old: {
      propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ propagated;
    });
    remove_propagated = pkg: _remove: pkg.overridePythonAttrs (old: {
      propagatedBuildInputs = remove _remove (old.propagatedBuildInputs or [ ]);
    });
    no_wheel = pkg: pkg.override { preferWheel = false; };
    no_check = pkg: pkg.overridePythonAttrs (_: { doCheck = false; });
    mkEnv =
      { projectDir
      , extraOverrides ? [ ]
      , extraPreOverrides ? [ ]
      , extraPostOverrides ? extraOverrides
      , extraBuildInputs ? [ ]
      , editablePackageSources ? { }
      , extraMkPoetryEnv ? { }
      , python ? final.python312
      , ignoreCollisions ? true
      , preferWheels ? true
      }:
      let
        p2nix = final.poetry2nix;
        extraFixes = final: prev:
          let
            add_setuptools = pkg: add_propagated pkg [ final.setuptools ];
          in
          # some default fixes for things i've seen
          {
            # import from nixpkgs
            inherit (python.pkgs) pymupdf markupsafe;

            # do not pull wheels!
            bcrypt = no_wheel prev.bcrypt;
            contourpy = no_wheel prev.contourpy;
            jsonschema = no_wheel prev.jsonschema;
            jsonschema-specifications = no_wheel prev.jsonschema-specifications;
            jupyterlab-pygments = no_wheel prev.jupyterlab-pygments;
            markdown-it-py = no_wheel prev.markdown-it-py;
            msgpack = no_wheel prev.msgpack;
            nbconvert = no_wheel prev.nbconvert;
            numba = no_wheel prev.numba;
            orjson = no_wheel prev.orjson;
            pytesseract = no_wheel prev.pytesseract;
            referencing = no_wheel prev.referencing;
            reportlab = no_wheel prev.reportlab;
            rpds-py = no_wheel prev.rpds-py;
            scikit-learn = no_wheel prev.scikit-learn;
            scipy = no_wheel prev.scipy;
            watchfiles = no_wheel prev.watchfiles;

            # requires setuptools
            py-lets-be-rational = add_setuptools prev.py-lets-be-rational;
            pypika = add_setuptools prev.pypika;
            swifter = add_setuptools prev.swifter;
            wikipedia = add_setuptools prev.wikipedia;
            xalglib = add_setuptools prev.xalglib;

            # other required propagations
            jupyterlab-miami-nights = add_propagated prev.jupyterlab-miami-nights [ prev.jupyter-packaging ];
          };
      in
      ((p2nix.mkPoetryEnv
        {
          inherit editablePackageSources python projectDir preferWheels;
          overrides = extraPreOverrides ++ (p2nix.overrides.withDefaults extraFixes) ++ extraPostOverrides;
        } // extraMkPoetryEnv).override
        (args: {
          inherit ignoreCollisions;
        })).overrideAttrs
        (old: {
          buildInputs = with final; [
            libcxx
          ] ++ extraBuildInputs;
        });
  };

  uv-nix = {
    overrideHelpers = { pkgs, final, prev }: rec {
      hacks = pkgs.callPackage pkgs.pyproject-nix.build.hacks { };
      add_buildinputs = build_inputs: pkg: pkg.overrideAttrs (old: { buildInputs = (old.buildInputs or [ ]) ++ build_inputs; });
      add_setuptools = add_buildinputs [ final.setuptools ];

      # this is a hack to filter out nvidia deps for torch! it takes in a base package, like pkgs.python311Packages.torchWithoutCuda
      torchHack = { from ? pkgs.python311Packages.torchWithoutCuda }: hacks.nixpkgsPrebuilt {
        inherit from;
        prev = prev.torch.overrideAttrs (old: {
          passthru = old.passthru // {
            dependencies = pkgs.lib.filterAttrs (name: _: ! pkgs.lib.hasPrefix "nvidia" name) old.passthru.dependencies;
          };
        });
      };
    };
    mkEnv =
      { name
      , workspaceRoot
      , envName ? "${name}-env"
      , python ? final.python313
      , sourcePreference ? "wheel"
      , pyprojectOverrides ? null
      , darwinSdkVersion ? "15.1"
      , venvIgnoreCollisions ? [ "*" ]
      , extraSetuptools ? [ ]
      , gitignore ? true
      , enableCuda ? false
      , _pkgs ? final
      }@args:
      let
        hacks = final.callPackage final.pyproject-nix.build.hacks { };
        cudaOverrides = _final: _prev: {
          bitsandbytes = _prev.bitsandbytes.overrideAttrs (_: {
            buildInputs = with _pkgs.cudaPackages; [
              cuda_cudart
              libcublas
              libcusparse
            ];
            postFixup = ''
              addAutoPatchelfSearchPath "${_final.nvidia-cusparselt-cu12}"
            '';
            autoPatchelfIgnoreMissingDeps = [
              "libcudart.so.11.0"
              "libcublas.so.11"
              "libcublasLt.so.11"
              "libcusparse.so.11"
            ];
          });
          nvidia-cusolver-cu12 = _prev.nvidia-cusolver-cu12.overrideAttrs (_: {
            buildInputs = [ _pkgs.cudatoolkit _pkgs.cudaPackages.libnvjitlink ];
          });
          nvidia-cusparse-cu12 = _prev.nvidia-cusparse-cu12.overrideAttrs (_: {
            buildInputs = [ _pkgs.cudaPackages.libnvjitlink ];
          });
          nvidia-nvshmem-cu12 = _prev.nvidia-nvshmem-cu12.overrideAttrs (_: {
            buildInputs = [ _pkgs.mpi ];
            autoPatchelfIgnoreMissingDeps = [
              "libmlx5.so.1"
            ];
          });
          nvidia-cufile-cu12 = _prev.nvidia-cufile-cu12.overrideAttrs (_: {
            autoPatchelfIgnoreMissingDeps = [
              "libmlx5.so.1"
              "librdmacm.so.1"
              "libibverbs.so.1"
            ];
          });
          infinistore = _prev.infinistore.overrideAttrs (_: {
            autoPatchelfIgnoreMissingDeps = [
              "libibverbs.so.1"
            ];
          });
          cupy-cuda12x = _prev.cupy-cuda12x.overrideAttrs (_: {
            buildInputs = with _pkgs.cudaPackages; [
              cuda_nvrtc
              cudnn_8_9
              cutensor
              libcufft
              libcurand
              libcusolver
              libcusparse
              nccl
            ];
            postFixup = ''
              addAutoPatchelfSearchPath "${_final.nvidia-cusparselt-cu12}"
            '';
          });
          xformers = _prev.xformers.overrideAttrs (_: {
            postFixup = ''
              addAutoPatchelfSearchPath "${_final.torch}"
            '';
          });
          flashinfer-python = _prev.flashinfer-python.overrideAttrs (_: {
            buildInputs = (with _final; [ torch setuptools ]) ++ (with _pkgs.cudaPackages; [
              cuda_nvcc
            ]);
          });
          lmcache = _prev.lmcache.overrideAttrs (_: {
            postFixup = ''
              addAutoPatchelfSearchPath "${_final.torch}"
            '';
          });
          vllm = _prev.vllm.overrideAttrs (_: {
            postFixup = ''
              addAutoPatchelfSearchPath "${_final.torch}"
            '';
          });
          sentencepiece = hacks.nixpkgsPrebuilt { from = python.pkgs.sentencepiece; };
          fastdeploy-gpu = _prev.fastdeploy-gpu.overrideAttrs (_: {
            buildInputs = with _pkgs.cudaPackages; [
              cuda_cudart
              libcublas
            ];
            autoPatchelfIgnoreMissingDeps = [ "libibverbs.so.1" ];
            postFixup = ''
              addAutoPatchelfSearchPath "${_final.paddlepaddle-gpu}"
              substituteInPlace $out/lib/python*/site-packages/fastdeploy/__init__.py --replace "ImportError" "Exception"
            '';
          });
          paddlepaddle-gpu = _prev.paddlepaddle-gpu.overrideAttrs (_: {
            autoPatchelfIgnoreMissingDeps = [ "libmlx5.so.1" ];
            postInstall = ''
              sed -i -E 's#(input_rank = len\(x\.shape\))#\1\n    if input_rank == 1:\n        x = x.unsqueeze(0)\n        input_rank += 1#g' $out/lib/python*/site-packages/paddle/incubate/nn/functional/fused_rms_norm.py
            '';
            buildInputs = with _pkgs.cudaPackages; [
              _final.setuptools
              cuda_nvrtc
              cudnn
              cuda_cudart
              libcublas
              cutensor
              cuda_nvtx
              libcufft
              libcurand
              libcusolver
              libcusparse
              nccl
            ];
          });
          flash-attn = _prev.flash-attn.overrideAttrs {
            postFixup = ''
              addAutoPatchelfSearchPath "${_final.torch}"
            '';
          };
          exllamav2 = _prev.exllamav2.overrideAttrs (old: {
            CUDA_HOME = _pkgs.cudatoolkit;
            TORCH_CUDA_ARCH_LIST = "8.0 8.6+PTX";
            buildInputs = (old.buildInputs or [ ]) ++ (with _final; [ setuptools torch ]);
          });
          torch =
            let
              baseInputs = (python.pkgs.torch.override { cudaSupport = true; }).buildInputs;
            in
            _prev.torch.overrideAttrs (_: {
              buildInputs = baseInputs ++ (with _pkgs.cudaPackages; [ libcufile ]);
              postFixup = ''
                addAutoPatchelfSearchPath "${_final.nvidia-cusparselt-cu12}"
              '';
            });
          torchaudio =
            let
              FFMPEG_ROOT = final.symlinkJoin {
                name = "ffmpeg";
                paths = with final; [
                  ffmpeg_6-full.bin
                  ffmpeg_6-full.dev
                  ffmpeg_6-full.lib
                ];
              };
            in
            _prev.torchaudio.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [ final.sox ];
              inherit FFMPEG_ROOT;
              autoPatchelfIgnoreMissingDeps = true;
              postFixup = ''
                addAutoPatchelfSearchPath "${_final.torch}/${python.sitePackages}/torch/lib"
              '';
            });
          torchvision = _prev.torchvision.overrideAttrs (_: {
            postFixup = ''
              addAutoPatchelfSearchPath "${_final.torch}/${python.sitePackages}/torch/lib"
            '';
          });
          triton = _prev.triton.overrideAttrs (_: {
            postInstall = ''
              sed -i -E 's#minor == 6#minor >= 6#g' $out/${python.sitePackages}/triton/backends/nvidia/compiler.py
            '';
          });
        };
        gitignoreRecursiveSource = final.nix-gitignore.gitignoreFilterSourcePure (_: _: true) [ ];
        workspace = final.uv2nix.lib.workspace.loadWorkspace { workspaceRoot = if gitignore then gitignoreRecursiveSource workspaceRoot else workspaceRoot; };
        overlay = workspace.mkPyprojectOverlay {
          # Prefer prebuilt binary wheels as a package source.
          # Sdists are less likely to "just work" because of the metadata missing from uv.lock.
          # Binary wheels are more likely to, but may still require overrides for library dependencies.
          inherit sourcePreference; # or sourcePreference = "sdist";
          # Optionally customise PEP 508 environment
          # environ = {
          #   platform_release = "5.10.65";
          # };
        };
        _pyprojectOverrides = _final: _prev:
          let
            add_buildinputs = build_inputs: pkg: pkg.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ build_inputs;
            });
            add_setuptools = add_buildinputs [ _final.setuptools ];
            _setuptools_required = [
              "aiohttp"
              "antlr4-python3-runtime"
              "crcmod"
              "curated-tokenizers"
              "distance"
              "docx2txt"
              "encodec"
              "etcd3"
              "filterpy"
              "flashinfer-python"
              "gensim"
              "html2text"
              "jieba"
              "jsonpath-rw"
              "markupsafe"
              "multitasking"
              "peewee"
              "py-lets-be-rational"
              "py-vollib"
              "pyautogui"
              "pymongo"
              "pypika"
              "pyyaml"
              "s3tokenizer"
              "scapy"
              "seqeval"
              "svglib"
              "swifter"
              "wikipedia"
              "xalglib"
              "zmq"
            ] ++ extraSetuptools;
            setuptools_required = listToAttrs (map (x: { name = x; value = add_setuptools _prev.${x}; }) _setuptools_required);
          in
          {
            # Implement standard build fixups here.
            # Note that uv2nix is _not_ using Nixpkgs buildPythonPackage.
            # It's using https://pyproject-nix.github.io/pyproject.nix/build.html
            numba = add_buildinputs (with final; [ tbb_2022 ]) _prev.numba;
            psycopg2 = add_setuptools (_prev.psycopg2.overrideAttrs (_: {
              buildInputs = [ final.postgresql ] ++ final.lib.optionals final.stdenv.hostPlatform.isDarwin [ final.openssl ];
              postPatch = ''
                substituteInPlace setup.py \
                  --replace-fail "self.pg_config_exe = self.build_ext.pg_config" 'self.pg_config_exe = "${final.libpq.pg_config}/bin/pg_config"'
              '';
            }));
            soundfile = _prev.soundfile.overrideAttrs (_: {
              postInstall = ''
                substituteInPlace $out/lib/python*/site-packages/soundfile.py --replace "_find_library('sndfile')" "'${final.libsndfile.out}/lib/libsndfile${final.stdenv.hostPlatform.extensions.sharedLibrary}'"
              '';
            });
          } // setuptools_required;

        pythonSet =
          # Use base package set from pyproject.nix builders
          (final.callPackage final.pyproject-nix.build.packages {
            inherit python;
            stdenv = final.stdenv.override {
              targetPlatform = final.stdenv.targetPlatform // (if final.stdenv.isDarwin then {
                # Sets MacOS SDK version to 15.1 which implies Darwin version 24.
                # See https://en.wikipedia.org/wiki/MacOS_version_history#Releases for more background on version numbers.
                inherit darwinSdkVersion;
              } else { });
            };
          }).overrideScope
            (
              final.lib.composeManyExtensions ([
                final.pyproject-build-systems.overlays.default
                overlay
                _pyprojectOverrides
              ] ++
              (if enableCuda then [ cudaOverrides ] else [ ])
              ++ (if pyprojectOverrides != null then [
                pyprojectOverrides
              ] else [ ]))
            );

        virtualenv = (pythonSet.mkVirtualEnv envName workspace.deps.all).overrideAttrs (_: { inherit venvIgnoreCollisions; });
      in
      virtualenv // rec {
        uvEnvVars = {
          UV_NO_MANAGED_PYTHON = "true";
          UV_NO_SYNC = "1";
          UV_PYTHON = python.interpreter;
          UV_PYTHON_DOWNLOADS = "never";
          UV_SYSTEM_PYTHON = "true";
          _UV_SITE = "${virtualenv}/lib/python${python.pythonVersion}/site-packages";
        };
        internal = {
          inherit args;
          libpython = final.runCommand "libpython" { } ''
            mkdir -p $out/lib
            cp -L ${python}/lib/*.so $out/lib/
          '';
        };
        wrappers =
          let
            wrap = { name, bin ? name }: final.writers.writeBashBin name ''
              ${virtualenv}/bin/${bin} "$@"
            '';
            _base = [
              "black"
              "pytest"
              "ruff"
              "ty"
            ];
          in
          {
            shell_hook = ''
              ln -sf ${uvEnvVars._UV_SITE} .direnv/site
            '';
            repo = "$(${final.git}/bin/git rev-parse --show-toplevel)";
          } // (final.lib.listToAttrs (map (x: { name = x; value = final.lib.setPrio (-8) (wrap { name = x; }); }) _base));
      };

    buildUvPackage =
      { pname
      , bins ? [ pname ]
      , version
      , python ? final.python313
      , lockFile ? null
      , lockUrl ? null
      , lockHash ? null
      , pyprojectOverrides ? null
      , extraDependencies ? [ ]
      , cudaSupport ? final.config.cudaSupport
      , ...
      }@args:
      let
        attrs = removeAttrs args [ "lockUrl" "lockHash" "extraDependencies" ];
      in
      assert (lockFile != null || (lockUrl != null && lockHash != null)) || throw "you must specify either a 'lockFile' or a 'lockUrl' and 'lockHash'!";
      final.stdenv.mkDerivation (finalAttrs: attrs // {
        inherit pname version;
        dontUnpack = true;
        workspaceRoot = final.runCommand "${pname}-uv-nix"
          {
            pyprojectTOML = final.writers.writeTOML "${pname}-pyproject.toml" {
              project = {
                name = pname;
                inherit version;
                description = "${finalAttrs.pname} package in uv2nix";
                dependencies = [ "${pname}==${version}" ] ++ extraDependencies;
              };
            };
            uvLock = if lockUrl != null then (final.fetchurl { url = lockUrl; hash = lockHash; }) else lockFile;
          }
          ''
            mkdir -p $out
            cp $pyprojectTOML $out/pyproject.toml
            cp $uvLock $out/uv.lock
          '';
        uvEnv = uv-nix.mkEnv {
          inherit python pyprojectOverrides;
          name = finalAttrs.pname;
          enableCuda = cudaSupport;
          inherit (finalAttrs) workspaceRoot;
        };
        nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ [ final.rsync final.makeWrapper ];
        installPhase =
          let
            copyBins = final.lib.concatStringsSep "\n" (map (x: "cp $uvEnv/bin/${x} $out/bin/${x}") bins);
          in
          ''
            runHook preInstall
            mkdir -p $out/bin
            rsync -a --exclude='bin/' $uvEnv/ $out
            ${copyBins}
            runHook postInstall
          '';
      });
  };
in
{
  inherit poetry-helpers uv-nix;
  poetry-nix = poetry-helpers; # i'd like to rename this permanently?
}
