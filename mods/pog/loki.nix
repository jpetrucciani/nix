# this file provides some pog wrappers around curl for communicating with loki
final: prev:
let
  inherit (final) pog;
in
{
  loki_log = pog {
    name = "loki_log";
    description = "a lightweight helper to allow sending log lines to loki directly, with some included metadata";
    version = "0.0.2";
    flags = [
      {
        name = "url";
        description = "the loki url to push to";
        envVar = "LOKI_URL";
        required = true;
      }
      {
        name = "message";
        description = "the message to send to the loki system";
        envVar = "LOKI_MSG";
        required = true;
      }
      {
        name = "tags";
        description = "additional tags and values to send, as a csv of key=value pairs";
        envVar = "LOKI_TAGS";
      }
      {
        name = "curl_opts";
        description = "extra options to pass to curl";
        default = "";
      }
    ];
    script = h: with h; ''
      export SSL_CERT_FILE="''${SSL_CERT_FILE:=${final.cacert}/etc/ssl/certs/ca-bundle.crt}"
      parse_tags() {
        local tags="$1"
        tags=$(echo "$tags" | ${final.gnused}/bin/sed -E 's/^[,\s]+|[,\s]+$//g')
        local json="{}"
        IFS=',' read -ra pairs <<< "$tags"
        for pair in "''${pairs[@]}"; do
          if [[ -z "$pair" ]]; then
            continue
          fi
          key=$(echo "$pair" | ${final.busybox}/bin/cut -d= -f1)
          value=$(echo "$pair" | ${final.busybox}/bin/cut -d= -f2)
          json=$(echo "$json" | ${final.jq}/bin/jq --arg k "$key" --arg v "$value" '. + {($k): $v}')
        done
        echo "$json"
      }

      hostname=$(hostname)
      get_ip() {
        if [[ "$(uname)" == "Darwin" ]]; then
          ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "unknown")
        else
          ip=$(${final.busybox}/bin/ip route get 1.1.1.1 | ${final.gnused}/bin/sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')
        fi
        echo "$ip"
      }
      ip_address=$(get_ip)

      json_tags=$(parse_tags "$tags,hostname=''${hostname},ip=''${ip_address},user=$USER,pog=1")
      TIMESTAMP=$(date +%s%N)
      JSON_PAYLOAD=$(${final.jq}/bin/jq -n \
        --arg ts "$TIMESTAMP" \
        --arg msg "$message" \
        --argjson labels "$json_tags" \
        '{
          "streams": [
            {
              "stream": $labels,
              "values": [[$ts, $msg]]
            }
          ]
        }')
      debug "json_payload:"
      debug "$JSON_PAYLOAD"
      # shellcheck disable=SC2086
      ${final.curl}/bin/curl $curl_opts -H "Content-Type: application/json" -XPOST -d "$JSON_PAYLOAD" "$url"
    '';
  };
}
