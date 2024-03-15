# this set of pog scripts creates some wrappers around ssh to make things easier
final: prev:
with prev;
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
      {
        name = "quiet";
        description = "run the proxy in quiet mode";
        bool = true;
      }
    ];
    script = helpers: ''
      ssh \
        -D "''${bind_host}:''${port}" \
        -C \
        -N \
        ''${quiet:+-q} \
        ''${fork:+-f} \
        "''${user:+user@}''${host}"
    '';
  };

  ssh_pog_scripts = [
    pogproxy
  ];
}
