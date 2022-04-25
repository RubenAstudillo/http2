{
  # inspired by: https://serokell.io/blog/practical-nix-flakes#packaging-existing-applications
  description = "A Hello World in Haskell with a dependency and a devShell";
  inputs.nixpkgs.url = "nixpkgs";
  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
      f = import ./default.nix;
    in
    {
      overlay = (final: prev: {
        http2 = final.haskellPackages.callPackage f {};
      });
      packages = forAllSystems (system: {
         http2 = nixpkgsFor.${system}.http2;
      });
      defaultPackage = forAllSystems (system: self.packages.${system}.http2);
      checks = self.packages;
      devShell = forAllSystems (system: let haskellPackages = nixpkgsFor.${system}.haskellPackages;
        in haskellPackages.shellFor {
          packages = p: [self.packages.${system}.http2];
          withHoogle = true;
          buildInputs = with haskellPackages; [
            haskell-language-server
            cabal-install
          ];
        });
  };
}
