final: prev:
with prev;
rec {
  scale = pog {
    name = "scale";
    description = "a quick and easy way to scale an image/video!";
    arguments = [
      { name = "source"; }
    ];
    flags = [
      {
        name = "horizontal";
        short = "x";
        description = "the number of pixels wide the image should scale to";
      }
      {
        name = "vertical";
        short = "y";
        description = "the number of pixels high the image should scale to";
      }
      {
        name = "output";
        description = "the filename to output to [defaults to the current name with a tag]";
      }
    ];
    script = helpers: with helpers; ''
      file="$1"
      name=""
      scale=""
      ${var.empty "file"} && die "you must specify a source file!" 1
      ${var.notEmpty "horizontal"} && ${var.notEmpty "vertical"} && die "you can only scale in 1 dimension!" 1
      if ${var.notEmpty "horizontal"}; then
        name="''${horizontal}x"
        scale="$horizontal:-1"
      else
        name="''${vertical}y"
        scale="-1:$vertical"
      fi
      ${var.empty "output"} && output="''${file%.*}.$name.''${file##*.}"
      ${_.ffmpeg} -i "$file" -vf scale="$scale" "$output"
    '';
  };
  flip = pog {
    name = "flip";
    description = "a quick and easy way to flip an image/video!";
    arguments = [
      { name = "source"; }
    ];
    flags = [
      {
        name = "horizontal";
        short = "x";
        description = "flip the source horizontally";
        bool = true;
      }
      {
        name = "vertical";
        short = "y";
        description = "flip the source vertically";
        bool = true;
      }
      {
        name = "output";
        description = "the filename to output to [defaults to the current name with a tag]";
      }
    ];
    script = helpers: with helpers; ''
      file="$1"
      sep=""
      ${var.empty "file"} && die "you must specify a source file!" 1
      ${var.empty "horizontal"} && ${var.empty "vertical"} && die "you must specify at least one way to flip!" 1
      ${var.empty "output"} && output="''${file%.*}.flip.''${file##*.}"
      ${var.notEmpty "horizontal"} && ${var.notEmpty "vertical"} && sep=","
      ${_.ffmpeg} -i "$file" -filter:v "''${vertical:+vflip}''${sep}''${horizontal:+hflip}" -c:a copy "$output"
    '';
  };
  cut_video = pog {
    name = "cut_video";
    description = "a quick and easy way to cut a video with ffmpeg!";
    arguments = [
      { name = "source"; }
    ];
    flags = [
      {
        name = "start";
        description = "the start timestamp to cut from";
        default = "0.0";
      }
      {
        name = "end";
        description = "the end timestamp to cut to";
      }
      {
        name = "duration";
        description = "the length of time to cut out. will override --end if passed";
      }
      {
        name = "output";
        description = "the filename to output to [defaults to the current name with a tag]";
      }
    ];
    script = helpers: with helpers; ''
      file="$1"
      ${var.empty "file"} && die "you must specify a source file!" 1
      ${file.notExists "file"} && die "the file '$file' does not exist!" 2
      ${var.empty "end"} && ${var.empty "duration"} && die "you must specify an end (-e|--end) or duration (-d|--duration)!" 3
      ${var.empty "output"} && output="''${file%.*}.cut.''${file##*.}"
        
      start_sec="$(echo "$start" | ${fn.ts_to_seconds})"
      if ${var.notEmpty "duration"}; then
        end_sec="$(echo "$start_sec" "$duration" | ${fn.add})"
      else
        end_sec="$(echo "$end" | ${fn.ts_to_seconds})"
      fi

      ${_.ffmpeg} -ss "$start_sec" -i "$file" -to "$end_sec" -c:v copy -c:a copy "$output"
    '';
  };
  crop_video = pog {
    name = "crop_video";
    description = "a quick and easy way to crop a video with ffmpeg!";
    arguments = [
      { name = "source"; }
    ];
    shortDefaultFlags = false;
    flags = [
      {
        name = "x";
        short = "x";
        description = "the x value to start the crop box at";
        default = "0";
      }
      {
        name = "y";
        short = "y";
        description = "the y value to start the crop box at";
        default = "0";
      }
      {
        name = "width";
        description = "the width of the crop box";
        default = "in_w";
      }
      {
        name = "height";
        description = "the height of the crop box";
        default = "in_h";
      }
      {
        name = "output";
        description = "the filename to output to [defaults to the current name with a tag]";
      }
    ];
    script = helpers: with helpers; ''
      file="$1"
      ${var.empty "file"} && die "you must specify a source file!" 1
      ${file.notExists "file"} && die "the file '$file' does not exist!" 2
      ${var.empty "output"} && output="''${file%.*}.crop.''${file##*.}"
      ${_.ffmpeg} -i "$file" -filter:v "crop=$width:$height:$x:$y" "$output"
    '';
  };
  to_mp3 = pog {
    name = "to_mp3";
    description = "a quick and easy way to convert an audio file to mp3!";
    arguments = [
      { name = "source"; }
    ];
    flags = [
      {
        name = "output";
        description = "the filename to output to [defaults to the current name with a tag]";
      }
      {
        name = "quality";
        description = "quality, 0 to 9 (lower is higher quality)";
        default = "4";
      }
    ];
    script = helpers: with helpers; ''
      # https://trac.ffmpeg.org/wiki/Encode/MP3
      file="$1"
      ${var.empty "file"} && die "you must specify a source file!" 1
      ${var.empty "output"} && output="''${file%.*}.mp3"
      ${_.ffmpeg} -i "$file" -c:v copy -c:a libmp3lame -q:a "$quality" "$output"
    '';
  };
  ffmpeg_pog_scripts = [
    scale
    flip
    cut_video
    crop_video
    to_mp3
  ];
}
