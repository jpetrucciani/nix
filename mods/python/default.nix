(final: prev: prev.lib.genAttrs [ "python310" "python311" "python312" ]
  (pythonAttr: final.lib.fix
    (self: (prev.${pythonAttr}.override {
      inherit self;
      packageOverrides = final.lib.composeManyExtensions self.overlays;
    }).overrideAttrs (old: {
      passthru = old.passthru // {
        overlays = map import [
          ./fixes.nix
          ./types.nix
          ./ai/deps.nix
          ./ai/dataset.nix
          ./ai/bindings.nix
          ./ai/vector.nix
          ./ai/prompts.nix
          ./ai/langchain.nix
          ./ai/llama-index.nix
          ./ai/apps.nix
          ./ai/auto.nix
          ./ai/eval.nix
          ./ai/kagi.nix
          ./ai/deployment.nix
          ./experimental.nix
          ./fastapi.nix
          ./finance.nix
          ./hax.nix
          ./loaders.nix
          ./misc.nix
          ./notebooks.nix
          ./pr.nix
        ];
      };
    }))
  )
)
