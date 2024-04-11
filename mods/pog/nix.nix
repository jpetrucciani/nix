# This module configures some helper tools for creating new nix environments!
final: prev:
let
  inherit (final) _ pog lib;
in
rec {
  nixup = let version = "0.0.6"; in pog {
    inherit version;
    name = "nixup";
    description = "a quick tool to create/update a base default.nix environment!";
    flags = [
      { name = "update"; bool = true; description = "update the pin to jpetrucciani in the given file (argument 1) [default: ./default.nix]"; }
      _.flags.nix.with_crystal
      _.flags.nix.with_db_pg
      _.flags.nix.with_db_redis
      _.flags.nix.with_elixir
      _.flags.nix.with_golang
      _.flags.nix.with_nim
      _.flags.nix.with_node
      _.flags.nix.with_php
      _.flags.nix.with_poetry
      _.flags.nix.with_pulumi
      _.flags.nix.with_python
      _.flags.nix.with_ruby
      _.flags.nix.with_rust
      _.flags.nix.with_terraform
      _.flags.nix.with_vlang
    ];
    shortDefaultFlags = false;
    script = h:
      ''
        directory="$(pwd | ${_.sed} 's#.*/##')"
        jacobi=$(${final.nix_hash_jpetrucciani}/bin/nix_hash_jpetrucciani 2>/dev/null);
        rev=$(echo "$jacobi" | ${lib.getExe final.jaq} -r '.rev')
        sha=$(echo "$jacobi" | ${lib.getExe final.jaq} -r '.sha256')
        toplevel=""
        _env="pkgs.buildEnv {${"\n"} inherit name paths; buildInputs = paths; };"
        crystal=""
        if [ "$with_crystal" = "1" ]; then
          crystal="crystal = [crystal_1_2${"\n"}shards];"
        fi
        pg=""
        if [ "$with_db_pg" = "1" ]; then
          pg="pg = __pg { postgres = pg; };${"\n"}pg_bootstrap = __pg_bootstrap { inherit name; postgres = pg; };${"\n"}pg_shell = __pg_shell { inherit name; postgres = pg; };"
          toplevel="pg = pkgs.postgresql_15;${"\n"}$toplevel"
        fi
        redis=""
        if [ "$with_db_redis" = "1" ]; then
          redis="rd = __rd;${"\n"}rd_shell = __rd_shell;"
        fi
        elixir=""
        if [ "$with_elixir" = "1" ]; then
          elixir="elixir = [elixir${"\n"}(with beamPackages; [${"\n"}hex])(ifIsLinux [inotify-tools]) (ifIsDarwin [ terminal-notifier (with darwin.apple_sdk_11_0.frameworks; [ CoreFoundation CoreServices ])])];"
          toplevel="inherit (pkgs.hax) ifIsLinux ifIsDarwin;${"\n"}$toplevel"
        fi
        golang=""
        if [ "$with_golang" = "1" ]; then
          golang="go = [go${"\n"}go-tools gopls];"
        fi
        nim=""
        if [ "$with_nim" = "1" ]; then
          nim="nim = [(nim2.withPackages (p: with p; []))];"
        fi
        node=""
        if [ "$with_node" = "1" ]; then
          toplevel="node = pkgs.nodejs_20;${"\n"}$toplevel"
          node="node = [node];npm = with node.pkgs; [prettier${"\n"}yarn];"
        fi
        php=""
        if [ "$with_php" = "1" ]; then
          php="php = [php82];"
        fi
        pulumi=""
        if [ "$with_pulumi" = "1" ]; then
          py="python = [(python311.withPackages ( p: with p; [${"\n"}pulumi]))];"
          pulumi="pulumi = [pulumi];"
        fi
        py=""
        if [ "$with_python" = "1" ]; then
          py="python = [ruff${"\n"}(python311.withPackages ( p: with p; [${"\n"}black]))];"
        fi
        poetry=""
        if [ "$with_poetry" = "1" ]; then
          py="python = [ruff${"\n"}black poetry];"
          poetry="python = (pkgs.poetry2nix.mkPoetryEnv { ${"\n"}projectDir = ./.; python = pkgs.python312; overrides = pkgs.poetry2nix.overrides.withDefaults (final: prev: { }); preferWheels = true; }).overrideAttrs (old: { buildInputs = with pkgs; [ libcxx ]; });${"\n"}"
          _env="python.env.overrideAttrs (_: {${"\n"} buildInputs = paths; });"
        fi
        ruby=""
        if [ "$with_ruby" = "1" ]; then
          ruby="ruby = [(ruby_3_2.withPackages ( p: with p; []))${"\n"}sqlite];"
        fi
        rust=""
        if [ "$with_rust" = "1" ]; then
          rust="rust = [cargo${"\n"}clang rust-analyzer rustc rustfmt];"
        fi
        terraform=""
        if [ "$with_terraform" = "1" ]; then
          terraform="terraform = [terraform${"\n"}terraform-ls terrascan tfsec];"
        fi
        vlang=""
        if [ "$with_vlang" = "1" ]; then
          vlang="vlang = [(vlang.withPackages (p: with p; []))];"
        fi
        ftb="fetchTarball { name = \"jpetrucciani-$(date '+%F')\"; url = \"https://github.com/jpetrucciani/nix/archive/$rev.tar.gz\"; sha256 = \"$sha\";}"
        if ${h.flag "update"}; then
          default_nix="''${1:-./default.nix}"
          ${h.file.notExists "default_nix"} && die "the nix file to update ('$default_nix') does not exist!"
          echo "updating '$default_nix' to '$rev'"
          ${_.sed} -i -E -z "s#(fetchTarball[\s]*).*(\/jpetrucciani\/|nix\.cobi\.dev\/)[^\}]*\}#$ftb#g" "$default_nix"
          ${_.sed} -i -E 's#(fetchTarball \{) (name)#\1\n\2#' "$default_nix"
          ${_.nixpkgs-fmt} "$default_nix" 2>/dev/null
          exit 0
        fi
        ${prev.coreutils}/bin/cat -s <<EOF | ${_.sed} -E 's#(fetchTarball \{) (name)#\1\n\2#' | ${_.nixpkgs-fmt}
          { pkgs ? import
              (''${ftb}) {}
          }:
          let
            name = "$directory";
            ''${toplevel}
            ''${poetry}
            tools = with pkgs; {
              cli = [
                coreutils
                nixpkgs-fmt
              ];
              ''${crystal} ''${elixir} ''${golang} ''${nim} ''${node} ''${php} ''${pulumi} ''${py} ''${ruby} ''${rust} ''${terraform} ''${vlang}
              scripts = pkgs.lib.attrsets.attrValues scripts;
            };

          scripts = with pkgs; {''${pg} ''${redis}};
          paths = pkgs.lib.flatten [ (builtins.attrValues tools) ];
          env = ''${_env}
          in
          (env.overrideAttrs (_: {
            inherit name;
            NIXUP = "${version}";
          })) // {inherit scripts;}
        EOF
      '';
  };

  y2n = final.writeBashBinChecked "y2n" ''
    yaml="$1"
    json=$(${_.y2j} "$yaml") \
      nix eval --raw --impure --expr \
      'with import ${final.pkgs.path} {}; lib.generators.toPretty {} (builtins.fromJSON (builtins.getEnv "json"))'
  '';

  cache = pog {
    name = "cache";
    description = "an easy tool to build nix configs and cache them to cachix!";
    flags = [
      {
        name = "cache_name";
        description = "the cachix to push to";
        default = "medable";
      }
      {
        name = "oldmac";
        description = "optionally build for x86_64-darwin (mac only)";
        bool = true;
      }
    ];
    script = ''
      ${final._._nix}/bin/nix-build ''${oldmac:+--system x86_64-darwin} | ${_.cachix} push "$cache_name"
    '';
  };

  nixrender =
    pog {
      name = "nixrender";
      description = "a quick and easy way to use nix to render various other config files!";
      flags = [ ];
      arguments = [
        { name = "nix_file"; }
      ];
      script = ''
        template="$1"
        rendered="$(${final._._nix}/bin/nix eval --raw -f "$template")"
        echo "$rendered"
      '';
    };

  hexcast =
    let
      _ = {
        inherit (final._) realpath sed yq;
        prettier = "${final.nodePackages.prettier}/bin/prettier --write --config ${../../prettier.config.js}";
        mktemp = "${final.coreutils}/bin/mktemp --suffix=.yaml";
        nix = "${final._._nix}/bin/nix";
      };
    in
    pog {
      name = "hexcast";
      version = "0.0.4";
      description = "a quick and easy way to use nix to render (cast) various other types of config files!";
      flags = [
        {
          name = "format";
          description = "the output format to use. use either yaml or json!";
          default = "yaml";
        }
        {
          name = "crds";
          description = "filter to only the crds (k8s specific)";
          bool = true;
        }
      ];
      arguments = [{ name = "nix_file"; }];
      script = helpers: with helpers; ''
        ${var.notEmpty "1"} && spell="$1"
        ${var.empty "spell"} && spell="$(${_.mktemp})" && cp /dev/stdin "$spell"
        spell_render="$(${_.mktemp})"
        fullpath="$(${_.realpath} "$spell")"
        debug "casting $fullpath - hex files at ${./hex}"
        ${_.nix} eval --raw --impure --expr "import ${./hex}/spell.nix ${prev.path} \"$fullpath\"" >"$spell_render"
        debug "formatting $spell_render"
        ${_.prettier} --parser "$format" "$spell_render" &>/dev/null
        debug "removing blank docs in $spell_render"
        # remove empty docs
        ${_.sed} -E -z -i 's#---(\n+---)*#---#g' "$spell_render"
        ${flag "crds"} && ${_.yq} e -i '. | select(.kind == "CustomResourceDefinition")' "$spell_render"
        cat "$spell_render"
      '';
    };

  hex = pog {
    name = "hex";
    version = "0.0.5";
    description = "a quick and easy way to render full kubespecs from nix files";
    flags = [
      {
        name = "target";
        description = "the file to render specs from";
        default = "./specs.nix";
      }
      {
        name = "dryrun";
        description = "just run the diff, don't prompt to apply";
        bool = true;
      }
      {
        name = "render";
        description = "only render and patch, do not diff or apply";
        bool = true;
      }
      # {
      #   name = "check";
      #   description = "whether to check the hex for deprecations";
      #   bool = true;
      # }
      {
        name = "crds";
        description = "filter down to just the CRDs (useful for initial deployments)";
        bool = true;
      }
      {
        name = "clientside";
        description = "run the diff on the clientside instead of serverside";
        short = "";
        bool = true;
      }
      {
        name = "prettify";
        description = "whether to run prettier on the hex output yaml";
        bool = true;
      }
      {
        name = "force";
        description = "force apply the resulting hex without a diff (WARNING - BE CAREFUL)";
        bool = true;
      }
      {
        name = "evaluate";
        description = "evaluate an in-line hex script";
      }
    ];
    script =
      let
        steps = {
          render = "render";
          patch = "patch";
          diff = "diff";
          apply = "apply";
        };
        _ = {
          k = lib.getExe' final.kubectl "kubectl";
          hc = lib.getExe hexcast;
          delta = lib.getExe' final.delta "delta";
          mktemp = "${final.coreutils}/bin/mktemp";
          prettier = "${final.nodePackages.prettier}/bin/prettier --write --config ${../../prettier.config.js}";
        };
      in
      helpers: with helpers; ''
        export USE_GKE_GCLOUD_AUTH_PLUGIN=True
        if ${var.notEmpty "evaluate"}; then
          target=$(${_.mktemp})
          cat <<EOF >"$target"
          {hex, pkgs}:
          $evaluate
        EOF
        fi
        side="true"
        ${flag "clientside"} && side="false"
        ${file.notExists "target"} && die "the file to render ('$target') does not exist!"
        rendered=$(${_.mktemp})
        diffed=$(${_.mktemp})
        debug "''${GREEN}render to '$rendered'"
        ${timer.start steps.render}
        ${_.hc} ''${crds:+--crds} "$target" >"$rendered"
        render_exit_code=$?
        render_runtime=${timer.stop steps.render}
        debug "''${GREEN}rendered to '$rendered' in $render_runtime''${RESET}"
        if [ $render_exit_code -ne 0 ]; then
          die "nixrender failed!" 2
        fi
        ${flag "prettify"} && ${_.prettier} --parser yaml "$rendered" >/dev/null
        if ${flag "render"}; then
          cat "$rendered"
          exit 0
        fi
        if ${flag "force"}; then
          ${timer.start steps.apply}
          ${_.k} apply --force-conflicts --server-side="$side" -f "$rendered"
          apply_runtime=${timer.stop steps.apply}
          debug "''${GREEN}force applied '$rendered' in $apply_runtime''${RESET}"
          exit 0
        fi
        ${timer.start steps.diff}
        ${_.k} diff --force-conflicts --server-side="$side" -f "$rendered" >"$diffed"
        diff_exit_code=$?
        diff_runtime=${timer.stop steps.diff}
        debug "''${GREEN}diffed '$rendered' to '$diffed' in $diff_runtime [exit code $diff_exit_code]''${RESET}"
        if [ $diff_exit_code -ne 0 ] && [ $diff_exit_code -ne 1 ]; then
          die "diff of hex failed!" 3
        fi
        if [ -s "$diffed" ]; then
          debug "''${GREEN}changes detected!''${RESET}"
        else
          blue "no changes in hex detected!"
          exit 0
        fi
        ${_.delta} <"$diffed"
        ${flag "dryrun"} && exit 0
        echo "---"
        ${confirm {prompt="Would you like to apply these changes?";}}
        echo "---"
        ${timer.start steps.apply}
        ${_.k} apply --force-conflicts --server-side="$side" -f "$rendered"
        apply_runtime=${timer.stop steps.apply}
        debug "''${GREEN}applied '$rendered' in $apply_runtime''${RESET}"
      '';
  };

  nixsum = pog {
    name = "nixsum";
    description = "my lazy helper function to summarize a dir of nix scripts";
    flags = [
      {
        name = "extensions";
        description = "pipe separated list of extensions to use in the summary";
        default = "nix";
      }
      {
        name = "depth";
        description = "how deep to search";
        default = "1";
      }
    ];
    script = ''
      files=$(${_.find} . -maxdepth "$depth" -regextype posix-egrep -regex "\./.*\.($extensions)" | ${_.sort})
      for f in $files; do
          echo -e "### [''${f:2}]($f)\n"
          top=$(${_.grep} "^#" "$f" | ${_.head} -1)
          echo -e "''${top:2}\n"
      done
    '';
  };

  nixcache = pog {
    name = "nixcache";
    description = "a way to cache one or more builds into s3";
    flags = [
      {
        name = "uri";
        description = "the cache uri to copy to (example: s3://nix-cache?region=us-east-2&compression=zstd)";
      }
    ];
    script = ''
      files=( "$@" )
      echo "caching $# builds"
      rm -f ./nixcache.log
      for i in $(${prev.coreutils}/bin/seq $#); do
          index=$((i-1))
          ${prev.nix}/bin/nix copy --refresh --to "$uri" "''${files[$index]}" >>nixcache.log
          echo "$i"
      done | ${prev.python311Packages.tqdm}/bin/tqdm --total "$#" >>/dev/null
      echo "cached $# builds!"
    '';
  };

  nupdate = pog {
    name = "nupdate";
    arguments = [{ name = "attribute"; }];
    description = "my lazy helper function to update an attribute in my nix repo";
    script = ''
      ${prev.nix-update}/bin/nix-update --build --commit --flake --format --use-update-script "$@"
    '';
  };

  ndiff = pog {
    name = "ndiff";
    arguments = [{ name = "attribute"; }];
    flags = [
      { name = "nixpkgs"; default = final.nixpkgsRev; }
    ];
    script = helpers: with helpers; ''
      attribute="$1"
      ${var.empty "attribute"} && die "no attribute specified to diff!"
      ${prev.nvd}/bin/nvd diff \
        "$(${final._._nix}/bin/nix eval --raw "github:NixOS/nixpkgs/$nixpkgs#$attribute.drvPath")" \
        "$(${final._._nix}/bin/nix eval --raw "github:jpetrucciani/nix#$attribute.drvPath")"
    '';
  };

  nix_pog_scripts = [
    cache
    hex
    hexcast
    ndiff
    nixrender
    nixup
    nixsum
    nixcache
    nupdate
    y2n
  ];
}
