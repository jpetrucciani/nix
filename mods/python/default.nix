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
          ./ai/bindings.nix
          ./ai/vector.nix
          ./ai/prompts.nix
          ./ai/apps.nix
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
