# This module configures some helper tools for creating new nix environments!
final: prev:
let
  inherit (final) _ pog lib;
in
rec {
  nixup =
    let
      version = "0.0.8";
      _flags = {
        with_crystal = "include crystal with dependencies";
        with_db_pg = "include postgres db and helper scripts";
        with_db_redis = "include redis db and helper scripts";
        with_dotnet = "include dotnet and the required libs";
        with_elixir = "include elixir with dependencies";
        with_golang = "include golang";
        with_java = "include a jvm and some basics";
        with_nim = "include a nim with dependencies";
        with_node = "include node";
        with_php = "include a php with packages";
        with_poetry = "include python using poetry2nix";
        with_pulumi = "include pulumi";
        with_python = "include a python with packages";
        with_ruby = "include ruby";
        with_rust = "include rust";
        with_terraform = "include terraform";
        # with_uv = "include python and uv";
        with_vlang = "include a vlang with dependencies";
        with_nvidia = "include some ld hacks to get nvidia drivers working (only useful on nixos/wsl)";
      };
      flags = lib.mapAttrsToList (k: v: { name = k; description = v; short = ""; bool = true; }) _flags;
    in
    pog {
      inherit version;
      name = "nixup";
      description = "a quick tool to create/update a base default.nix environment!";
      flags = [
        { name = "srcpath"; description = "the fs path to import pkgs from if passed. if not passed in, will pin to the latest version of jpetrucciani/nix"; }
        { name = "update"; bool = true; description = "update the pin to jpetrucciani in the given file (argument 1) [default: ./default.nix]"; }
      ] ++ flags;
      shortDefaultFlags = false;
      script = h:
        ''
          directory="$(pwd | ${_.sed} 's#.*/##')"
          jacobi=$(${final.nix_hash_jpetrucciani}/bin/nix_hash_jpetrucciani 2>/dev/null);
          rev=$(echo "$jacobi" | ${lib.getExe final.jaq} -r '.rev')
          sha=$(echo "$jacobi" | ${lib.getExe final.jaq} -r '.sha256')
          toplevel=""
          _env="pkgs.buildEnv {${"\n"} inherit name paths; buildInputs = paths; };"
          extra_env=""
          crystal=""
          if [ "$with_crystal" = "1" ]; then
            crystal="crystal = [crystal${"\n"}shards];"
          fi
          pg=""
          if [ "$with_db_pg" = "1" ]; then
            pg="pg = __pg { postgres = pg; };${"\n"}pg_bootstrap = __pg_bootstrap { inherit name; postgres = pg; };${"\n"}pg_shell = __pg_shell { inherit name; postgres = pg; };"
            toplevel="pg = pkgs.postgresql_16;${"\n"}$toplevel"
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
          fi
          nim=""
          if [ "$with_nim" = "1" ]; then
            nim="nim = [(nim2.withPackages (p: with p; []))];"
          fi
          node=""
          if [ "$with_node" = "1" ]; then
            toplevel="node = pkgs.nodejs_22;${"\n"}$toplevel"
            node="node = [node];npm = with node.pkgs; [prettier${"\n"}yarn];"
          fi
          php=""
          if [ "$with_php" = "1" ]; then
            php="php = [php83];"
          fi
          dotnet=""
          if [ "$with_dotnet" = "1" ]; then
            dotnet="dotnet = [clang${"\n"}dotnet-sdk_8 dotnetPackages.Nuget netcoredbg zlib];"
            extra_env="$extra_env DOTNET_CLI_TELEMETRY_OPTOUT = 1; DOTNET_ROOT = \"\''${pkgs.dotnet-sdk_8}\";"
          fi
          pulumi=""
          if [ "$with_pulumi" = "1" ]; then
            py="python = [(python312.withPackages ( p: with p; [${"\n"}pulumi]))];"
            pulumi="pulumi = [pulumi];"
          fi
          py=""
          if [ "$with_python" = "1" ]; then
            py="python = [ruff${"\n"}(python311.withPackages ( p: with p; [${"\n"}black]))];"
          fi
          poetry=""
          if [ "$with_poetry" = "1" ]; then
            py="python = [ruff${"\n"}(poetry.override (_: { python3 = python312; }))];"
            poetry="python = pkgs.poetry-helpers.mkEnv {${"\n"}projectDir = ./.; python = pkgs.python312; extraOverrides = [(final: prev: { })];};${"\n"}"
            _env="python.env.overrideAttrs (_: {${"\n"} buildInputs = paths; });"
          fi
          ruby=""
          if [ "$with_ruby" = "1" ]; then
            ruby="ruby = [(ruby_3_2.withPackages ( p: with p; []))${"\n"}sqlite];"
          fi
          rust=""
          if [ "$with_rust" = "1" ]; then
            rust="rust = [cargo${"\n"}clang rust-analyzer rustc rustfmt${"\n"}# deps${"\n"}pkg-config openssl];"
          fi
          terraform=""
          if [ "$with_terraform" = "1" ]; then
            terraform="terraform = [terraform${"\n"}terraform-ls terrascan tfsec];"
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
            toplevel="deps = with pkgs; [${"\n"}cudaPackages.cudatoolkit stdenv.cc.cc.lib ];${"\n"}$toplevel"
            extra_env="$extra_env LD_LIBRARY_PATH = \"\''${pkgs.hax.nvidiaLdPath}:\''${pkgs.lib.makeLibraryPath deps}\";${"\n"}CUDA_PATH = pkgs.cudatoolkit;"
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
          if ${h.var.notEmpty "srcpath"}; then
            ftb="$srcpath"
          fi
          ${prev.coreutils}/bin/cat -s <<EOF | ${_.sed} -E 's#(fetchTarball \{) (name)#\1\n\2#' | ${_.nixpkgs-fmt}
            { pkgs ? import
                (''${ftb}) {}
            }:
            let
              name = "$directory";

              ''${toplevel} ''${poetry}
              tools = with pkgs; {
                cli = [
                  jfmt
                  nixup
                ]; ''${crystal} ''${elixir} ''${golang} ''${nim} ''${node} ''${php} ''${dotnet} ''${java} ''${pulumi} ''${py} ''${ruby} ''${rust} ''${terraform} ''${vlang}
                scripts = pkgs.lib.attrsets.attrValues scripts;
              };

            scripts = with pkgs; {''${pg} ''${redis}};
            paths = pkgs.lib.flatten [ (builtins.attrValues tools) ];
            env = ''${_env}
            in
            (env.overrideAttrs (_: {
              inherit name;
              NIXUP = "${version}"; $extra_env
            })) // {inherit scripts;}
          EOF
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
      ${prev.nix-update}/bin/nix-update --build --flake --use-update-script "$@"
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
      ${prev.nix-update}/bin/nix-update --build --flake --version="$latest_tag" "$@"
    '';
  };

  #  get_latest = "${curl}/bin/curl https://api.github.com/repos/supabase/cli/releases/latest | ${jq}/bin/jq '.tag_name'";

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
        "$(${final._nix}/bin/nix eval --raw "github:NixOS/nixpkgs/$nixpkgs#$attribute.drvPath")" \
        "$(${final._nix}/bin/nix eval --raw "github:jpetrucciani/nix#$attribute.drvPath")"
    '';
  };

  nix_pog_scripts = [
    prev.hex
    prev.hexcast
    prev.nixrender
    cache
    ndiff
    nixup
    nixsum
    nixcache
    nupdate
    nupdate_latest_github
    y2n
  ];
}
