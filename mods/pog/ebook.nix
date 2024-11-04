final: prev: {
  ebook_fixup = final.pog {
    name = "ebook_fixup";
    description = "a quick and easy way to try to fix an ebook for kindle";
    arguments = [
      { name = "source"; }
    ];
    flags = [
      {
        name = "output";
        description = "the filename to output to [defaults to the current name with a 'fixed' between the name and extension]";
      }
    ];
    script =
      let
        e = "${final.calibre}/bin/ebook-convert";
        mktemp = "${final.coreutils}/bin/mktemp --suffix=.mobi";
      in
      helpers: with helpers; ''
        file="$1"
        temp_ebook="$(${mktemp})"
        ${var.empty "file"} && die "you must specify a source ebook!" 1
        ${var.empty "output"} && output="''${file%.*}.fixed.''${file##*.}"
        ${e} "$file" "$temp_ebook"
        ${e} "$temp_ebook" "$output"
      '';
  };
}
