final: prev:
with prev;
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
          psql = ''${postgres}/bin/psql -d postgres -h localhost -p "$PGPORT" -c'';
          create_db = "CREATE DATABASE ${db_name};";
          create_ext = builtins.concatStringsSep "\n" (map (x: ''CREATE EXTENSION IF NOT EXISTS \"${x}\";'') extensions);
          create_user = ''
            CREATE USER ${name} WITH ENCRYPTED PASSWORD '${password}';
            GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${name};
            ALTER USER ${name} CREATEDB;
          '';
        in
        ''
          bootstrap() {
            ${postgres}/bin/initdb -E UTF8 "$PGDATA"
            ${pg_ctl} start
            ${psql} "${create_db}"
            ${psql} "${create_ext}"
            ${psql} "${create_user}"
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

  db_pog_scripts = [
    __pg
    __pg_bootstrap
    __pg_shell
  ];
}
