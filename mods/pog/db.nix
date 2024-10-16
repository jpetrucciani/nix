# this set of pog scripts allows us to use postgres, redis, etc. in local dev environments via nix
final: prev:
with prev;
let
  flags = {
    redis_port = {
      name = "port";
      envVar = "REDIS_PORT";
      default = "6379";
      description = "port that redis lives on";
    };
  };
in
rec {
  __pg_bootstrap =
    { name ? "db"
    , db_name ? name
    , password ? name
    , extensions ? [ "pgcrypto" "uuid-ossp" ]
    , postgres ? postgresql_15
    , extra_bootstrap ? ""
    }: pog {
      name = "__pg_bootstrap";
      description = "a quick and easy way to bootstrap a local postgres db";
      script =
        let
          pg_ctl = ''${postgres}/bin/pg_ctl -o "-k '$PGDATA'" -D "$PGDATA"'';
          _psql = x: ''${postgres}/bin/psql -d ${x} -h localhost -p "$PGPORT" -c'';
          psql = _psql "postgres";
          psql_db = _psql db_name;
          create_db = ''CREATE DATABASE \"${db_name}\";'';
          create_ext = builtins.concatStringsSep "\n" (map (x: ''CREATE EXTENSION IF NOT EXISTS \"${x}\";'') extensions);
          create_user = ''
            CREATE USER \"${name}\" WITH ENCRYPTED PASSWORD '${password}';
            GRANT ALL PRIVILEGES ON DATABASE \"${db_name}\" TO \"${name}\";
            ALTER USER \"${name}\" CREATEDB;
          '';
          grant_schema = ''
            GRANT ALL ON SCHEMA public TO \"${name}\";
          '';
        in
        ''
          bootstrap() {
            ${postgres}/bin/initdb -E UTF8 "$PGDATA"
            ${pg_ctl} start
            ${psql} "${create_db}"
            ${psql} "${create_ext}"
            ${psql} "${create_user}"
            ${psql_db} "${create_ext}"
            ${psql_db} "${grant_schema}"
            ${extra_bootstrap}
            ${pg_ctl} stop
          }
          [ ! -d "$PGDATA" ] && bootstrap
        '';
    };
  __pg = { postgres ? postgresql_15, extra_flags ? "" }: pog {
    name = "__pg";
    description = "run your local postgres db from $PGDATA";
    script = ''${postgres}/bin/postgres -k "$PGDATA" -D "$PGDATA" -p "$PGPORT" ${extra_flags}'';
  };
  __pg_shell = { name ? "db", postgres ? postgresql_15, extra_flags ? "" }: pog {
    name = "__pg_shell";
    description = "run a psql shell into postgres locally";
    script = ''${final.portwatch}/bin/portwatch "$PGPORT" && ${postgres}/bin/psql -h localhost -p "$PGPORT" -U ${name} -d ${name} ${extra_flags}'';
  };

  __rd = pog {
    name = "__rd";
    description = "run your local redis db";
    flags = [
      flags.redis_port
    ];
    script = ''
      ${redis}/bin/redis-server --port "$port"
    '';
  };
  __rd_shell = pog {
    name = "__rd_shell";
    description = "run your local redis db";
    flags = [
      flags.redis_port
    ];
    script = ''
      ${final.portwatch}/bin/portwatch "$port" && ${redis}/bin/redis-cli -p "$port"
    '';
  };

  __run =
    { name ? "run"
    , pre ? ""
    , post ? ""
    , procfile ? "Procfile"
    , title ? name
    , root ? null
    , description ? "a quick and easy service orchestrator!"
    , overmindPort ? 4322
    , overmind ? pkgs.overmind
    , bash ? pkgs.bashInteractive
    , tmux ? pkgs.tmux
    , tmuxConfig ? ./resources/tmux.conf
    , sleepHack ? 0.2
    }:
    let
      o = "${overmind}/bin/overmind";
      chroot = if root != null then ''--root "${root}"'' else "";
    in
    pog {
      inherit name description;
      script = ''
        export OVERMIND_NO_PORT="1"
        export OVERMIND_SOCKET=":${toString overmindPort}"
        export OVERMIND_NETWORK="tcp"
        export OVERMIND_TMUX_CONFIG=${tmuxConfig}
        export PATH="${tmux}/bin/:$PATH"
        ${pre}
        ${o} start ${chroot} --procfile ${procfile} --title "${title}" --shell ${bash}/bin/bash -D
        sleep ${toString sleepHack} # this is a hack to stop overmind from crashing?
        ${o} connect
        ${post}
      '';
    };

  __rabbitmq =
    { port ? 5672
    , managementPort ? 15672
    , guest ? true
    , extraConfig ? ""
    , plugins ? [ ]
    , defaultPlugins ? [ "rabbitmq_management" "rabbitmq_shovel" "rabbitmq_shovel_management" ]
    , extraPluginDirs ? [ ]
    }:
    let
      config = writeTextFile {
        name = "__rabbitmq.conf";
        text = ''
          loopback_users.guest = ${pkgs.lib.boolToString guest}
          listeners.tcp.default = ${toString port}
          management.listener.port = ${toString managementPort}
          management.listener.ssl = false
          ${extraConfig}
        '';
      };
      enabledPlugins = writeTextFile {
        name = "__rabbitmq_plugins";
        text = ''
          [ ${builtins.concatStringsSep "," _plugins} ].
        '';
      };
      _plugins = plugins ++ defaultPlugins;
      _pluginDirs = [ "${rabbitmq-server}/plugins" ] ++ extraPluginDirs;
      pluginDirs = builtins.concatStringsSep ":" _pluginDirs;
    in
    pog {
      name = "__rabbitmq";
      description = "";
      script = ''
        export RABBIT_DATA="''${RABBIT_DATA:-.rabbitmq}"
        export RABBIT_PLUGINS="''${RABBIT_PLUGINS:-''${RABBIT_DATA}/plugins}"
        ${pkgs.coreutils}/bin/mkdir -p "$RABBIT_DATA" "$RABBIT_PLUGINS"
        export RABBITMQ_MNESIA_BASE="$RABBIT_DATA"
        export RABBITMQ_LOG_BASE="$RABBIT_DATA/logs"
        export RABBITMQ_CONFIG_FILE="${config}"
        export RABBITMQ_ENABLED_PLUGINS_FILE="${enabledPlugins}"
        export RABBITMQ_PLUGINS_DIR="$RABBIT_PLUGINS:${pluginDirs}"
        ${rabbitmq-server}/bin/rabbitmq-server
      '';
    };

  db_pog_scripts = [
    # postgres
    (__pg { })
    (__pg_bootstrap { })
    (__pg_shell { })
    # redis
    __rd
    __rd_shell
    # magic run helper
    (__run { })
    # queues
    (__rabbitmq { })
  ];
}
