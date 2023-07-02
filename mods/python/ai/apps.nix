final: prev: with prev; {
  lama-cleaner =
    let
      name = "lama-cleaner";
      version = "1.2.1";
    in
    buildPythonPackage {
      inherit version;
      pname = name;
      format = "setuptools";

      src = pkgs.fetchFromGitHub {
        owner = "Sanster";
        repo = name;
        rev = "203e775e2ed9bda2c55b15bba71a2a107ba7b8d2";
        hash = "sha256-r0ZiHdUdEckqR2TmsJDrH5/4Jp63IZRMNex1iqqDHHQ=";
      };

      propagatedBuildInputs = [
        accelerate
        # controlnet-aux
        diffusers
        flask
        flask-cors
        flask-socketio
        flaskwebgui
        gradio
        jinja2
        loguru
        markupsafe
        omegaconf
        opencv4
        piexif
        pydantic
        pytest
        rich
        safetensors
        scikit-image
        simple-websocket
        torch
        torchvision
        tqdm
        transformers
        yacs
      ];

      postPatch = ''
        sed -i -E \
          -e '/opencv-python/d' \
          -e '/diffusers\[torch/d' \
          -e '/controlnet-aux/d' \
          ./requirements.txt
      '';

      pythonRelaxDeps = [
        "Jinja2"
        "flask"
        "flaskwebgui"
        "markupsafe"
        "transformers"
      ];
      nativeBuildInputs = [
        pythonRelaxDepsHook
      ];

      pythonImportsCheck = [ "lama_cleaner" ];
      doCheck = false;

      meta = with lib; {
        description = "Image inpainting tool powered by SOTA AI Model";
        homepage = "https://github.com/Sanster/lama-cleaner";
        mainProgram = "lama-cleaner";
        license = licenses.asl20;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };
}
