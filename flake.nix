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
      packages = eachSystem (system: pkgs: rec {
        default = menu;
        menu = inputs.self.lib.mkPackage { inherit pkgs; };
        menu-example = inputs.self.lib.mkMenu {
          inherit pkgs; name = "menu-example";
          definition = builtins.fromJSON (builtins.readFile ./example.json);
        };
      });

      devShells = eachSystem (system: pkgs: {
        default = pkgs.mkShell {
          buildInputs = (with inputs.self.packages.${system}; [
            menu
            menu-example
          ]) ++ (with pkgs; [
            dialog
            jq
            nixpkgs-fmt
            nodePackages.prettier
            shellcheck
            shfmt
            treefmt
          ]);
          shellHook = ''
            echo
            echo -e "  Welcome! Type ‘\033[1mmenu-example\033[0m’ to enter a menu."
            echo
            echo -e "  It’s the same as ‘\033[1mmenu example.json\033[0m’, if you want to play with different JSONs."
            echo
            echo -e "  You can also run ‘\033[1mnix run github:michalrus/nix-menu#menu-example\033[0m’ from anywhere."
            echo
          '';
        };
      });

      lib = {
        mkMenu = { pkgs, name ? "menu", definition }:
          pkgs.writeShellScriptBin name ''
            exec ${pkgs.lib.getExe (inputs.self.lib.mkPackage { inherit pkgs; })} \
              ${builtins.toFile "menu.json" (builtins.toJSON definition)}
          '';

        mkPackage = { pkgs }:
          pkgs.writeShellScriptBin "menu" ''
            export PATH=${with pkgs; lib.makeBinPath [ dialog jq gnused ]}:"$PATH"
            ${builtins.replaceStrings ["%NIX_MENU_VERSION%"] [(inputs.self.rev or "dirty")] (builtins.readFile ./menu.sh)}
          '';
      };
    };
}
