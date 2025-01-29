# This overlay provides `snowball`, a fun way to package up some (snow)flakes and throw it at another operating system!
### example
# sudo -i nix-env -f https://github.com/jpetrucciani/nix/archive/main.tar.gz -iA snowball.amazon-ssm-agent
# sudo ln -s /nix/var/nix/profiles/default/snowball/amazon-ssm-agent.service /etc/systemd/system/amazon-ssm-agent.service
# sudo systemctl daemon-reload
# sudo systemctl enable amazon-ssm-agent
final: prev: {
  snowball =
    let
      inherit (final.lib) filter fix hasAttr attrNames concatMapStringsSep;
      _snowball = { name, conf }:
        let
          defaults = { system.stateVersion = final.lib.mkDefault "25.05"; };
          empty = final.nixos defaults;
          os = final.nixos { imports = [ defaults conf ]; };
          uniqueKeys = a: b: filter (k: !hasAttr k b) (attrNames a);
          systemd-units = uniqueKeys os.config.systemd.units empty.config.systemd.units;
        in
        fix (result: final.buildEnv {
          name = "snowball_${name}";
          extraPrefix = "/snowball";
          paths = map (unit: os.config.systemd.units.${unit}.unit) systemd-units;
          passthru.install = (final.writers.writeBashBin "install" ''
            sudo -i nix-env -i ${result}
            ${concatMapStringsSep "\n" (unit: ''
            sudo ln -sf /nix/var/nix/profiles/default/snowball/${unit} /etc/systemd/system/${unit}
            '') systemd-units}
            sudo systemctl daemon-reload
            ${concatMapStringsSep "\n" (unit: ''
            sudo systemctl enable ${unit}
            '') systemd-units}
          '').overrideAttrs { name = "snowball_${name}_install"; };
        });
    in
    {
      pack = _snowball;
      amazon-ssm-agent = _snowball { name = "amazon-ssm-agent"; conf = { services.amazon-ssm-agent.enable = true; }; };
    };
}
