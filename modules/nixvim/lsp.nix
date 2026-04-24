{
  self,
  lib,
  inputs,
  ...
}:
{
  debug = true;

  flake.modules.nixvim.base =
    { pkgs, ... }:
    {
      lsp = lib.mkIf (inputs ? nixvim) {
        inlayHints.enable = true;
        keymaps = [
          {
            key = "<leader>ht";
            mode = "n";
            action = inputs.nixvim.lib.nixvim.mkRaw ''
              function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
              end
            '';
            options.desc = "Toggle inlay hints";
          }
          {
            key = "<space>a";
            action = inputs.nixvim.lib.nixvim.mkRaw "vim.lsp.buf.code_action";
            mode = [
              "n"
              "v"
            ];
          }
          {
            key = "gd";
            lspBufAction = "definition";
          }
          {
            key = "gD";
            lspBufAction = "declaration";
          }
          {
            key = "go";
            lspBufAction = "type_definition";
          }
          {
            key = "gi";
            lspBufAction = "implementation";
          }
          {
            key = "K";
            lspBufAction = "hover";
          }
          {
            key = "<C-k>";
            lspBufAction = "signature_help";
          }
          {
            key = "<space>r";
            lspBufAction = "rename";
          }
          {
            action = inputs.nixvim.lib.nixvim.mkRaw "function() vim.diagnostic.jump({ count=-1, float=true }) end";
            key = "<leader>k";
          }
          {
            action = inputs.nixvim.lib.nixvim.mkRaw "function() vim.diagnostic.jump({ count=1, float=true }) end";
            key = "<leader>j";
          }
        ];
        servers = {
          asm_lsp.enable = true;
          nixd = {
            enable = true;
            config = {
              filetypes = [
                "nix"
              ];
              root_markers = [
                "flake.lock"
                "flake.nix"
                "README.md"
              ];
              settings.nixd =
                let
                  # Yoinked from https://github.com/MattSturgeon/nix-config/commit/b8aa42d6c01465949ef5cd9d4dc086d4eaa36793
                  # The wrapper curries `_nixd-expr.nix` with the `self` and `system` args
                  wrapper = builtins.toFile "expr.nix" ''
                             import ${"${self}" + "/lib/_nixd-expr.nix"} {
                               self = "${self}";
                               system = "${pkgs.stdenv.hostPlatform.system}";
                             }
                    	 '';
                  withFlakes = expr: "let inherit (import ${wrapper}) local global system; in " + expr;
                in
                {
                  nixpkgs.expr = withFlakes "global.inputs.nixpkgs";
                  formatting = {
                    command = [ "${lib.getExe pkgs.nixfmt}" ];
                  };
                  options = {
                    nixos.expr = withFlakes "builtins.foldl' (acc: b: acc // b.options) {} (builtins.attrValues (local.nixosConfigurations or {}))";
                    home.expr = withFlakes "builtins.foldl' (acc: b: acc // b.options) {} (builtins.attrValues (local.homeConfigurations or {}))";
                    flake-parts.expr = withFlakes "global.debug.options";
                    flake-parts-perSystem.expr = withFlakes "global.currentSystem.options";
                    nixvim.expr = withFlakes "global.packages.\${system}.nixvim.options";
                  };
                };
            };
          };
          nil_ls = {
            enable = false;
            config = {
              filetypes = [
                "nix"
              ];
              root_markers = [
                "flake.lock"
                "flake.nix"
                "README.md"
              ];
              settings.nix.flake.autoArchive = true;
              settings.nix.flake.autoEvalInputs = true;
            };
          };
          texlab.enable = true;
          zls.enable = true;
        };
      };
      plugins.lspconfig.enable = true;
      plugins.cmp.settings.sources = [
        {
          name = "nvim_lsp";
          group_index = 1;
        }
      ];
    };
}
