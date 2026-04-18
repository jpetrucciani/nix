# [jeeves](https://github.com/robinovitch61/jeeves) is an AI agent conversation history browser
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule (finalAttrs: {
  pname = "jeeves";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "robinovitch61";
    repo = "jeeves";
    tag = "v${finalAttrs.version}";
    hash = "sha256-epo2n72vKklhRV3CPnlH70iXvrr/jFxje0Gvs9899Qo=";
  };

  vendorHash = "sha256-RjVURtngH7mivuMzpw8Pmsd+NfxAdbHvdKSaiCSlNBE=";

  ldflags = [ "-s" ];

  meta = {
    description = "AI agent conversation history browser";
    homepage = "https://github.com/robinovitch61/jeeves";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "jeeves";
  };
})
