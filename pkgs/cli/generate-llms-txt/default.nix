{ hax, lib }:
hax.writePythonApplication {
  name = "generate-llms-txt";
  src = ./generate_llms_txt.py;
  pythonVersion = "3.11";

  meta = {
    description = "Generate llms.txt and llms-full.txt from Python docstrings";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
