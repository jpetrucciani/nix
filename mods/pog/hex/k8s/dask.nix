# [dask](https://docs.dask.org/en/stable/) is a python library/framework for parallel and distributed computing 
{ hex, ... }:
let
  namespace = "dask";
  kubernetes-operator =
    let
      # https://docs.dask.org/en/stable/deploying-kubernetes.html
      name = "dask-operator";
    in
    rec {
      __functor = _: version.latest;
      defaults = {
        inherit name namespace;
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v2024-5-0;
        v2024-5-0 = _v "2024.5.0" "1xryp51dn0w9yma914s4ggbrhxmdfay4gzgscyng33i1zdd7zbdl"; # 2024-05-01
      };
      chart_url = version: "https://helm.dask.org/dask-kubernetes-operator-${version}.tgz";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
in
{
  inherit kubernetes-operator;
}
