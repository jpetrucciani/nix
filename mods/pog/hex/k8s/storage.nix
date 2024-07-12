# helpers for defining PVs and PVCs
{ hex, ... }:
let
  inherit (hex) toYAMLDoc;
  access_modes = {
    RWO = "ReadWriteOnce";
    ROX = "ReadOnlyMany";
    RWX = "ReadWriteMany";
    RWOP = "ReadWriteOncePod";
  };
  _storage = "1000Gi"; # this value is not respected for NFS or local-path, and can usually be ignored
in
{
  nfs_pv = { name, server, path, namespace ? "default", storage ? _storage }:
    let
      pv = {
        apiVersion = "v1";
        kind = "PersistentVolume";
        metadata = {
          inherit name namespace;
        };
        spec = {
          accessModes = [ access_modes.RWX ];
          capacity = {
            inherit storage;
          };
          nfs = {
            inherit server path;
          };
        };
      };
      pvc = {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          inherit name namespace;
        };
        spec = {
          accessModes = [ access_modes.RWX ];
          resources.requests.storage = storage;
          storageClassName = "";
        };
      };
    in
    ''
      ${toYAMLDoc pv}
      ${toYAMLDoc pvc}
    '';

  local_pv = { name, path, namespace ? "default", storage ? _storage }:
    let
      pv = {
        apiVersion = "v1";
        kind = "PersistentVolume";
        metadata = {
          inherit name namespace;
        };
        spec = {
          accessModes = [ access_modes.RWO ];
          capacity = {
            inherit storage;
          };
          hostPath.path = path;
        };
      };
      pvc = {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          inherit name namespace;
        };
        spec = {
          accessModes = [ access_modes.RWO ];
          resources.requests.storage = storage;
          storageClassName = "";
          volumeName = name;
        };
      };
    in
    ''
      ${toYAMLDoc pv}
      ${toYAMLDoc pvc}
    '';
}
