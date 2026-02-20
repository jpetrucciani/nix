{ lib
, rustPlatform
, fetchFromGitHub
, installShellFiles
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "weathr";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "Veirt";
    repo = "weathr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-JwI5a+O5Nu39Nr0st5yBLTM5kPLC8UIGAoBMqxnOOl4=";
  };

  cargoHash = "sha256-Yj1WxpOLL8GiVpCebPZQgdw+L9g+4CNY7n2z8PJQz4k=";

  nativeBuildInputs = [
    installShellFiles
  ];

  doCheck = false; # tests require network

  meta = {
    description = "A terminal weather app with ascii animation";
    homepage = "https://github.com/Veirt/weathr";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "weathr";
  };
})
