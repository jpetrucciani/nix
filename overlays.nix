with builtins; [
  (
    self: super:
      (x: { hax = x; }) (
        with super;
        with lib;
        with builtins;
        lib // rec {
          inherit (stdenv) isLinux isDarwin isAarch64;
          inherit (pkgs) fetchFromGitHub;

          isM1 = isDarwin && isAarch64;

          kwb = with builtins; fromJSON (readFile ./sources/kwb.json);
          chief_keef = import (
            super.pkgs.fetchFromGitHub {
              owner = "kwbauson";
              repo = "cfg";
              rev = kwb.rev;
              sha256 = kwb.sha256;
            }
          );
          comma = chief_keef.better-comma;

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
          soundScript = name: url: hash:
            let
              file = pkgs.fetchurl {
                url = url;
                sha256 = hash;
              };
            in
            writeShellScriptBin name ''
              ${sox}/bin/play --no-show-progress ${file} &
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
          qlScript = name: command:
            (writeBashBinChecked name ''
              ${pkgs.up}/bin/up --unsafe-full-throttle -c '${command}'
            ''
            );

          soundFolder = "https://hexa.dev/static/sounds";

          meme_sounds = [
            (soundScript "coin" "${soundFolder}/coin.wav" "18c7dfhkaz9ybp3m52n1is9nmmkq18b1i82g6vgzy7cbr2y07h93")
            (soundScript "guh" "${soundFolder}/guh.wav" "1chr6fagj6sgwqphrgbg1bpmyfmcd94p39d34imq5n9ik674z9sa")
            (soundScript "bruh" "${soundFolder}/bruh.mp3" "11n1a20a7fj80xgynfwiq3jaq1bhmpsdxyzbnmnvlsqfnsa30vy3")
            (soundScript "fail" "${soundFolder}/the-price-is-wrong.mp3" "1kj0n7qwl6saqqmjn8xlkfjwimi2hyxgaqdkkzn5z1rgnhwwvp91")
          ];

          aws_bash_scripts = [
            (
              writeBashBinChecked "aws_id" ''
                aws sts get-caller-identity --query Account --output text
              ''
            )
            (
              writeBashBinChecked "ecr_login" ''
                region="''${1:-us-east-1}"
                ${pkgs.awscli2}/bin/aws ecr get-login-password --region "''${region}" |
                ${pkgs.docker-client}/bin/docker login --username AWS \
                    --password-stdin "$(${pkgs.awscli2}/bin/aws sts get-caller-identity --query Account --output text).dkr.ecr.''${region}.amazonaws.com"
              ''
            )
            (
              writeBashBinChecked "ecr_login_public" ''
                region="''${1:-us-east-1}"
                ${pkgs.awscli2}/bin/aws ecr-public get-login-password --region "''${region}" |
                ${pkgs.docker-client}/bin/docker login --username AWS \
                    --password-stdin public.ecr.aws
              ''
            )
          ];

          general_bash_scripts = [
            (
              writeBashBinChecked "hms" ''
                ${pkgs.git}/bin/git -C ~/.config/nixpkgs/ pull origin main
                home-manager switch
              ''
            )
            (
              writeBashBinChecked "get_cert" ''
                ${pkgs.curl}/bin/curl --insecure -I -vvv "$1" 2>&1 |
                  ${pkgs.gawk}/bin/awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }'
              ''
            )
            (
              writeBashBinChecked "jql" ''
                echo "" | ${pkgs.fzf}/bin/fzf --print-query --preview-window wrap --preview "cat $1 | ${pkgs.jq}/bin/jq -C {q}"
              ''
            )
            (
              writeBashBinChecked "slack_meme" ''
                word="$1"
                fg="$2"
                bg="$3"
                ${pkgs.figlet}/bin/figlet -f banner "$word" | sed 's/#/:'"$fg"':/g;s/ /:'"$bg"':/g' | awk '{print ":'"$bg"':" $1}'
              ''
            )
            (
              writeBashBinChecked "ssh_fwd" ''
                host="$1"
                port="$2"
                ${pkgs.openssh}/bin/ssh -L "$port:$host:$port" "$host"
              ''
            )
            (
              writeBashBinChecked "scale_x" ''
                file="$1"
                px="$2"
                ${pkgs.ffmpeg}/bin/ffmpeg -i "$file" -vf scale="$px:-1" "''${file%.*}.$px.''${file##*.}"
              ''
            )
            (
              writeBashBinChecked "scale_y" ''
                file="$1"
                px="$2"
                ${pkgs.ffmpeg}/bin/ffmpeg -i "$file" -vf scale="-1:$px" "''${file%.*}.$px.''${file##*.}"
              ''
            )
          ];

          k8s_bash_scripts = [
            # deployment stuff
            (
              writeBashBinChecked "_get_deployment_patch" ''
                echo "spec.template.metadata.labels.date = \"$(date +'%s')\";" | \
                  ${pkgs.gron}/bin/gron -u | \
                  tr -d '\n' | \
                  ${pkgs.gnused}/bin/sed -E 's#\s+##g'
              ''
            )
            (
              writeBashBinChecked "refresh_deployment" ''
                deployment_id="$1"
                namespace="''${2:-default}"
                ${pkgs.kubectl}/bin/kubectl --namespace "$namespace" \
                  patch deployment "$deployment_id" --patch "''$(_get_deployment_patch)"
                ${pkgs.kubectl}/bin/kubectl --namespace "$namespace" rollout status deployment/"$deployment_id"
              ''
            )
          ];

          docker_aliases = {
            # docker
            d = "docker";
            da = "docker ps -a";
            di = "docker images";
            de = "docker exec -it";
            dr = "docker run --rm -it";
            drma = "docker stop $(docker ps -aq) && docker rm -f $(docker ps -aq)";
            drmi = "di | grep none | awk '{print $3}' | sponge | xargs docker rmi";
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
              kubectl run "jacobi-''${RANDOM}" -it --image-pull-policy=Always --rm --restart Never --image=alpine:latest'';
          };

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
      let
        extra-packages =
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
      in
      { inherit extra-packages; } // extra-packages
  )
  (
    self: super: {
      _nix_hash = with super; with hax; repo: branch: name: (
        writeBashBinChecked "nix_hash_${name}" ''
          ${nix-prefetch-git}/bin/nix-prefetch-git \
            --quiet \
            --no-deepClone \
            --branch-name ${branch} \
            https://github.com/${repo}.git | \
          ${jq}/bin/jq '{ rev: .rev, sha256: .sha256 }'
        ''
      );
      nix_hash_unstable = self._nix_hash "NixOS/nixpkgs" "nixpkgs-unstable" "unstable";
      nix_hash_jpetrucciani = self._nix_hash "jpetrucciani/nix" "main" "jpetrucciani";
      nix_hash_kwb = self._nix_hash "kwbauson/cfg" "main" "kwb";
      nix_hash_hm = self._nix_hash "nix-community/home-manager" "master" "hm";
      git-trim = with super; with hax; (
        writeBashBinChecked "git-trim" (readFile ./scripts/git-trim.sh)
      );
      home-packages = (import ./home.nix).home.packages;
    }
  )
]
