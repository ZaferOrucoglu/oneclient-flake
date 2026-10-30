{
  description = "Nix flake for OneClient";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = nixpkgs.legacyPackages;
    in
    {
      packages = forAllSystems (system: {
        oneclient = pkgsFor.${system}.callPackage ./package.nix { };
        default = self.packages.${system}.oneclient;
      });

      checks = forAllSystems (system: {
        inherit (self.packages.${system}) oneclient;
      });

      apps = forAllSystems (system:
        let
          pkgs = pkgsFor.${system};
          updateScript = pkgs.writeShellApplication {
            name = "update-oneclient";
            runtimeInputs = with pkgs; [ curl jq gnugrep gnused nix git coreutils ];
            text = ''
              exec ${./update.sh} "$@"
            '';
          };
        in
        {
          oneclient = {
            type = "app";
            program = "${self.packages.${system}.oneclient}/bin/oneclient";
            meta = {
              description = "OneClient";
            };
          };
          update = {
            type = "app";
            program = "${updateScript}/bin/update-oneclient";
            meta = {
              description = "Update OneClient package to the latest release";
            };
          };
          default = self.apps.${system}.oneclient;
        });

      overlays.default = final: prev: {
        oneclient = self.packages.${final.system}.oneclient;
      };

      nixosModules.default = { pkgs, ... }: {
        environment.systemPackages = [
          self.packages.${pkgs.stdenv.hostPlatform.system}.oneclient
        ];
      };
    };
}
