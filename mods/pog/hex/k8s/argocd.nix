# [argocd](https://github.com/argoproj/argo-cd) is declarative continuous deployment for kubernetes
{ hex, ... }:
let
  argocd = rec {
    defaults = {
      name = "argocd";
      namespace = "argocd";
      valuesAttrs = {
        repoServer = {
          extraContainers = [
            {
              command = [
                "/var/run/argocd/argocd-cmp-server"
              ];
              image = "ghcr.io/jpetrucciani/argohex:latest";
              name = "hex";
              securityContext = {
                runAsNonRoot = true;
                runAsUser = 999;
              };
              imagePullPolicy = "Always";
              volumeMounts = [
                {
                  mountPath = "/var/run/argocd";
                  name = "var-files";
                }
                {
                  mountPath = "/home/argocd/cmp-server/plugins";
                  name = "plugins";
                }
                { mountPath = "/tmp"; name = "hex-tmp"; }
              ];
            }
          ];
          volumes = [{ name = "hex-tmp"; emptyDir = { }; }];
        };
      };
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v7-6-12;
      v7-6-12 = _v "7.6.12" "18z2sihm7v96swnjsryq476km6qakzk7g1dfzlb6j4pl91ls1rz0"; # 2024-10-18
      v7-6-8 = _v "7.6.8" "09nyrbxk2678ni3269l42dr7x8592c6lnz2cngrzall0y779p26w"; # 2024-10-03
      v7-3-4 = _v "7.3.4" "0xym2k7v8qwmkx7mp2rd1al4xlvanp1lrh5zwyrg852c6cl1wf1w"; # 2024-07-02
      v6-11-1 = _v "6.11.1" "0hnvnzjfsp4fvnkh8w9axz1254xsr29wc40jrnjbv9i2hhaxy94g"; # 2024-05-23
      v5-55-0 = _v "5.55.0" "0766cii918lp2b3v7xcraspv1p10snj4z1c4gf4i4pqnpnvpcpwj"; # 2024-02-07
      v5-18-1 = _v "5.18.1" "1dqa8vpsxql3kyfraysdpfignji12f3nzaazv0s6k1s0fwbc2d3m";
      v5-17-4 = _v "5.17.4" "0y4br59pspwqv6p9m9pkj6l1nakdzbnds5nxzqfh1r4bv55hxfdl";
      v5-16-15 = _v "5.16.15" "1pybbvjdi9nvcc1cisv7bdrlfclfbh7lffqjkfr55qlrqrvrpx6i";
      v5-15-2 = _v "5.15.2" "0bd5m6rg86pyrpfwwdkbi2s2ryj77n5cb3dy84r1vkaxmvmssn15";
      v4-10-9 = _v "4.10.9" "0ipjcyh9bf6rjic5s1fifq2kn0p6cvy1wjviqaa21lm93laq6832";
      v4-10-6 = _v "4.10.6" "15bmai7k9bih5v3l29s5pvzgdqcbd4ff9302vz9xrgkdbbwm8bfp";
    };
    chart_url = version: "https://github.com/argoproj/argo-helm/releases/download/argo-cd-${version}/argo-cd-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
    app =
      { name
      , repo
      , path
      , targetRevision ? "main"
      , pluginName ? "hex-v0.0.8"
      , namespace ? defaults.namespace
      , syncOptions ? [ ]
      , defaultSyncOptions ? [ "ServerSideApply=true" ]
      , project ? "default"
      , destination ? "in-cluster"
      }: hex.toYAMLDoc {
        apiVersion = "argoproj.io/v1alpha1";
        kind = "Application";
        metadata = {
          inherit name namespace;
        };
        spec = {
          destination.name = destination;
          inherit project;
          source = {
            inherit targetRevision path;
            plugin.name = pluginName;
            repoURL = repo;
          };
          syncPolicy.syncOptions = defaultSyncOptions ++ syncOptions;
        };
      };
  };
in
argocd
