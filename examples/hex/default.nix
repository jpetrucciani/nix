# this is a lightweight nix env showing how you can include hex in your local environment
{ pkgs ? import
    (fetchTarball {
      name = "jpetrucciani-2024-03-15";
      url = "https://github.com/jpetrucciani/nix/archive/901e642726b101dfd5ad6fb9f16aa608d2e96efa.tar.gz";
      sha256 = "0083rdr4lqc6hlc3c8n6rkqzxk4qf8b3y73vml1mx16da242d1if";
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
  NIXUP = "0.0.6";
})) // { inherit scripts; }
