# [custom-pod-autoscaler](https://github.com/jthomperoo/custom-pod-autoscaler-operator) is an operator for managing custom autoscaling rules
{ hex, ... }:
{
  cluster =
    let
      spec_url = version: "https://github.com/jthomperoo/custom-pod-autoscaler-operator/releases/download/v${version}/cluster.yaml";
      setup = { version, sha256 }: builtins.readFile (builtins.fetchurl {
        inherit sha256;
        url = spec_url version;
      });
    in
    {
      version = rec {
        _v = v: s: setup { version = v; sha256 = s; };
        latest = v1-4-2;
        v1-4-2 = _v "1.4.2" "1k8229s30y6hy759v25jh2dvj5sz0cyjyy7gkz7l6fm8x868m6qb";
      };
    };
}
