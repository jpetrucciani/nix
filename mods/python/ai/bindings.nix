final: prev: with prev; let
  inherit (stdenv) isAarch64 isDarwin;
  inherit (prev.pkgs) darwin;
  isM1 = isDarwin && isAarch64;
in
rec {
  llama-cpp-python =
    let
      inherit (lib) optionals;
      osSpecific =
        if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate MetalKit MetalPerformanceShaders MetalPerformanceShadersGraph ]
        else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
        else [ ];
      llama-cpp-pin = pkgs.fetchFromGitHub {
        owner = "ggerganov";
        repo = "llama.cpp";
        rev = "232caf3c1581a6cb023571780ff41dc2d66d1ca0";
        hash = "sha256-EEGaNqGsjY+6U2i5eEc9BC8XmntRFqgd5Be9/4N4PIs=";
      };
    in
    buildPythonPackage rec {
      pname = "llama-cpp-python";
      version = "0.1.79";
      format = "pyproject";
      src = pkgs.fetchFromGitHub {
        owner = "abetlen";
        repo = pname;
        rev = "refs/tags/v${version}";
        hash = "sha256-5SFrUXmjeUN2Py0kfZo1lW01zZBI0LGAvTg/WeGlIA0=";
      };

      cuda = false;

      _CMAKE_ARGS = [ ] ++ (optionals isM1 [ "-DLLAMA_METAL=on" ]) ++ (optionals cuda [ "-DLLAMA_CUBLAS=on" ]);
      CMAKE_ARGS = builtins.concatStringsSep " " _CMAKE_ARGS;
      FORCE_CMAKE = if (isM1 || cuda) then "1" else null;

      preConfigure = ''
        cp -r ${llama-cpp-pin}/. ./vendor/llama.cpp
        chmod -R +w ./vendor/llama.cpp
      '';
      preBuild = ''
        cd ..
      '';
      buildInputs = osSpecific;

      nativeBuildInputs = [
        pythonRelaxDepsHook
        prev.pkgs.cmake
        prev.pkgs.ninja
        poetry-core
        scikit-build
        setuptools
      ] ++ (optionals cuda [ pkgs.cudatoolkit ]);
      pythonRelaxDeps = [ "diskcache" ];
      propagatedBuildInputs = [
        diskcache
        numpy
        typing-extensions

        # server mode
        fastapi
        sse-starlette
        uvicorn
      ];

      pythonImportsCheck = [ "llama_cpp" ];

      passthru.cuda = llama-cpp-python.overridePythonAttrs (old: {
        CMAKE_ARGS = "-DLLAMA_CUBLAS=on";
        FORCE_CMAKE = 1;
        nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.cudatoolkit ];
      });

      meta = with lib; {
        description = "A Python wrapper for llama.cpp";
        homepage = "https://github.com/abetlen/llama-cpp-python";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  ggml-python =
    let
      osSpecific =
        if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate MetalKit MetalPerformanceShaders MetalPerformanceShadersGraph ]
        else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
        else [ ];
    in
    buildPythonPackage rec {
      pname = "ggml-python";
      version = "0.0.1";

      format = "pyproject";
      src = pkgs.fetchFromGitHub {
        owner = "abetlen";
        repo = pname;
        rev = "c4cb698cd2068addafe0b2b4fd3c63b49061f5c8";
        # rev = "refs/tags/v${version}";
        hash = "sha256-jMjkJYXUGA0PL0FoZOXpeHScVS0s2i0izhQbPk4iJsA=";
        fetchSubmodules = true;
      };

      CMAKE_ARGS = if isM1 then "-DLLAMA_METAL=on" else null;
      FORCE_CMAKE = if isM1 then "1" else null;

      # let's remove this - we propagate it below
      postPatch = ''
        sed -i -E '/typing_extensions/d' ./pyproject.toml
      '';
      preBuild = ''
        cd ..
      '';
      buildInputs = osSpecific;

      nativeBuildInputs = [
        prev.pkgs.cmake
        prev.pkgs.ninja
        pathspec
        poetry-core
        pyproject-metadata
        scikit-build
        scikit-build-core
        setuptools
      ];
      propagatedBuildInputs = [
        numpy
        typing-extensions

        # server mode
        fastapi
        sse-starlette
        uvicorn
      ];

      pythonImportsCheck = [ "ggml" ];

      meta = with lib; {
        description = "Python bindings for ggml";
        homepage = "https://github.com/abetlen/ggml-python";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };
  pyllamacpp =
    let
      osSpecific =
        if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate ]
        else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
        else [ ];
    in
    buildPythonPackage rec {
      pname = "pyllamacpp";
      version = "2.4.1";
      format = "pyproject";

      src = pkgs.fetchFromGitHub {
        owner = "abdeladim-s";
        repo = pname;
        rev = "refs/tags/v${version}";
        hash = "sha256-b7QMDD0OrSUtEzMX1lMPt7h2oqrLKwfWGxgjAI2LnMM=";
        fetchSubmodules = true;
      };
      buildInputs = osSpecific;
      nativeBuildInputs = [
        pkgs.cmake
        pkgs.ninja
        setuptools
        wheel
      ];

      pythonImportsCheck = [ "pyllamacpp" ];
      dontUseCmakeConfigure = true;

      meta = with lib; {
        description = "Python bindings for llama.cpp";
        homepage = "https://github.com/abdeladim-s/pyllamacpp";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  pygptj =
    let
      osSpecific =
        if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate ]
        else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
        else [ ];
    in
    buildPythonPackage rec {
      pname = "pygptj";
      version = "2.0.3";
      format = "pyproject";

      src = pkgs.fetchFromGitHub {
        owner = "abdeladim-s";
        repo = pname;
        rev = "refs/tags/v${version}";
        hash = "sha256-Ub7qXARiOIpT4UaI9mACtrRUiPbIQgABUias3TNDqP0=";
        fetchSubmodules = true;
      };

      buildInputs = osSpecific;
      nativeBuildInputs = [
        pkgs.cmake
        pkgs.ninja
        setuptools
        wheel
      ];

      dontUseCmakeConfigure = true;

      propagatedBuildInputs = [
        numpy
      ];

      pythonImportsCheck = [ "pygptj" ];

      meta = with lib; {
        description = "Python bindings for the GGML GPT-J Laguage model";
        homepage = "https://github.com/abdeladim-s/pygptj";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  pygpt4all = buildPythonPackage rec {
    pname = "pygpt4all";
    version = "1.1.0";
    format = "setuptools";

    src = pkgs.fetchFromGitHub {
      owner = "nomic-ai";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-4/AogNqSv2bBugkXj4T5G6xgr2tubZNkBpUu/CUDYko=";
    };

    pythonImportsCheck = [ "pygpt4all" ];
    propagatedBuildInputs = [
      pyllamacpp
      pygptj
    ];

    meta = with lib; {
      description = "Official Python CPU inference for GPT4All language models based on llama.cpp and ggml";
      homepage = "https://github.com/nomic-ai/pygpt4all";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
  rwkv-cpp =
    let
      osSpecific =
        if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate ]
        else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
        else [ ];
      version = "0.0.1";
      libFile = if isDarwin then "librwkv.dylib" else "librwkv.so";
      setup-py = pkgs.writeTextFile {
        name = "setup.py";
        text = ''
          from setuptools import setup
          setup(
            name="rwkv_cpp",
            version="${version}",
            author="",
            author_email="",
            packages=["."],
            package_data={"":["${libFile}"]},
            setup_requires=["numpy", "torch", "tokenizers"],
            install_requires=[],
          )
        '';
      };
    in
    buildPythonPackage {
      inherit version;
      pname = "rwkv-cpp";
      format = "pyproject";
      src = pkgs.fetchFromGitHub {
        owner = "saharNooby";
        repo = "rwkv.cpp";
        rev = "1c363e6d5f4ec7817ceffeeb17bd972b1ce9d9d0";
        hash = "sha256-IU+3MwIY3NnJPYtxrgpphLOnHAOQAKYd+8BV1tusgC4=";
        fetchSubmodules = true;
      };
      preBuild = ''
        cd ..
        cp ./rwkv/rwkv_cpp_model.py .
        cp ./rwkv/rwkv_cpp_shared_library.py .
        cp ${setup-py} ./setup.py
        mkdir -p ./bin/Release
        cmake .
        cmake --build . --config Release
        sed -i -E "s#(paths = \[)#\1'$out/${prev.python.sitePackages}/${libFile}',#g" ./rwkv_cpp_shared_library.py
      '';
      buildInputs = osSpecific;

      nativeBuildInputs = [
        prev.pkgs.cmake
        prev.pkgs.ninja
        poetry-core
        scikit-build
        setuptools
      ];

      propagatedBuildInputs = [
        numpy
        tokenizers
        torch
        typing-extensions
      ];

      pythonImportsCheck = [
        "rwkv_cpp_model"
        "rwkv_cpp_shared_library"
      ];

      meta = with lib; {
        description = "";
        homepage = "https://github.com/saharNooby/rwkv.cpp";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };



  whisper-cpp-python =
    let
      name = "whisper-cpp-python";
      version = "0.2.0";
      osSpecific =
        if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate ]
        else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
        else [ ];
    in
    buildPythonPackage {
      inherit version;
      pname = name;
      format = "pyproject";

      src = pkgs.fetchFromGitHub {
        owner = "carloscdias";
        repo = name;
        rev = "0744238e10f6b1da3440d43aa3dff43d46b09b30";
        hash = "sha256-Nj35UwCLD88SF26rqrNiLo1lUQTHAKUVKyMyaA0Cy7Q=";
        fetchSubmodules = true;
      };

      postPatch = let sed = "sed -i -E"; in
        if stdenv.isDarwin then ''
          ${sed} 's#(_lib_base_name = )"whisper"#\1"libwhisper"#g' ./setup.py
          ${sed} 's#(lib_ext = )".so"#\1".dylib"#g' ./setup.py
        ''
        else "";
      preBuild = ''
        cd ..
      '';
      buildInputs = osSpecific;

      pythonRelaxDeps = [ "librosa" ];
      nativeBuildInputs = [
        pythonRelaxDepsHook
        pkgs.cmake
        pkgs.ninja
        pycparser
        scikit-build
        setuptools
      ] ++ (if stdenv.isDarwin then [ pkgs.gcc ] else [ ]);

      propagatedBuildInputs = [
        librosa
      ];

      pythonImportsCheck = [ "whisper_cpp_python" ];

      meta = with lib; {
        description = "A Python wrapper for whisper.cpp";
        homepage = "https://github.com/carloscdias/whisper-cpp-python";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  ctransformers =
    let
      name = "ctransformers";
      version = "0.2.24";
      osSpecific =
        if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate ]
        else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
        else [ ];
    in
    buildPythonPackage {
      inherit version;
      pname = name;
      format = "setuptools";

      src = pkgs.fetchFromGitHub {
        owner = "marella";
        repo = name;
        rev = "refs/tags/v${version}";
        hash = "sha256-Ub+1z7A4kabQiuL+E2UlHzwY6dFZHSYR4VuFk9ancTY=";
        fetchSubmodules = true;
      };

      propagatedBuildInputs = [
        huggingface-hub
        py-cpuinfo
      ];
      dontUseCmakeConfigure = true;

      nativeBuildInputs = [
        pkgs.cmake
        scikit-build
      ];
      buildInputs = osSpecific;
      nativeCheckInputs = [ pytestCheckHook ];
      pythonImportsCheck = [ "ctransformers" ];
      disabledTestPaths = [ "tests/test_model.py" ];
      pytestFlagsArray = [ "--lib basic" ];
      meta = with lib; {
        description = "Python bindings for the Transformer models implemented in C/C++ using GGML library";
        homepage = "https://github.com/marella/ctransformers";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  google-cloud-aiplatform = buildPythonPackage rec {
    pname = "google-cloud-aiplatform";
    version = "1.27.0";
    format = "setuptools";

    src = pkgs.fetchFromGitHub {
      owner = "googleapis";
      repo = "python-aiplatform";
      rev = "refs/tags/v${version}";
      hash = "sha256-0bSmOcU4gcjI9RiF2RJX9mki4faXSXbIJNVh9GGgjOE=";
    };

    # let's remove this - we propagate it below
    postPatch = ''
      sed -i -E '/shapely/d' ./setup.py
      rm -rf ./samples
    '';

    # the tests require a variety of deps, and credentials
    doCheck = false;

    propagatedBuildInputs = [
      google-api-core
      google-cloud-bigquery
      google-cloud-resource-manager
      google-cloud-storage
      packaging
      proto-plus
      protobuf
      shapely
    ];

    nativeCheckInputs = [
      pytestCheckHook
      pytest-asyncio
    ];

    passthru.optional-dependencies = {
      autologging = [
        mlflow
      ];
      cloud_profiler = [
        tensorboard-plugin-profile
        tensorflow
        werkzeug
      ];
      datasets = [
        pyarrow
      ];
      endpoint = [
        requests
      ];
      full = [
        docker
        explainable-ai-sdk
        fastapi
        google-cloud-bigquery-storage
        google-vizier
        lit-nlp
        mlflow
        numpy
        pandas
        pyarrow
        pyyaml
        requests
        starlette
        tensorflow
        urllib3
        uvicorn
      ];
      lit = [
        explainable-ai-sdk
        lit-nlp
        pandas
        tensorflow
      ];
      metadata = [
        numpy
        pandas
      ];
      pipelines = [
        pyyaml
      ];
      prediction = [
        docker
        fastapi
        starlette
        uvicorn
      ];
      private_endpoints = [
        requests
        urllib3
      ];
      tensorboard = [
        tensorflow
      ];
      testing = [
        docker
        explainable-ai-sdk
        fastapi
        google-cloud-bigquery-storage
        google-vizier
        grpcio-testing
        ipython
        kfp
        lit-nlp
        mlflow
        numpy
        pandas
        pyarrow
        pytest-asyncio
        pytest-xdist
        pyyaml
        requests
        scikit-learn
        starlette
        tensorboard-plugin-profile
        tensorflow
        urllib3
        uvicorn
        werkzeug
        xgboost
      ];
      vizier = [
        google-vizier
      ];
      xai = [
        tensorflow
      ];
    };

    pythonImportsCheck = [ "google.cloud.aiplatform" ];

    meta = with lib; {
      description = "Vertex AI API client library";
      homepage = "https://github.com/googleapis/python-aiplatform";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
