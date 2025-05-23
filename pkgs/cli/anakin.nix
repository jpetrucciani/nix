# [anakin](https://github.com/Timmmm/anakin/) is a tool to kill orphan processes
{ lib
, rustPlatform
, fetchFromGitHub
}:
rustPlatform.buildRustPackage {
  pname = "anakin";
  version = "unstable-2024-03-29";

  src = fetchFromGitHub {
    owner = "Timmmm";
    repo = "anakin";
    rev = "258fc03c630bc6e98392c982869b88c8c3617942";
    hash = "sha256-5v964c7o1/sXS+S9NvaNW9BlyMhFxFPyMLmO819aGds=";
  };

  cargoHash = "sha256-4eOrMfWxV7LFhkfRWopYyOqWY6Sy60h8XdKsjo+jJC8=";

  meta = with lib; {
    description = "Kill orphan processes";
    homepage = "https://github.com/Timmmm/anakin";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    platforms = platforms.linux;
    mainProgram = "anakin";
  };
}
