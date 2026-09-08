{ lib
, stdenv
, buildGoModule
, fetchFromGitHub
, makeWrapper
, coreutils
, runCommand
, runtimeShell
, writeText
, terraform-providers
, installShellFiles
,
}:

let
  package = buildGoModule (finalAttrs: {
    pname = "terraform";
    version = "1.5.5";

    src = fetchFromGitHub {
      owner = "hashicorp";
      repo = "terraform";
      rev = "v${finalAttrs.version}";
      hash = "sha256-SBS3a/CIUdyIUJvc+rANIs+oXCQgfZut8b0517QKq64=";
    };

    vendorHash = "sha256-lQgWNMBf+ioNxzAV7tnTQSIS840XdI9fg9duuwoK+U4=";

    patches = [ ./provider-path-0_15.patch ];

    env.CGO_ENABLED = if stdenv.hostPlatform.isDarwin then "1" else "0";

    ldflags = [
      "-s"
      "-w"
    ];

    postConfigure = ''
      substituteInPlace vendor/github.com/bgentry/speakeasy/speakeasy_unix.go \
        --replace-fail "/bin/stty" "${coreutils}/bin/stty"
    '';

    nativeBuildInputs = [ installShellFiles ];

    postInstall = ''
      installShellCompletion --bash --name terraform <(echo complete -C terraform terraform)
    '';

    preCheck = ''
      export HOME=$TMPDIR
      export TF_SKIP_REMOTE_TESTS=1
    '';

    subPackages = [ "." ];

    passthru = {
      inherit plugins;
      tests = { inherit terraform_plugins_test; };
    };

    meta = {
      description = "Tool for building, changing, and versioning infrastructure";
      homepage = "https://www.terraform.io/";
      changelog = "https://github.com/hashicorp/terraform/blob/v${finalAttrs.version}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      maintainers = with lib.maintainers; [ jpetrucciani ];
      mainProgram = "terraform";
    };
  });

  terraform_plugins_test =
    let
      mainTf = writeText "main.tf" ''
        resource "random_id" "test" {}
      '';
      terraform = (pluggable package).withPlugins (providers: [ providers.hashicorp_random ]);
    in
    runCommand "terraform-plugin-test" { buildInputs = [ terraform ]; } ''
      set -e
      export HTTP_PROXY=http://127.0.0.1:0 HTTPS_PROXY=https://127.0.0.1:0
      cp ${mainTf} main.tf
      terraform init
      touch $out
    '';

  pluggable =
    terraform:
    let
      withPlugins =
        selectedPlugins:
        let
          actualPlugins = selectedPlugins terraform.plugins;
          wrapperInputs = lib.unique (
            lib.flatten (
              lib.catAttrs "propagatedBuildInputs" (builtins.filter (plugin: plugin != null) actualPlugins)
            )
          );
          passthru = {
            withPlugins = newPlugins: withPlugins (plugins': newPlugins plugins' ++ actualPlugins);
            full = withPlugins (
              providers: lib.filter lib.isDerivation (lib.attrValues providers.actualProviders)
            );
            overrideDerivation = f: (pluggable (terraform.overrideDerivation f)).withPlugins selectedPlugins;
            overrideAttrs = f: (pluggable (terraform.overrideAttrs f)).withPlugins selectedPlugins;
            override = args: (pluggable (terraform.override args)).withPlugins selectedPlugins;
          };
        in
        if actualPlugins == [ ] then
          terraform.overrideAttrs
            (oldAttrs: {
              passthru = oldAttrs.passthru // passthru;
            })
        else
          lib.appendToName "with-plugins" (
            stdenv.mkDerivation {
              inherit (terraform) meta pname version;
              nativeBuildInputs = [ makeWrapper ];
              passthru = terraform.passthru // passthru;

              buildCommand = ''
                for providerDir in ${toString actualPlugins}; do
                  for file in $(find "$providerDir/libexec/terraform-providers" -type f); do
                    relativeFile=''${file#"$providerDir/"}
                    mkdir -p "$out/$(dirname "$relativeFile")"
                    cat <<WRAPPER > "$out/$relativeFile"
                #!${runtimeShell}
                exec "$file" "$@"
                WRAPPER
                    chmod +x "$out/$relativeFile"
                  done
                done

                mkdir -p "$out/bin"
                makeWrapper "${terraform}/bin/terraform" "$out/bin/terraform" \
                  --set NIX_TERRAFORM_PLUGIN_DIR "$out/libexec/terraform-providers" \
                  --prefix PATH : "${lib.makeBinPath wrapperInputs}"
              '';
            }
          );
    in
    withPlugins (_: [ ]);

  plugins = builtins.removeAttrs terraform-providers [
    "override"
    "overrideDerivation"
    "recurseForDerivations"
  ];
in
pluggable package
