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
  db_init_hack = ''export LD_PRELOAD="${final.getpwuid_hack}/lib/libpwuid_override.so" '';
  LOCALE_ARCHIVE_2_27 = "${final.glibcLocales}/lib/locale/locale-archive";
in
rec {
  __pg_bootstrap =
    { name ? "db"
    , db_name ? name
    , password ? name
    , extensions ? [ "pgcrypto" "uuid-ossp" ]
    , postgres ? postgresql_16
    , hackDbInit ? false
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
          export LOCALE_ARCHIVE_2_27=${LOCALE_ARCHIVE_2_27}
          bootstrap() {
            ${if hackDbInit then db_init_hack else ""}
            ${postgres}/bin/initdb -E UTF8 "$PGDATA"
            unset LD_PRELOAD
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
  __pg = { postgres ? postgresql_16, extra_flags ? "" }: pog {
    name = "__pg";
    description = "run your local postgres db from $PGDATA";
    script = ''
      export LOCALE_ARCHIVE_2_27=${LOCALE_ARCHIVE_2_27}
      ${postgres}/bin/postgres -k "$PGDATA" -D "$PGDATA" -p "$PGPORT" ${extra_flags}
    '';
  };
  __pg_shell = { name ? "db", postgres ? postgresql_16, extra_flags ? "" }: pog {
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

  __vk = pog {
    name = "__vk";
    description = "run your local valkey db";
    flags = [
      flags.redis_port
    ];
    script = ''
      ${valkey}/bin/valkey-server --port "$port"
    '';
  };
  __vk_shell = pog {
    name = "__vk_shell";
    description = "run your local valkey db";
    flags = [
      flags.redis_port
    ];
    script = ''
      ${final.portwatch}/bin/portwatch "$port" && ${valkey}/bin/valkey-cli -p "$port"
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

  __mysql_bootstrap =
    { name ? "db"
    , mysql ? mysql84
    , extra_bootstrap ? ""
    , extra_bootstrap_sql ? ""
    , mysql_settings ? {
        mysqld = {
          bind-address = "0.0.0.0";
          port = 3306;
          innodb_numa_interleave = "0";
        };
      }
    }: pog {
      name = "__mysql_bootstrap";
      description = "a quick and easy way to bootstrap a local mysql db";
      script =
        let
          _mysql = ''${mysql}/bin/mysql -h 127.0.0.1 -N -u root'';
          mysqld = builtins.concatStringsSep " " [
            ''${mysql}/bin/mysqld''
            ''--defaults-file=${configFile}''
            ''--datadir="$MYSQLDATA"''
            ''--socket="$MYSQLDATA/mysql.sock"''
            ''--pid-file="$MYSQLDATA/mysql.pid"''
            ''--basedir=${mysql}''
          ];
          format = pkgs.formats.ini { listsAsDuplicateKeys = true; };
          configFile = format.generate "my.cnf" mysql_settings;
          bootstrap = ''
            CREATE DATABASE IF NOT EXISTS ${name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
            CREATE USER IF NOT EXISTS '${name}'@'%' IDENTIFIED BY '${name}';
            GRANT ALL PRIVILEGES ON ${name}.* TO '${name}'@'%';
            FLUSH PRIVILEGES;
            SET GLOBAL max_connections = 150;
            SET GLOBAL connect_timeout = 10;
            ${extra_bootstrap_sql}
          '';
        in
        ''
          MYSQLDATA=''${MYSQLDATA:-$(pwd)/.db/}
          PIDFILE="$MYSQLDATA/mysql.pid"

          wait_for_mysql() {
            for i in $(seq 1 10); do
              if ${_mysql} -e "SELECT 1" >/dev/null 2>&1; then
                return 0
              fi
              debug "wait_for_mysql[$i]"
              sleep 1
            done
            echo "Failed to connect to MySQL after 30 seconds"
            return 1
          }
          bootstrap() {
            ${mysqld} --initialize-insecure
            cp ${configFile} "$MYSQLDATA/my.cnf"
            touch "$MYSQLDATA/mysql_init"
            rm "$MYSQLDATA"/undo_*

            ${mysqld} --pid-file="$PIDFILE" --daemonize

            # Wait for MySQL to be ready
            if ! wait_for_mysql; then
              echo "MySQL failed to start"
              exit 1
            fi
            echo "${bootstrap}" | ${_mysql}
            ${extra_bootstrap}

            # Properly shutdown MySQL using the pid file
            if [ -f "$PIDFILE" ]; then
              kill "$(cat "$PIDFILE")"
              while [ -f "$PIDFILE" ]; do sleep 1; done
            fi
          }
          [ ! -d "$MYSQLDATA" ] && bootstrap
        '';
    };
  __mysql = { mysql ? mysql84, extra_flags ? "" }: pog {
    name = "__mysql";
    description = "run your local mysql db from $MYSQLDATA";
    script = ''
      MYSQLDATA=''${MYSQLDATA:-$(pwd)/.db/}

      # Clean up any existing undo files if the server isn't running
      if [ ! -f "$MYSQLDATA/mysql.pid" ] || ! kill -0 "$(cat "$MYSQLDATA/mysql.pid")" 2>/dev/null; then
        rm -f "$MYSQLDATA"/undo_*
      fi

      cleanup() {
        echo "Shutting down MySQL..."
        if [ -f "$MYSQLDATA/mysql.pid" ]; then
          kill "$(cat "$MYSQLDATA/mysql.pid")"
          while [ -f "$MYSQLDATA/mysql.pid" ]; do sleep 1; done
        fi
        exit 0
      }
      trap cleanup TERM

      red "mysqld starting - use ctrl+\ (SIGQUIT) to kill!"
      ${mysql}/bin/mysqld \
        --defaults-file="$MYSQLDATA/my.cnf" \
        --datadir="$MYSQLDATA" \
        --socket="$MYSQLDATA/mysql.sock" \
        --pid-file="$MYSQLDATA/mysql.pid" \
        --console \
        --basedir=${mysql} ${extra_flags}
    '';
  };
  __mysql_shell = { name ? "db", mysql ? mysql84, extra_flags ? "" }: pog {
    name = "__mysql_shell";
    description = "run a psql shell into postgres locally";
    script = ''
      MYSQLPORT=''${MYSQLPORT:-3306}
      TMPCNF=$(mktemp)
      trap 'rm -f $TMPCNF' EXIT

      cat > "$TMPCNF" << EOF
      [client]
      user=${name}
      password=${name}
      host=127.0.0.1
      port=$MYSQLPORT
      database=${name}
      EOF

      ${final.portwatch}/bin/portwatch "$MYSQLPORT" && ${mysql}/bin/mysql --defaults-file="$TMPCNF" ${extra_flags}
    '';
  };

  db_pog_scripts = [
    # postgres
    (__pg { })
    (__pg_bootstrap { })
    (__pg_shell { })
    # mysql
    (__mysql { })
    (__mysql_bootstrap { })
    (__mysql_shell { })
    # redis
    __rd
    __rd_shell
    # valkey
    __vk
    __vk_shell
    # magic run helper
    (__run { })
    # queues
    (__rabbitmq { })
  ];
}
