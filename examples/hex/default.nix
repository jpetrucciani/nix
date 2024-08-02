# this is a lightweight nix env showing how you can include hex in your local environment
{ pkgs ? import
    (fetchTarball {
      name = "jpetrucciani-2024-08-02";
      url = "https://github.com/jpetrucciani/nix/archive/231b96d11db575631fb5c16f9fb4165950966358.tar.gz";
      sha256 = "0zbkds5mlxjnp05pyh96z51samw1ikknyz4ndjpcsf8g7khaw9qw";
    })
    { }
}:
let
  name = "hex";

  tools = with pkgs; {
    k8s = [
      hex
      kubectl
    ];
    scripts = pkgs.lib.attrsets.attrValues scripts;
  };

  scripts = with pkgs; { };
  paths = pkgs.lib.flatten [ (builtins.attrValues tools) ];
  env = pkgs.buildEnv {
    inherit name paths; buildInputs = paths;
  };
in
(env.overrideAttrs (_: {
  inherit name;
  NIXUP = "0.0.7";
})) // { inherit scripts; }
