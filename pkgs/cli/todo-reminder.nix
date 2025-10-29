# [todo-reminder](https://github.com/leo108/todo-reminder) is a command-line tool that scans codebases for TODO comments, tracking deadlines and formatting issues. 
{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "todo-reminder";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "leo108";
    repo = "todo-reminder";
    rev = "v${version}";
    hash = "sha256-jmNZ6AsRgPd6jxXEAN/CSJeuQToP+NM1GEBJzKUxM3c=";
  };

  cargoHash = "sha256-eGN+CW+dEE/6MfMdhxmknSM+oEw7VTjWlIa/kK8ePs8=";

  meta = {
    description = "A command-line tool that scans codebases for TODO comments, tracking deadlines and formatting issues";
    homepage = "https://github.com/leo108/todo-reminder";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "todo-reminder";
  };
}
