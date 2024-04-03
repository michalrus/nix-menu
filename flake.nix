{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
  };

  outputs = inputs:
    let
      inherit (inputs.nixpkgs) lib;
      eachSystem = f: lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (system: f system inputs.nixpkgs.legacyPackages.${system});
    in
    {
      devShells = eachSystem (system: pkgs: {
        default = pkgs.mkShell {
          buildInputs = (with pkgs; [
            dialog
            jq
            nixpkgs-fmt
            nodePackages.prettier
            shellcheck
            shfmt
            treefmt
          ]) ++ [
            (pkgs.writeShellScriptBin "menu" ''
              export PATH=${with pkgs; lib.makeBinPath [ dialog jq gnused ]}:"$PATH"
              exec ${pkgs.runtimeShell} ${./menu.sh}
            '')
          ];
          shellHook = ''
            echo
            echo -e "  Welcome! Type ‘\033[1mmenu\033[0m’ to enter a menu."
            echo
          '';
        };
      });
    };
}
