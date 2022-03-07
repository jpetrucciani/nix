prev: next:
(x: { hax = x; }) (
  with next;
  with lib;
  with builtins;
  lib // rec {
    inherit (stdenv) isLinux isDarwin isAarch64;
    inherit (pkgs) fetchFromGitHub;

    isM1 = isDarwin && isAarch64;
    isNixOS = isLinux && (builtins.match ''.*ID="?nixos.*'' (builtins.readFile /etc/os-release)) == [ ];
    isAndroid = isAarch64 && !isDarwin && !isNixOS;
    isUbuntu = isLinux && (builtins.match ''.*ID="?ubuntu.*'' (builtins.readFile /etc/os-release)) == [ ];
    isNixDarwin = builtins.getEnv "NIXDARWIN_CONFIG" != "";

    kwb = with builtins; fromJSON (readFile ../sources/kwb.json);
    chief_keef = import (
      next.pkgs.fetchFromGitHub {
        inherit (kwb) rev sha256;
        owner = "kwbauson";
        repo = "cfg";
      }
    );

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

    comma = (prev.writeBashBinCheckedWithFlags {
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
          --overlay ${./pkgs.nix} \
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
    attrIf = check: name: if check then name else null;
    alias = name: x:
      writeShellScriptBin name
        ''exec ${if isDerivation x then exe x else x} "$@"'';
    overridePackage = pkg:
      let
        path = head (splitString ":" pkg.meta.position);
      in
      prev.callPackage path;
    nix-direnv = next.nix-direnv.override { nix = next.nixUnstable; };
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
        installPhase = ''
          mkdir -p $out/bin
          echo '#!/bin/bash' > $out/bin/${name}
          cat $textPath >> $out/bin/${name}
          chmod +x $out/bin/${name}
          ${shellcheck}/bin/shellcheck $out/bin/${name}
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
  