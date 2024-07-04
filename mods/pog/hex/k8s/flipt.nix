# [flipt](https://github.com/flipt-io/flipt) is a feature flag service built with Go
{ hex, ... }:
let
  name = "flipt";
  flipt = rec {
    defaults = {
      inherit name;
      namespace = name;
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-64-0;
      v0-64-0 = _v "0.64.0" "1dz9kd3fbcj2q8yywjr9yqpafln5m6i119kq7s64bdlv3qdh34ww"; # 2024-06-26
      v0-57-0 = _v "0.57.0" "18mf3ggp8lzycj7fw27ar0k232vgk5m8z0cig2byi8frkq1c0l91"; # 2024-04-05
      v0-56-0 = _v "0.56.0" "0l6m6ncwqlaqmwhr3dd4k1p3apq1lbgwxlwhyx3k1gpi92z5kpbb"; # 2024-04-02
      v0-55-2 = _v "0.55.2" "06shfrpk8m2x6pkssy2iq3qrj71dp88zzmma88b04hddvn56vh83"; # 2024-03-29
      v0-55-0 = _v "0.55.0" "0nnz89cxrvxbmyk51hkhsywf4j6p1hc4q70lp0s059cr7zxhli8k"; # 2024-03-25
      v0-54-2 = _v "0.54.2" "0fpzrmwlanzm5mkxsdab6q8v7nnfjidi9r27ldpi85mfkdigjwrp"; # 2024-03-15
      v0-54-1 = _v "0.54.1" "1iqh9g2rcwfljffpf1yb5n1w45gr67z713s68bl43cp0zalmvykv"; # 2024-03-13
      v0-54-0 = _v "0.54.0" "1jydw98824kw5i2322z39m3ywlkrx959hgg5yb9jq7dnvp1xn5ym"; # 2024-02-23
      v0-53-1 = _v "0.53.1" "1wgmnbms95rnjd3dq09dwiiwdnrq95pc9n0v6763b5j9s7yf7alc"; # 2024-02-12
      v0-53-0 = _v "0.53.0" "1fdq507fjinancnfgy0qkfx91z7p9yp84qxxld4khr0fh791bfv2"; # 2024-02-09
      v0-52-0 = _v "0.52.0" "1p1hzwz181x7dvyln98qdjfswkrnkk122m7z0vm1sd7ycazbv9wz"; # 2024-01-23
      v0-51-0 = _v "0.51.0" "0vnb965a10s8qzjgr11ph40g6ji1cnm6j93rs0qshnn4jkg13553"; # 2024-01-09
    };
    chart_url = version: "https://github.com/flipt-io/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
flipt
