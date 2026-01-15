# This overlay provides `snowball`, a fun way to package up some (snow)flakes and throw it at another operating system!
### example
# sudo -i nix-env -f https://github.com/jpetrucciani/nix/archive/main.tar.gz -iA snowball.amazon-ssm-agent
# sudo ln -s /nix/var/nix/profiles/default/snowball/amazon-ssm-agent.service /etc/systemd/system/amazon-ssm-agent.service
# sudo systemctl daemon-reload
# sudo systemctl enable amazon-ssm-agent
final: prev:
let
  inherit (final.lib) filter fix hasAttr hasSuffix attrNames concatMapStringsSep foldl recursiveUpdate;
  inherit (final.writers) writeBashBin;
  _merge = foldl recursiveUpdate { };

  defaults = {
    user = "root";
    group = "root";
    env = {
      SNOWBALL = "0.0.3";
      TZ = "America/New_York";
      TZDIR = "${final.tzdata}/share/zoneinfo";
    };
    wantedBy = [ "multi-user.target" ];
  };

  _snowball =
    { name
    , conf
    , preInstall ? ""
    , postInstall ? ""
    , prePack ? ""
    , postPack ? ""
    }:
    let
      defaults = { system.stateVersion = final.lib.mkDefault "25.05"; };
      empty = final.nixos defaults;
      os = final.nixos { imports = [ defaults conf ]; };
      uniqueKeys = a: b: filter (k: !hasAttr k b) (attrNames a);
      systemd-units = uniqueKeys os.config.systemd.units empty.config.systemd.units;
      enable_units = filter (x: !(hasSuffix ".target" x)) systemd-units;
      start_units = filter (x: hasSuffix ".timer" x) systemd-units;
    in
    fix (result: final.buildEnv {
      name = "snowball_${name}";
      extraPrefix = "/snowball";
      paths = map (unit: os.config.systemd.units.${unit}.unit) systemd-units;
      passthru =
        let
          vars = ''
            _name="${name}"
            _units="${concatMapStringsSep " " (unit: unit) systemd-units}"
          '';
        in
        rec {
          install = (writeBashBin "install" ''
            _drv=${result}
            ${vars}
            # preInstall
            echo "[${name}] preInstall" >&2
            ${preInstall}
            sudo -i nix-env -i "$_drv"
            ${concatMapStringsSep "\n" (unit: ''sudo ln -sf /nix/var/nix/profiles/default/snowball/${unit} /etc/systemd/system/${unit}'') systemd-units}
            # install
            sudo systemctl daemon-reload
            # enable everything except targets
            ${concatMapStringsSep "\n" (unit: ''sudo systemctl enable ${unit}'') enable_units}

            # start timers
            ${concatMapStringsSep "\n" (unit: ''sudo systemctl start ${unit}'') start_units}

            # postInstall
            echo "[${name}] postInstall" >&2
            ${postInstall}
          '').overrideAttrs { name = "snowball_${name}_install"; };
          pack = (writeBashBin "pack" ''
            _install=${install}
            ${vars}
            # prePack
            echo "[${name}] prePack" >&2
            ${prePack}
            install_store_path=$(nix build --no-link --print-out-paths $_install)
            echo "built the snowball installer to $install_store_path" >&2

            # postPack
            echo "[${name}] postPack" >&2
            ${postPack}
          '').overrideAttrs { name = "snowball_${name}_pack"; };
        };
    });

  job =
    { name
    , script
    , description ? ""
    , user ? defaults.user
    , group ? defaults.group
    , _path ? with final; [ bash coreutils ]  # default paths to add (so we can remove if needed)
    , path ? [ ] # extra paths to append to _path
    , env ? { }
    , envFile ? null
    , calendar ? [ ]
    , needs ? [ ]
    , wantedBy ? defaults.wantedBy
    , onSuccess ? "echo 'success!'"
    , onFailure ? "echo 'failure!'"
    , extra ? { }
    }:
    let
      toServiceName = name: if hasSuffix ".service" name then name else name + ".service";
      all_paths = _path ++ path;
      after = map toServiceName needs;
    in
    assert (calendar != [ ] || needs != [ ]) || throw "you must specify a list of 'calendar' entries, or a list of 'needs'";
    {
      systemd.services = {
        ${name} = _merge [
          {
            inherit description script;
            path = all_paths;
            environment = defaults.env // env;
            ${if calendar != [ ] then "startAt" else null} = calendar;
            serviceConfig = {
              Group = group;
              User = user;
              ${if envFile != null then "EnvironmentFile" else null} = envFile;
            };
            inherit after;
            requires = after;
            unitConfig.PartOf = after;
            postStop = ''
              if [ $SERVICE_RESULT = "success" ]; then
                ${onSuccess}
              else
                ${onFailure}
              fi
            '';
            wantedBy = if needs == [ ] then wantedBy else after;
          }
          extra
        ];
      };
    };

  svc = { name, script, env ? { }, wantedBy ? defaults.wantedBy, extra ? { } }: {
    systemd.services.${name} = _merge [
      {
        inherit wantedBy script;
        environment = defaults.env // env;
      }
      extra
    ];
  };

  # examples/tests
  job_x = job { name = "job_x"; script = ''echo 123 >/tmp/job_x.out.txt''; calendar = [ "minutely" ]; };
  job_y = job { name = "job_y"; script = ''cat /tmp/job_x.out.txt /tmp/job_x.out.txt /tmp/job_x.out.txt >/tmp/job_y.out.txt''; needs = [ "job_x" ]; };
  job_z = job { name = "job_z"; script = ''${final.busybox}/bin/wc -l /tmp/job_y.out.txt >/tmp/job_z.out.txt''; needs = [ "job_y" ]; };
in
{
  snowball =
    {
      # snowball tools
      templates = {
        inherit job svc;
      };
      tools = {
        inherit _merge _snowball;
      };
      pack = _snowball;

      # examples
      amazon-ssm-agent = _snowball { name = "amazon-ssm-agent"; conf = { services.amazon-ssm-agent.enable = true; }; };
      earlyoom = _snowball {
        name = "earlyoom";
        conf = {
          systemd.services.earlyoom.serviceConfig.ExecStart = "${final.earlyoom}/bin/earlyoom";
          services.earlyoom = {
            enable = true;
            freeSwapThreshold = 10;
            freeMemThreshold = 10;
            extraArgs = [
              "-g"
              "--avoid '(^|/)(sshd|systemd|kubelet)$'"
              "--prefer '(^|/)(python.*|node)$'"
            ];
          };
        };
      };

      _examples = {
        example_jobset = _snowball { name = "job_test"; conf = _merge [ job_x job_y job_z ]; };
      };
    };
}
