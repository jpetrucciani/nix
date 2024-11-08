# this file provides some pog wrappers for discord features
final: prev: {
  discord_webhook = final.pog {
    name = "discord_webhook";
    description = "a quick helper to post text or code to discord, using a discord webhook";
    flags = [
      { name = "webhookurl"; envVar = "DISCORD_WEBHOOK_URL"; required = true; }
      { name = "snippet"; bool = true; description = "post the contents as a snippet"; }
      { name = "snippetlang"; short = ""; description = "the language to use for the snippet, if snippet mode is enabled"; }
    ];
    script = h: with h; ''
      message="$1"
      message_escaped=$(echo "$message" | ${final.gnused}/bin/sed 's/"/\\"/g')
      if ${flag "snippet"}; then
          if [ -n "$snippetlang" ]; then
              payload="{\"content\":\"\`\`\`$snippetlang\\n$message_escaped\\n\`\`\`\"}"
          else
              payload="{\"content\":\"\`\`\`\\n$message_escaped\\n\`\`\`\"}"
          fi
      else
          payload="{\"content\":\"$message_escaped\"}"
      fi
      response="$(${final.curl}/bin/curl -s -H "Content-Type: application/json" -X POST -d "$payload" "$webhookurl")"
      debug "$response"
    '';
  };
}
