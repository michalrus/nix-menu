{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
  };

  outputs = inputs:
    let
      eachSystem = f: inputs.nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (system: f system inputs.nixpkgs.legacyPackages.${system});
    in
    {
      devShells = eachSystem (system: pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [ treefmt nixpkgs-fmt ];
        };
      });
    };
}
