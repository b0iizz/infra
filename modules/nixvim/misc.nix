{ lib, inputs, ... }:
{
  flake.modules.nixvim.base = lib.mkIf (inputs ? nixvim) (
    { ... }:
    {
      plugins.dashboard.enable = true;
      # plugins.nix.enable = true;
      plugins.nvim-autopairs.enable = true;
      plugins.which-key.enable = true;
      plugins.treesitter.enable = true;
      plugins.indent-o-matic = {
        enable = true;
        settings = {
          max_lines = 2048;
          skip_multiline = false;
          standard_widths = [
            2
            4
            8
          ];
          filetype_nix = {
            standard_widths = [ 2 ];
          };
        };
      };
      plugins.indent-blankline = {
        enable = true;
        settings = {
          indent = {
            char = "│";
          };
          scope = {
            enabled = true;
            show_start = false;
            show_end = false;
            show_exact_scope = true;
          };
          exclude = {
            filetypes = [
              ""
              "checkhealth"
              "help"
              "lspinfo"
              "packer"
              "TelescopePrompt"
              "TelescopeResults"
              "yaml"
            ];
            buftypes = [
              "terminal"
              "quickfix"
            ];
          };
        };
      };
    }
  );
}
