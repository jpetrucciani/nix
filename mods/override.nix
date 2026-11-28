# This overlay provides some overrides/fixes for various packages
final: prev:
let
  inherit (final.stdenv.hostPlatform) isDarwin;
  cudaDriverRunpath = pkg: pkg.overrideAttrs (old: {
    # Header sorting corrupts these executables; a second RPATH rewrite aborts.
    patchelfFlags = (old.patchelfFlags or [ ]) ++ [ "--no-sort" ];
    dontUseAutoAddDriverRunpath = true;
    appendRunpaths = (old.appendRunpaths or [ ]) ++ [ "${final.addDriverRunpath.driverLink}/lib" ];
  });
in
{
  # fix for getting yank working on darwin
  yank = prev.yank.overrideAttrs (attrs: {
    makeFlags = if isDarwin then [ "YANKCMD=/usr/bin/pbcopy" ] else attrs.makeFlags;
  });

  # fix for python3Packages.ray
  py-spy = prev.py-spy.overrideAttrs (old: {
    doCheck = false;
  });

  _std = (import ../flake-compat.nix).inputs.nix-std.lib;

  sssd = prev.sssd.override { python3 = final.python311; };

  questdb = prev.questdb.overrideAttrs (old: {
    preInstall = ''
      mkdir -p $out/bin
      echo -e '#!/usr/bin/env bash\nexport JAVA_MAIN="io.questdb/io.questdb.ServerMain"' >$out/bin/env.sh
      echo -e '#!/usr/bin/env bash\necho hello' >$out/bin/print-hello.sh
      chmod +x $out/bin/env.sh
      chmod +x $out/bin/print-hello.sh
    '';
  });

  distcc_34 =
    let
      version = "2021-05-11";
    in
    prev.distcc.overrideAttrs (old: {
      inherit version;
      src = final.fetchFromGitHub {
        owner = "distcc";
        repo = "distcc";
        rev = "50d821efe99cae82c05be0a4ab3b4035ef0d3883";
        hash = "sha256-S3EHJ8s+bYWBmOfKP5ErNSa+UIalIK82MgKhWvPnwFo=";
      };
    });

  cudaPackages = prev.cudaPackages.overrideScope (_final: _prev: {
    cuda_gdb = cudaDriverRunpath _prev.cuda_gdb;
    cuda_sanitizer_api = cudaDriverRunpath _prev.cuda_sanitizer_api;
  });
}
