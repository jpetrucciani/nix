final: prev:
(x: { hax = x; }) (
  with prev;
  with lib;
  with builtins;
  lib // rec {
    inherit (stdenv) isLinux isDarwin isAarch64;
    inherit (pkgs) fetchFromGitHub;

    isM1 = isDarwin && isAarch64;
    isX86Mac = isDarwin && !isAarch64;
    isArmLinux = isAarch64 && isLinux;
    isNixOS = isLinux && (builtins.match ''.*ID="?nixos.*'' (builtins.readFile /etc/os-release)) == [ ];
    isAndroid = isAarch64 && !isDarwin && !isNixOS;
    isUbuntu = isLinux && (builtins.match ''.*ID="?ubuntu.*'' (builtins.readFile /etc/os-release)) == [ ];
    isWSL = isLinux && (builtins.match ''.*microsoft-standard-WSL2.*'' (builtins.readFile /proc/version)) == [ ];
    isNixDarwin = builtins.getEnv "NIXDARWIN_CONFIG" != "";

    attrIf = check: name: if check then name else null;
    # attrIf helpers
    ifIsLinux = attrIf isLinux;
    ifIsArmLinux = attrIf isArmLinux;
    ifIsNixOS = attrIf isNixOS;
    ifIsUbuntu = attrIf isUbuntu;
    ifIsNixDarwin = attrIf isNixDarwin;
    ifIsAndroid = attrIf isAndroid;
    ifIsDarwin = attrIf isDarwin;
    ifIsM1 = attrIf isM1;
    ifIsWSL = attrIf isWSL;

    kwb = fromJSON (readFile ../sources/kwb.json);
    chief_keef = import (
      prev.pkgs.fetchFromGitHub {
        inherit (kwb) rev sha256;
        owner = "kwbauson";
        repo = "cfg";
      }
    );

    pythonPackageOverlay =
      overlay: attr: self: super:
      let
        pyOverlay = a: {
          ${a} = self.lib.fix (py:
            super.${a}.override (old: {
              self = py;
              packageOverrides = self.lib.composeExtensions
                (old.packageOverrides or (_: _: { }))
                overlay;
            }));
        };
      in
      if builtins.isList attr then
        (builtins.zipAttrsWith (name: builtins.head) (map pyOverlay attr)) else pyOverlay attr;

    ssh = rec {
      github = ''
        Host github.com
          User git
          Hostname github.com
          PreferredAuthentications publickey
      '';
      mac_meme = ''
        IPQoS 0x00
          XAuthLocation /opt/X11/bin/xauth
      '';
      config = ''
        Include config.d/*

        Host *
          User jacobi
          PasswordAuthentication no
          Compression yes
          IdentitiesOnly yes
          # secure stuff
          Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
          KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
          MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
          HostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-512-cert-v01@openssh.com
          ${optionalString isDarwin mac_meme}
      '';
    };

    comma = (final.writeBashBinCheckedWithFlags {
      name = ",";
      description = "a quick and easy way to run software that you don't have!";
      flags = [
        {
          name = "package";
          description = "a specific package to use for this binary";
        }
        {
          name = "unset";
          description = "unset the saved package selection for this invocation";
          bool = true;
        }
        {
          name = "overlay";
          description = "an additional overlay to include in comma";
        }
        {
          name = "description";
          description = "print out the description of the package";
          bool = true;
        }
      ];
      arguments = [
        { name = "binary"; }
      ];
      script = ''
        exec ${chief_keef.better-comma}/bin/, \
          --overlay ${./mods.nix} \
          --overlay ${./pkgs/cli.nix} \
          --overlay ${./pkgs/cloud.nix} \
          --overlay ${./pkgs/k8s.nix} \
          --overlay ${./pkgs/server.nix} \
          ''${overlay:+--overlay $overlay} \
          ''${unset:+-u} \
          ''${description:+-d} \
          ''${package:+-p $package} \
          "$@"
      '';
    }).overrideAttrs (_: { name = "better-comma"; });
    vanilla_comma = chief_keef.better-comma;

    mapAttrValues = f: mapAttrs (_: f);
    fakePlatform = x:
      x.overrideAttrs (
        attrs: {
          meta = attrs.meta or { } // { platforms = lib.platforms.all; };
        }
      );
    prefixIf = b: x: y: if b then x + y else y;
    mapLines = f: s:
      concatMapStringsSep "\n" (l: if l != "" then f l else l)
        (splitString "\n" s);
    words = splitString " ";
    alias = name: x:
      writeShellScriptBin name
        ''exec ${if isDerivation x then exe x else x} "$@"'';
    overridePackage = pkg:
      let
        path = head (splitString ":" pkg.meta.position);
      in
      final.callPackage path;
    nix-direnv = prev.nix-direnv.override { inherit (prev) nix; };
    excludeLines = f: text:
      concatStringsSep "\n" (filter (x: !f x) (splitString "\n" text));
    drvs = x:
      if isDerivation x || isList x then
        flatten x
      else
        flatten (mapAttrsToList (_: drvs) x);
    writeBashBinChecked = name: text:
      stdenv.mkDerivation {
        inherit name text;
        dontUnpack = true;
        passAsFile = "text";
        nativeBuildInputs = [ shellcheck ];
        installPhase = ''
          mkdir -p $out/bin
          echo '#!/bin/bash' > $out/bin/${name}
          cat $textPath >> $out/bin/${name}
          chmod +x $out/bin/${name}
          shellcheck $out/bin/${name}
        '';
      };
    getJson = url: sha256:
      let
        text = fetchurl {
          inherit url sha256;
        };
      in
      fromJSON (readFile text);
    drvsExcept = x: e:
      with { excludeNames = concatMap attrNames (attrValues e); };
      flatten (drvs (filterAttrsRecursive (n: _: !elem n excludeNames) x));
    dmgOverride = name: pkg:
      with rec {
        src = sources."dmg-${name}";
        msg = "${name}: src ${src.version} != pkg ${pkg.version}";
        checkVersion = lib.assertMsg (pkg.version == src.version) msg;
      };
      if isDarwin then
        assert checkVersion;
        (mkDmgPackage name src) // {
          originalPackage = pkg;
        }
      else
        pkg;
    qlScript = name: command:
      (writeBashBinChecked name ''
        ${pkgs.up}/bin/up --unsafe-full-throttle -c '${command}'
      '');

    git-trim = writeBashBinChecked "git-trim" (readFile ../scripts/git-trim.sh);

    docker_aliases = rec {
      # docker
      d = "docker";
      da = "${d} ps -a";
      daq = "${d} ps -aq";
      di = "${d} images";
      drma = "${d} stop $(${daq}) && ${d} rm -f $(${daq})";
    };

    kubernetes_aliases = {
      # k8s
      k = "kubectl";
      kx = "kubectx";
      ka = "kubectl get pods";
    };
  }
)
  