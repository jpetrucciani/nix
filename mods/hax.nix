prev: next:
(x: { hax = x; }) (
  with next;
  with lib;
  with builtins;
  lib // rec {
    inherit (stdenv) isLinux isDarwin isAarch64;
    inherit (pkgs) fetchFromGitHub;

    isM1 = isDarwin && isAarch64;
    isAndroid = isAarch64 && !isDarwin;
    isNixOS = isLinux && (builtins.match ".*ID=nixos.*" (builtins.readFile /etc/os-release)) == [ ];
    isUbuntu = isLinux && (builtins.match ".*ID=ubuntu.*" (builtins.readFile /etc/os-release)) == [ ];
    isNixDarwin = builtins.getEnv "NIXDARWIN_CONFIG" != "";

    kwb = with builtins; fromJSON (readFile ../sources/kwb.json);
    chief_keef = import (
      next.pkgs.fetchFromGitHub {
        inherit (kwb) rev sha256;
        owner = "kwbauson";
        repo = "cfg";
      }
    );

    comma = writeShellScriptBin "," ''
      exec ${chief_keef.better-comma}/bin/, --overlay ${./mods.nix} "$@"
    '';
    vanilla_comma = chief_keef.better-comma;

    mapAttrValues = f: mapAttrs (n: v: f v);
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
        flatten (mapAttrsToList (_: v: drvs v) x);
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
    brewCask = cask: sha256:
      let
        home = getEnv "HOME";
        data =
          getJson "https://formulae.brew.sh/api/cask/${cask}.json" sha256;
        appFile = head (filter isString (lists.flatten data.artifacts));
      in
      stdenv.mkDerivation {
        name = data.token;
        src = fetchurl {
          inherit url sha256;
          name = "${data.token}.dmg";
        };
        phases = [ "unpackPhase" "buildPhase" "installPhase" ];
        buildInputs = [ undmg ];
        installPhase = ''
            mkdir -p $out/Applications
            cp -R ${appFile} "$out/Applications"
            ln -s "$out/Applications/${appFile}" "${home}/Applications/${
          head data.name
          }.app"
        '';
        meta = { };
        sourceRoot = ".";
      };
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
      de = "${d} exec -it";
      dr = "${d} run --rm -it";
      drma = "${d} stop $(${daq}) && ${d} rm -f $(${daq})";
    };

    kubernetes_aliases = {
      # k8s
      k = "kubectl";
      kx = "kubectx";
      ka = "kubectl get pods";
      kaw = "kubectl get pods -o wide";
      knuke = "kubectl delete pods --grace-period=0 --force";
      klist =
        "kubectl get pods --all-namespaces -o jsonpath='{..image}' | tr -s '[[:space:]]' '\\n' | sort | uniq -c";
      kshell = ''
        kubectl run "''${user}-''${RANDOM}" -it --image-pull-policy=Always --rm --restart Never --image=alpine:latest'';
    };

  }
)
  