# This overlay provides the `hax` library, which contains useful functions and other packages and configurations.
final: prev:
(x: { hax = x; }) (
  with prev;
  with lib;
  lib // rec {
    inherit (stdenv) isLinux isDarwin isAarch64;
    inherit (pkgs) fetchFromGitHub;

    isM1 = isDarwin && isAarch64;
    isX86Mac = isDarwin && !isAarch64;
    isArmLinux = isAarch64 && isLinux;
    isNixDarwin = builtins.getEnv "NIXDARWIN_CONFIG" != "";
    isWSL = builtins.pathExists "/proc/sys/fs/binfmt_misc/WSLInterop";
    isNixOS = builtins.pathExists "/etc/NIXOS";
    isNixOSWSL = isWSL && isNixOS;

    nvidiaLdPath = if isWSL then "/usr/lib/wsl/lib" else if isNixOS then "/run/opengl-driver/lib" else "";

    attrIf = check: name: if check then name else null;
    attrHash = attrs: builtins.hashString "sha256" (builtins.toJSON attrs);
    # attrIf helpers
    ifIsLinux = attrIf isLinux;
    ifIsArmLinux = attrIf isArmLinux;
    ifIsUbuntu = attrIf isUbuntu;
    ifIsNixDarwin = attrIf isNixDarwin;
    ifIsDarwin = attrIf isDarwin;
    ifIsM1 = attrIf isM1;

    chief_keef = flake.inputs.kwb.packages.${pkgs.stdenv.hostPlatform.system};

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
        (builtins.zipAttrsWith (_: builtins.head) (map pyOverlay attr)) else pyOverlay attr;

    ssh = rec {
      github = ''
        Host github.com
          User git
          Hostname github.com
          PreferredAuthentications publickey
      '';
      mac_meme = ''
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

    comma = (pog {
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
    optList = conditional: list: if conditional then list else [ ];
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

    basePythonPackages = p: with p; [
      # common use case
      gamble
      httpx
      cryptography

      # text
      anybadge
      tabulate
      beautifulsoup4

      # data
      numpy
      pandas
      polars

      # my types (for nixpkgs)
      boto3-stubs
      botocore-stubs
    ]
    ++ (optList (!isM1) [ ])
    ++ (optList isLinux [ ])
    ;

    filterSrc =
      { path
      , default_ignores ? [
          ".db"
          ".git"
          ".mypy_cache"
          ".ruff_cache"
          ".terraform"
          "*.logs"
          "bin"
          "build"
          "dist"
          "logs"
          "node_modules"
          "tmp"
          "venv"
        ]
      , extra_ignore ? [ ]
      }: final.nix-gitignore.gitignoreSource (default_ignores ++ extra_ignore) path;

    exportFilterPath = names:
      let
        grepV = lib.concatMapStrings (n: " | grep -v ${n}") names;
        tr = "${final.busybox}/bin/tr";
      in
      ''
        export PATH=$(echo $PATH | ${tr} ':' '\n' ${grepV} | ${tr} '\n' ':')
      '';
  }
)
  