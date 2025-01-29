# This overlay provides `snowball`, a fun way to package up some (snow)flakes and throw it at another operating system!
final: prev: {
  snowball =
    let
      _snowball = { name, conf }:
        let
          defaults = { system.stateVersion = final.lib.mkDefault "25.05"; };
          empty = final.nixos defaults;
          os = final.nixos { imports = [ defaults conf ]; };
          uniqueKeys = a: b: builtins.filter (k: !builtins.hasAttr k b) (builtins.attrNames a);
          systemd-units = uniqueKeys os.config.systemd.units empty.config.systemd.units;
        in
        final.buildEnv {
          name = "snowball-${name}";
          extraPrefix = "/snowball";
          paths = map (unit: os.config.systemd.units.${unit}.unit) systemd-units;
        };
    in
    {
      pack = _snowball;
      amazon-ssm-agent = _snowball { name = "amazon-ssm-agent"; conf = { services.amazon-ssm-agent.enable = true; }; };
    };
}
