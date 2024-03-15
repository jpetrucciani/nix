# This module contains a `soundScript` wrapper that uses `pog` to create command line sound bites!
final: prev:
with prev;
let
  soundFolder = "https://cobi.dev/static/sound";
in
rec {
  soundScript = name: url: sha256:
    let
      file = pkgs.fetchurl {
        inherit url sha256;
      };
      echo = "echos 0.8 0.7 700 0.25 900 0.3";
      chorus = "chorus 0.5 0.9 50 0.4 0.25 2 -t 60 0.32 0.4 2.3 -t 40 0.3 0.3 1.3 -s";
    in
    pog {
      inherit name;
      description = "a quick and easy way to play a sound meme!";
      flags = [
        {
          name = "speed";
          description = "the speed at which to play the sound";
          default = "1.0";
        }
        {
          name = "pitch";
          description = "the pitch modifier for the sound [-1000 to 1000]";
          default = "0.0";
        }
        {
          name = "tempo";
          description = "the tempo at which to play the sound";
          default = "1.0";
        }
        {
          name = "reverse";
          description = "play the sound in reverse!";
          bool = true;
        }
        {
          name = "echo";
          description = "apply an echo-y effect";
          bool = true;
        }
        {
          name = "chorus";
          description = "apply a chorus-y effect";
          bool = true;
        }
      ];
      script = ''
        # shellcheck disable=SC2068
        ${_.sox} --no-show-progress -V2 --clobber ${file} \
          speed "$speed" \
          tempo "$tempo" \
          pitch "$pitch" \
          ''${chorus:+${chorus}} \
          ''${echo:+${echo}} \
          ''${reverse:+reverse} \
          "$@"
      '';
    };

  bruh = soundScript "bruh" "${soundFolder}/bruh.mp3" "sha256-w28wlLYOa7pttev73vStcAWs5MCRO+tfB0i6o4BQwYY=";
  coin = soundScript "coin" "${soundFolder}/coin.wav" "sha256-I8EDvMiLHf/fNk+gGBYKeNZqk47BilLHXT59NaFrh6E=";
  dababy = soundScript "dababy" "${soundFolder}/dababy.mp3" "sha256-Vg/7/WrMgi2Fz27reG1iAdxFpvdyLWAhk9+8GACL0rg=";
  do_it = soundScript "do_it" "${soundFolder}/do_it.mp3" "sha256-98bR48sTooZqqb+gqPNiBymBoii6mQAJZA7yc2m0uXo=";
  error = soundScript "error" "${soundFolder}/xp_error.mp3" "sha256-OpvwYGEbDVhaU3pGs5EWSMQKPnKLHF778UfzPfmRWp4=";
  fail = soundScript "fail" "${soundFolder}/the_price_is_wrong.mp3" "sha256-Id3NObQvh1/sn7Nh9bqHItbIpZu0IysrxkobyvGxQM4=";
  fart = soundScript "fart" "${soundFolder}/reverb_fart.mp3" "sha256-ooEfsfXtIy4ZpWUoxcTBx67Rjfzvxpy9tdyio/fzJic=";
  guh = soundScript "guh" "${soundFolder}/guh.wav" "sha256-SqdPjpkx2YJrJKOlcUlqrDpf7wpvvQwv5k8b+ZQzGbI=";
  hello_mario = soundScript "hello_mario" "${soundFolder}/hello_mario.mp3" "sha256-hRKpRcM3o+LNdCzm5VkXkXbLkBby8fzNlDb0dd5+u20=";
  waluigi = soundScript "waluigi" "${soundFolder}/waluigi.mp3" "sha256-uT9BDNDaeuQPoE/WafS0Wo6FlrCvOmDJwG7rsFVf6Zw=";

  keith_ultrawide = soundScript "keith_ultrawide" "${soundFolder}/keith/ultrawide.ogg" "sha256-r23YcTBFCUyXCwGY8hEKWCr2vLBUQKyemAuWbqX0ulY=";
  ultrawides_are_ultra_pog = soundScript "keith_ultrawide" "${soundFolder}/keith/ultrawides_are_ultra_pog.mp3" "sha256-eXXzztQ8a4jREUTaiRgQbMkk0Qup2Ga1zF/91Qs8ddA=";
  ben_and_cobi_were_so_right = soundScript "ben_and_cobi_were_so_right" "${soundFolder}/keith/ben_and_cobi_were_so_right.mp3" "sha256-5dgNLwKb02M+VxG3AuHOBp1n9HYaVS6T7Kr9L6/f/Ns=";

  meme_sounds = [
    bruh
    coin
    dababy
    do_it
    error
    fail
    fart
    guh
    hello_mario
    waluigi
    keith_ultrawide
    ben_and_cobi_were_so_right
  ];
}
