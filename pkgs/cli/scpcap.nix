{ lib
, fetchgit
, makeWrapper
, openssh
, rustPlatform
}:

rustPlatform.buildRustPackage {
  pname = "scpcap";
  version = "0.1.0-unstable-2026-08-28";

  src = fetchgit {
    url = "https://git.digitalsorcery.net/eric/scpcap";
    rev = "aeb827b3615d3ecea857c355ed6c4211833450c6";
    hash = "sha256-OZtIa2ez8nJH4noeHQJ3IA/wAt/2MVvCU0u+JEe7kpk=";
  };

  cargoHash = "sha256-eFtE/llDyMdo20og2SfAwlqY78o3ABfqEzM9dJS+Jcg=";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram "$out/bin/scpcap" \
      --prefix PATH : ${lib.makeBinPath [ openssh ]}
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/scpcap" --help >/dev/null

    runHook postInstallCheck
  '';

  meta = {
    description = "Copy local or remote packet captures while they are still growing";
    homepage = "https://git.digitalsorcery.net/eric/scpcap";
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "scpcap";
    platforms = lib.platforms.unix;
  };
}
