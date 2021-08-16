with builtins; [
  (
    self: super:
      (x: { hax = x; }) (
        with super;
        with lib;
        with builtins;
        lib // rec {
          inherit (stdenv) isLinux isDarwin;
          inherit (pkgs) fetchFromGitHub;
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
            self.callPackage path;
          nix-direnv = super.nix-direnv.override { nix = super.nixUnstable; };
          excludeLines = f: text:
            concatStringsSep "\n" (filter (x: !f x) (splitString "\n" text));
          drvs = x:
            if isDerivation x || isList x then
              flatten x
            else
              flatten (mapAttrsToList (_: v: drvs v) x);
          soundScript = x: y:
            writeShellScriptBin x ''
              ${sox}/bin/play --no-show-progress ${y}
            '';
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
                url = url;
                sha256 = sha256;
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
                name = "${data.token}.dmg";
                url = data.url;
                sha256 = data.sha256;
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
        }
      )
  )
  (
    self: super:
      with super;
      mapAttrs (n: v: hax.fakePlatform v) {
        inherit gixy;
        inherit brave;
      }
  )
  (
    self: super:
      let extraPackages =
        with super;
        with hax;
        (
          fn:
          optionalAttrs (pathExists ./pkgs)
            (listToAttrs (mapAttrsToList fn (readDir ./pkgs)))
        ) (
          n: _: rec {
            name = removeSuffix ".nix" n;
            value = pkgs.callPackage (./pkgs + ("/" + n)) { };
          }
        );
      in { inherit extraPackages; } // extraPackages
  )
]
