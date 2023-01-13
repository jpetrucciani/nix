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
          create_db = "CREATE DATABASE ${db_name};";
          create_ext = builtins.concatStringsSep "\n" (map (x: ''CREATE EXTENSION IF NOT EXISTS \"${x}\";'') extensions);
          create_user = ''
            CREATE USER ${name} WITH ENCRYPTED PASSWORD '${password}';
            GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${name};
            ALTER USER ${name} CREATEDB;
          '';
          grant_schema = ''
            GRANT ALL ON SCHEMA public TO ${name};
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
      ${redis}/bin/redis-cli -p "$port"
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
  ];
}
