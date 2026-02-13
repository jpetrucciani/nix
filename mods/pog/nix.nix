# This module configures some helper tools for creating new nix environments!
final: prev:
let
  inherit (final) _ pog lib;
  gitignore = import ./ignore.nix;
in
rec {
  nixup =
    let
      version = "0.0.10";
      _flags = {
        with_bun = "include bun with dependencies";
        with_crystal = "include crystal with dependencies";
        with_db_pg = "include postgres db and helper scripts";
        with_db_redis = "include redis db and helper scripts";
        with_dotnet = "include dotnet and the required libs";
        with_elixir = "include elixir with dependencies";
        with_golang = "include golang";
        with_java = "include a jvm and some basics";
        with_nim = "include a nim with dependencies";
        with_node = "include node";
        with_ocaml = "include an ocaml environment";
        with_php = "include a php with packages";
        with_poetry = "include python using poetry2nix";
        with_pulumi = "include pulumi";
        with_python = "include a python with packages";
        with_ruby = "include ruby";
        with_rust = "include rust";
        with_terraform = "include terraform";
        with_uv = "include python using uv2nix";
        with_vlang = "include a vlang with dependencies";
        with_nvidia = "include some ld hacks to get nvidia drivers working (only useful on nixos/wsl)";
      };
      flags = lib.mapAttrsToList (k: v: { name = k; description = v; short = ""; bool = true; }) _flags;
      jaq = lib.getExe final.jaq;
    in
    pog {
      inherit version;
      name = "nixup";
      description = "a quick tool to create/update a base default.nix environment! will also attempt to make you a baseline gitignore";
      flags = [
        { name = "srcpath"; description = "the fs path to import pkgs from if passed. if not passed in, will pin to the latest version of jpetrucciani/nix"; }
        { name = "update"; bool = true; description = "update the pin to jpetrucciani in the given file (argument 1) [default: ./default.nix]"; }
        { name = "repo"; description = "GitHub repo to pin (format: owner/repo)"; default = "jpetrucciani/nix"; }
        { name = "branch"; description = "Branch to pin to"; default = "main"; }
      ] ++ flags;
      shortDefaultFlags = false;
      script = h:
        ''
          directory="$(pwd | ${_.sed} 's#.*/##')"
          repo_owner=$(echo "$repo" | cut -d'/' -f1)
          repo_name=$(echo "$repo" | cut -d'/' -f2)
          remote=$(${final.nix_hash}/bin/nix_hash --repo "$repo" --branch "$branch" 2>/dev/null);
          rev=$(echo "$remote" | ${jaq} -r '.rev')
          sha=$(echo "$remote" | ${jaq} -r '.sha256')
          toplevel=""
          _env="pkgs.buildEnv {${"\n"} inherit name paths; buildInputs = paths; };"
          extra_env=""
          extra_env_overrides=""
          gitignore="${gitignore.nix}"
          crystal=""
          if [ "$with_crystal" = "1" ]; then
            crystal="crystal = [crystal${"\n"}shards];"
            gitignore="$gitignore${"\n"}# crystal${"\n"}${gitignore.crystal}"
          fi
          pg=""
          if [ "$with_db_pg" = "1" ]; then
            pg="pg = __pg { postgres = pg; };${"\n"}pg_bootstrap = __pg_bootstrap { inherit name; postgres = pg; };${"\n"}pg_shell = __pg_shell { inherit name; postgres = pg; };"
            toplevel="pg = pkgs.postgresql_16.withPackages (p: with p; [pgvector]);${"\n"}$toplevel"
          fi
          redis=""
          if [ "$with_db_redis" = "1" ]; then
            redis="rd = __rd;${"\n"}rd_shell = __rd_shell;"
          fi
          elixir=""
          if [ "$with_elixir" = "1" ]; then
            elixir="elixir = [elixir${"\n"}(with beamPackages; [${"\n"}hex])(ifIsLinux [inotify-tools]) (ifIsDarwin [ terminal-notifier (with darwin.apple_sdk_12_3.frameworks; [ CoreFoundation CoreServices ])])];"
            toplevel="inherit (pkgs.hax) ifIsLinux ifIsDarwin;${"\n"}$toplevel"
          fi
          golang=""
          if [ "$with_golang" = "1" ]; then
            golang="go = [go${"\n"}go-tools gopls];"
            gitignore="$gitignore${"\n"}# go${"\n"}${gitignore.go}"
          fi
          nim=""
          if [ "$with_nim" = "1" ]; then
            nim="nim = [(nim.withPackages (p: with p; [])) nimble];"
            gitignore="$gitignore${"\n"}# nim${"\n"}${gitignore.nim}"
          fi
          bun=""
          if [ "$with_bun" = "1" ]; then
            bun="bun = [bun];"
            gitignore="$gitignore${"\n"}# bun${"\n"}${gitignore.node}"
          fi
          node=""
          if [ "$with_node" = "1" ]; then
            toplevel="node = pkgs.nodejs_22;${"\n"}$toplevel"
            node="node = [node];npm = with node.pkgs; [prettier];"
            gitignore="$gitignore${"\n"}# node${"\n"}${gitignore.node}"
          fi
          php=""
          if [ "$with_php" = "1" ]; then
            php="php = [php83];"
          fi
          dotnet=""
          if [ "$with_dotnet" = "1" ]; then
            dotnet="dotnet = [clang${"\n"}dotnet-sdk_9 dotnet-runtime_9 dotnetPackages.Nuget netcoredbg zlib];"
            extra_env="$extra_env DOTNET_CLI_TELEMETRY_OPTOUT = 1; DOTNET_ROOT = \"\''${pkgs.dotnet-sdk_9}\";"
          fi
          ocaml=""
          if [ "$with_ocaml" = "1" ]; then
            ocaml="ocaml = [bintools${"\n"}clang] ++ (with ocamlPackages; [dream${"\n"}dune_3 findlib ocaml ocaml-lsp ocamlformat]);"
          fi
          pulumi=""
          if [ "$with_pulumi" = "1" ]; then
            py="python = [(python314.withPackages ( p: with p; [${"\n"}pulumi]))];"
            pulumi="pulumi = [pulumi];"
          fi
          py=""
          if [ "$with_python" = "1" ]; then
            py="python = [ruff${"\n"}(python314.withPackages ( p: with p; [${"\n"}black]))];"
            gitignore="$gitignore${"\n"}# python${"\n"}${gitignore.python}"
          fi
          poetry=""
          if [ "$with_poetry" = "1" ]; then
            py="python = [ruff${"\n"}(poetry.override (_: { python3 = python314; }))];"
            poetry="python = pkgs.poetry-helpers.mkEnv {${"\n"}projectDir = ./.; python = pkgs.python314; extraOverrides = [(final: prev: { })];};${"\n"}"
            _env="python.env.overrideAttrs (_: {${"\n"} buildInputs = paths; });"
            gitignore="$gitignore${"\n"}# python${"\n"}${gitignore.python}"
          fi
          ruby=""
          if [ "$with_ruby" = "1" ]; then
            ruby="ruby = [(ruby_3_2.withPackages ( p: with p; []))${"\n"}sqlite];"
          fi
          rust=""
          if [ "$with_rust" = "1" ]; then
            rust="rust = [cargo${"\n"}clang rust-analyzer rustc rustfmt${"\n"}# deps${"\n"}pkg-config openssl];"
            gitignore="$gitignore${"\n"}# rust${"\n"}${gitignore.rust}"
          fi
          terraform=""
          if [ "$with_terraform" = "1" ]; then
            terraform="terraform = [terraform${"\n"}terraform-ls terrascan tfsec];"
            gitignore="$gitignore${"\n"}# terraform${"\n"}${gitignore.terraform}${"\n"}"
          fi
          uv=""
          uv_top=""
          if [ "$with_uv" = "1" ]; then
            extra_env_overrides="// uvEnv.uvEnvVars"
            uv="uv = [uv uvEnv];"
            uv_top="uvEnv = pkgs.uv-nix.mkEnv {${"\n"}inherit name; python = pkgs.python314; workspaceRoot = pkgs.hax.filterSrc { path = ./.; }; pyprojectOverrides = final: prev: { }; };${"\n"}"
            gitignore="$gitignore${"\n"}# python${"\n"}${gitignore.python}"
          fi
          vlang=""
          if [ "$with_vlang" = "1" ]; then
            vlang="vlang = [(vlang.withPackages (p: with p; []))];"
          fi
          java=""
          if [ "$with_java" = "1" ]; then
            java="java = [gradle${"\n"}zulu];"
          fi
          if [ "$with_nvidia" = "1" ]; then
            toplevel="deps = with pkgs; [${"\n"}stdenv.cc.cc.lib ] ++ (with cudaPackages; [${"\n"}cudatoolkit]);${"\n"}$toplevel"
            extra_env="$extra_env LD_LIBRARY_PATH = \"\''${pkgs.hax.nvidiaLdPath}:\''${pkgs.lib.makeLibraryPath deps}\";${"\n"}CUDA_PATH = pkgs.cudatoolkit;"
          fi
          ftb="fetchTarball { name = \"$repo_owner-$(date '+%F')\"; url = \"https://github.com/$repo/archive/$rev.tar.gz\"; sha256 = \"$sha\";}"
          if ${h.flag "update"}; then
            default_nix="''${1:-./default.nix}"
            ${h.file.notExists "default_nix"} && die "the nix file to update ('$default_nix') does not exist!"
            echo "updating '$default_nix' to '$repo@$rev'"
            ${_.sed} -i -E -z "s#(fetchTarball[\s]*).*(\/$repo_owner\/$repo_name|nix\.cobi\.dev\/)[^\}]*\}#$ftb#g" "$default_nix"
            ${_.sed} -i -E 's#(fetchTarball \{) (name)#\1\n\2#' "$default_nix"
            ${_.nixpkgs-fmt} "$default_nix" 2>/dev/null
            exit 0
          fi
          if ${h.var.notEmpty "srcpath"}; then
            ftb="$srcpath"
          fi
          ${final.coreutils}/bin/cat -s <<EOF | ${_.sed} -E 's#(fetchTarball \{) (name)#\1\n\2#' | ${_.nixpkgs-fmt}
            { pkgs ? import
                (''${ftb}) {}
            }:
            let
              name = "$directory";
              ''${toplevel} ''${poetry} ''${uv_top}
              tools = with pkgs; {
                cli = [
                  jfmt
                  nixup
                ]; ''${bun} ''${crystal} ''${elixir} ''${golang} ''${nim} ''${node} ''${ocaml} ''${php} ''${dotnet} ''${java} ''${pulumi} ''${py} ''${ruby} ''${rust} ''${terraform} ''${uv} ''${vlang}
                scripts = pkgs.lib.attrsets.attrValues scripts;
              };

            scripts = with pkgs; {''${pg} ''${redis}};
            paths = pkgs.lib.flatten [ (builtins.attrValues tools) ];
            env = ''${_env}
            in
            (env.overrideAttrs (_: {
              inherit name;
              NIXUP = "${version}"; $extra_env
            }''${extra_env_overrides})) // {inherit scripts;}
          EOF
          if [ ! -f .gitignore ]; then
            echo "$gitignore" > .gitignore
          fi
        '';
    };

  y2n = final.hax.writeBashBinChecked "y2n" ''
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
      ${final._nix}/bin/nix-build ''${oldmac:+--system x86_64-darwin} | ${_.cachix} push "$cache_name"
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
      for i in $(${final.coreutils}/bin/seq $#); do
          index=$((i-1))
          ${final._nix}/bin/nix copy --refresh --to "$uri" "''${files[$index]}" >>nixcache.log
          echo "$i"
      done | ${final.python314Packages.tqdm}/bin/tqdm --total "$#" >>/dev/null
      echo "cached $# builds!"
    '';
  };

  nupdate = pog {
    name = "nupdate";
    arguments = [{ name = "attribute"; }];
    description = "my lazy helper function to update an attribute in my nix repo";
    script = ''
      ${final.nix-update}/bin/nix-update --build --flake --use-update-script "$@"
    '';
  };

  nupdate_latest_github = pog {
    name = "nupdate_latest_github";
    arguments = [{ name = "attribute"; }];
    flags = [
      { name = "owner"; description = "the owner of the repo"; }
      { name = "repo"; description = "the repo name"; }
    ];
    description = "";
    script = ''
      latest_tag=$(${final.curl}/bin/curl "https://api.github.com/repos/$owner/$repo/releases/latest" | ${final.jq}/bin/jq -r '.tag_name')
      ${final.nix-update}/bin/nix-update --build --flake --version="$latest_tag" "$@"
    '';
  };

  #  get_latest = "${curl}/bin/curl https://api.github.com/repos/supabase/cli/releases/latest | ${jq}/bin/jq '.tag_name'";

  ndiff = pog {
    name = "ndiff";
    description = "a pog script to diff my repo's attrs vs upstream";
    arguments = [{ name = "attribute"; }];
    flags = [
      { name = "nixpkgs"; default = final.nixpkgsRev; }
    ];
    script = helpers: with helpers; ''
      attribute="$1"
      ${var.empty "attribute"} && die "no attribute specified to diff!"
      ${final.nvd}/bin/nvd diff \
        "$(${final._nix}/bin/nix eval --raw "github:NixOS/nixpkgs/$nixpkgs#$attribute.drvPath")" \
        "$(${final._nix}/bin/nix eval --raw "github:jpetrucciani/nix#$attribute.drvPath")"
    '';
  };

  rehydrate = pog {
    name = "rehydrate";
    description = "a pog script to restore libraries from the nix-store on a binary that's been copied to a new box";
    arguments = [{ name = "binary"; }];
    script = ''
      target="$1"
      paths=$( (${final.patchelf}/bin/patchelf --print-rpath "$target" | ${_.tr} ':' '\n'; ${final.glibc.bin}/bin/ldd "$target" | ${final.gnugrep}/bin/grep -o '/nix/store/[^/ ]*') | ${_.sort} -u)
      for path in $paths; do
          if [ ! -e "$path" ]; then
              echo "fetching missing path: $path"
              ${final._nix}/bin/nix-store -r "$path"
          else
              echo "already exists: $path"
          fi
      done
    '';
  };

  nix_pog_scripts = [
    final.hex
    final.hexcast
    final.nixrender
    cache
    ndiff
    nixup
    nixsum
    nixcache
    nupdate
    nupdate_latest_github
    # rehydrate
    y2n
  ];
}
