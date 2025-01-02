(final: prev: prev.lib.genAttrs [ "python311" "python312" "python313" ]
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
          ./ai/bindings.nix
          ./ai/prompts.nix
          ./ai/apps.nix
          ./ai/auto.nix
          ./ai/kagi.nix
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
