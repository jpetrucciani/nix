# this is a lightweight nix env showing how you can include hex in your local environment
{ pkgs ? import
    (fetchTarball {
      name = "jpetrucciani-2025-01-22";
      url = "https://github.com/jpetrucciani/nix/archive/823936a22b0f0e545b1fa8e88f24343967f18330.tar.gz";
      sha256 = "0d01ipxvgyyr0akyfr6phl080sg5rnsw2bwbffcxrng2yna4z8ap";
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
  NIXUP = "0.0.9";
})) // { inherit scripts; }
