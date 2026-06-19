# [semaphore](https://github.com/semaphoreui/semaphore) is a web UI for Ansible, Terraform/OpenTofu, PowerShell, and shell tasks
{ lib
, buildGoModule
, buildNpmPackage
, fetchFromGitHub
}:

let
  version = "2.18.12";
  commit = "8a4dcf0868af718aaa5871368a3247dd622521f4";

  src = fetchFromGitHub {
    owner = "semaphoreui";
    repo = "semaphore";
    rev = "v${version}";
    hash = "sha256-+Q2FlvjILYN4VuqzaZFH443XNl/lYPeMXkqzr6LFf6Y=";
  };

  webui = buildNpmPackage {
    pname = "semaphore-webui";
    inherit version src;

    sourceRoot = "source/web";
    npmDepsHash = "sha256-AucNPMJPkGpb03Thvndmph5WbBTBHXGe/Nyd7yJ78Jo=";

    makeCacheWritable = true;
    dontNpmBuild = true;

    preBuild = ''
      chmod -R u+w ..
      mkdir -p ../api
    '';

    buildPhase = ''
      runHook preBuild
      npm run build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -R ../api/public $out/public
      runHook postInstall
    '';
  };
in
buildGoModule {
  pname = "semaphore";
  inherit version src;

  vendorHash = "sha256-IGupO3i55YEx3ryxPrnEXxh6ssPpzeWX+nPMYKHZfCs=";
  overrideModAttrs = _: _: {
    postPatch = "";
  };
  env.CGO_ENABLED = 0;

  subPackages = [ "cli" ];

  tags = [ "netgo" ];

  postPatch = ''
    mkdir -p api
    cp -R ${webui}/public api/public
    chmod -R u+w api/public
  '';

  ldflags = [
    "-s"
    "-w"
    "-X github.com/semaphoreui/semaphore/util.Ver=v${version}"
    "-X github.com/semaphoreui/semaphore/util.Commit=${commit}"
    "-X github.com/semaphoreui/semaphore/util.Date=1780941527"
  ];

  postInstall = ''
    mv $out/bin/{cli,semaphore}
  '';

  meta = {
    description = "Modern UI and powerful API for Ansible, Terraform/OpenTofu/Terragrunt, PowerShell and other DevOps tools";
    homepage = "https://github.com/semaphoreui/semaphore";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "semaphore";
    platforms = lib.platforms.linux;
  };
}
