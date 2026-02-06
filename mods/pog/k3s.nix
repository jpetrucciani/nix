# This module creates some `pog` tools specific to [k3s](https://github.com/k3s-io/k3s) cluster maintenance!
final: prev:
let
  inherit (final) _ pog;
in
rec {
  k3s_gc = pog {
    name = "k3s_gc";
    description = "a pog script to do garbage collection on a k3s node";
    script = ''
      ${final.k3s}/bin/k3s crictl rmi --prune
    '';
  };

  k3s_useradd =
    let
      bb = "${final.busybox}/bin";
      k = "${final.kubectl}/bin/kubectl";
      ossl = "${final.openssl}/bin/openssl";
    in
    pog {
      name = "k3s_useradd";
      description = "create a service account user cert + kubeconfig for the k3s cluster";
      flags = [
        { name = "common"; description = "common name"; }
        { name = "organization"; description = "organization name"; }
        { name = "extrasubject"; description = "extra subject field content to append"; }
        { name = "days"; description = "days until expiration"; default = "420"; }
        { name = "k3sdir"; description = "root dir of k3s data"; default = "/var/lib/rancher/k3s"; }
      ];
      script = h: with h; ''
        ${var.empty "common"} && die "you must specify a common name for the user!" 1
        subject="/CN=$common''${organization:+/O=$organization}$extrasubject"
        debug "read or create key"
        [ -f "$common.key" ] || {
          debug "creating key"
          ${ossl} genrsa -out "$common.key" 4096
        }
        debug "read or create csr"
        [ -f "$common.csr" ] || {
          debug "creating csr"
          ${ossl} req -new -key "$common.key" -out "$common.csr" -subj "$subject"
        }
        _date="$(date +'%F')"
        crt_name="$common.$_date.crt"
        kcfg_name="$common.$_date.yaml"
        debug "creating new cert for common '$common'"
        ${ossl} x509 -req -in "$common.csr" -CA "$k3sdir/server/tls/client-ca.crt" -CAkey "$k3sdir/server/tls/client-ca.key" -CAcreateserial -out "$crt_name" -days "$days"

        current_ip="$(${bb}/ip route get 1 | ${final.gawk}/bin/awk '{print $NF;exit}' | ${bb}/head -1)"
        cluster="$(${bb}/cat /etc/hostname)"
        debug "found '$cluster' at ip '$current_ip'"

        debug "creating kubeconfig"
        KUBECTL="${k} --kubeconfig=$kcfg_name"
        $KUBECTL config set-cluster "$cluster" --embed-certs --server="https://$current_ip:6443" --certificate-authority="$k3sdir/server/tls/server-ca.crt"
        $KUBECTL config set-credentials "$common" --embed-certs --client-certificate="$crt_name"  --client-key="$common.key"
        $KUBECTL config set-context "$cluster" --cluster="$cluster" --namespace="default" --user="$common"
        $KUBECTL config set current-context "$cluster"
        debug "created kubeconfig '$kcfg_name'"
      '';
    };

  k3s_pog_scripts = [
    k3s_gc
    k3s_useradd
  ];
}
