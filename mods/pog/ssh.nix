final: prev:
with prev;
let
in
rec {
  pogproxy = pog {
    name = "pogproxy";
    description = "a quick and easy way to set up a socks proxy through ssh";
    flags = [
      _.flags.ssh.host
      {
        name = "bind_host";
        description = "the local ip to bind to";
        default = "127.0.0.1";
      }
      {
        name = "port";
        description = "the local port to bind to";
        default = "1337";
      }
      {
        name = "user";
        description = "the user to use for the ssh connection";
      }
      {
        name = "fork";
        description = "fork and run this proxy in the background";
        bool = true;
      }
    ];
    script = helpers: ''
      ssh \
        -D "''${bind_host}:''${port}" \
        -q \
        -C \
        -N \
        ''${fork:+-f} \
        "''${user:+user@}''${host}"
    '';
  };

  ssh_pog_scripts = [
    pogproxy
  ];
}
