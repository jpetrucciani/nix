# This overlay provides `snowball`, a fun way to package up some (snow)flakes and throw it at another operating system!
### example
# sudo -i nix-env -f https://github.com/jpetrucciani/nix/archive/main.tar.gz -iA snowball.amazon-ssm-agent
# sudo ln -s /nix/var/nix/profiles/default/snowball/amazon-ssm-agent.service /etc/systemd/system/amazon-ssm-agent.service
# sudo systemctl daemon-reload
# sudo systemctl enable amazon-ssm-agent
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
