{ hex, ... }:
let
  argocd = rec {
    defaults = {
      name = "argocd";
      namespace = "argocd";
      version = "5.19.6";
      sha256 = "1illqq069qzd7xf66zvyjkiy7xr1x0d1k9hy0w2svmv9q9ffiars";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v5-19-6;
      v5-19-6 = _v defaults.version defaults.sha256;
      v5-18-1 = _v "5.18.1" "1dqa8vpsxql3kyfraysdpfignji12f3nzaazv0s6k1s0fwbc2d3m";
      v5-17-4 = _v "5.17.4" "0y4br59pspwqv6p9m9pkj6l1nakdzbnds5nxzqfh1r4bv55hxfdl";
      v5-16-15 = _v "5.16.15" "1pybbvjdi9nvcc1cisv7bdrlfclfbh7lffqjkfr55qlrqrvrpx6i";
      v5-15-2 = _v "5.15.2" "0bd5m6rg86pyrpfwwdkbi2s2ryj77n5cb3dy84r1vkaxmvmssn15";
      v4-10-9 = _v "4.10.9" "0ipjcyh9bf6rjic5s1fifq2kn0p6cvy1wjviqaa21lm93laq6832";
      v4-10-6 = _v "4.10.6" "15bmai7k9bih5v3l29s5pvzgdqcbd4ff9302vz9xrgkdbbwm8bfp";
    };
    chart_url = version: "https://github.com/argoproj/argo-helm/releases/download/argo-cd-${version}/argo-cd-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
argocd
