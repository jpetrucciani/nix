(final: prev: prev.lib.genAttrs [ "python310" "python311" "python312" ]
  (pythonAttr: final.lib.fix
    (self: (prev.${pythonAttr}.override {
      inherit self;
      packageOverrides = final.lib.composeManyExtensions self.overlays;
    }).overrideAttrs (old: {
      passthru = old.passthru // {
        overlays = map import [
          ./ai.nix
          ./experimental.nix
          ./fastapi.nix
          ./finance.nix
          ./fixes.nix
          ./hax.nix
          ./misc.nix
          ./notebooks.nix
          ./pr.nix
          ./types.nix
        ];
      };
    }))
  )
)
