final: prev:
with prev;
rec {
  github_tags = pog {
    name = "github_tags";
    description = "a nice wrapper for getting github tags for a repo!";
    flags = [
      {
        name = "latest";
        description = "fetch only the latest tag";
        bool = true;
      }
      _.flags.github.owner
      _.flags.github.repo
    ];
    script = ''
      tags="$(${_.curl} -Ls "https://api.github.com/repos/''${owner}/''${repo}/tags" |
        ${_.jq} -r '.[].name')"
      if [ -n "''${latest}" ]; then
        echo "$tags" | ${_.head} -n 1
      else
        echo "$tags"
      fi
    '';
  };

  github_pog_scripts = [
    github_tags
  ];
}
