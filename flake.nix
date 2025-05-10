{
  description = "zig utilities";
  inputs = {
    nixpkgs     .url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils .url = "github:numtide/flake-utils";
    flake-parts .url = "github:hercules-ci/flake-parts";
    zig2nix     .url = "github:Cloudef/zig2nix";
  };
  outputs = inputs @ {
    flake-utils,
    flake-parts,
    zig2nix,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = flake-utils.lib.defaultSystems;
      perSystem = {
        system,
        pkgs,
        ...
      }: let
        zigCompiler = zig2nix.packages.${system}.zig-0_13_0;
        # zigEnv = zig2nix."zig-env".${system} {
        #   nixpkgs = inputs.nixpkgs;
        #   zig = zigCompiler;
        # };
        # whiterun = zigEnv.package {
        #   pname = "whiterun";
        #   version = "0.1.0";
        #   src = pkgs.lib.cleanSource ./.;
        # };
      in {
        # packages.whiterun = whiterun;
        # packages.default = whiterun;
        # apps.run = {
        #   type = "app";
        #   program = "${whiterun}/bin/whiterun";
        # };
        devShells.default = pkgs.mkShell {
          buildInputs = [
            zigCompiler
            # whiterun
          ];
        };
      };
    };
}
