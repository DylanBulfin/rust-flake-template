{
  description = "Basic Rust flake with home-manager module";

  # inputs = { nixpkgs.url = "github:NixOS/nixpkgs/release-24.05"; };
  inputs = {
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, fenix, nixpkgs, }:
    let
      system = "x86_64-linux";
      systemPkgs = nixpkgs.legacyPackages.${system};

      ####################################################################################
      ## User Inputs:
      cargoFile = ./Cargo.toml;
      lockFile = ./Cargo.lock;

      # If you want to use a regular toolchain, set this to either: "stable", "beta",
      # "nightly"
      toolchainName = "stable";

      # If you want to use the toolchain specified by a file, set the file path here. If
      # it is not null it will overwrite the toolchainName setting. One of these settings
      # must be set
      toolchainFile = null;
      # If the toolchainFile is non-null it needs an SHA which it reads from here. When
      # you first build it it will throw an error which will show the real SHA. Haven't
      # found a better way around it yet
      toolchainSha256 = systemPkgs.lib.fakeSha256;
      deps = with systemPkgs;
        [
          # Put dependencies here
        ];
      native-deps = with systemPkgs;
        [
          # Put native dependencies here
        ];

      ## End of User Inputs
      ####################################################################################

      toolchain = if toolchainFile == null then
        (if toolchainName == "stable" then
          fenix.packages.${system}.stable.toolchain
        else if toolchainName == "beta" then
          fenix.packages.${system}.beta.toolchain
        else if toolchainName == "nightly" then
          fenix.packages.${system}.minimal.toolchain
        else
          abort "Can only select stable, beta, or nightly toolchain by name")
      else
        fenix.packages.${system}.fromToolchainFile {
          file = toolchainFile;
          sha256 = toolchainSha256;
        };

      rustPlatform = systemPkgs.makeRustPlatform {
        cargo = toolchain;
        rustc = toolchain;
      };

      parsedToml = builtins.fromTOML (builtins.readFile cargoFile);
      project = parsedToml.package.name;
      version = parsedToml.package.version;

      package = rustPlatform.buildRustPackage {
        pname = "${project}";
        version = "${version}";
        src = ./.;

        buildInputs = deps;

        nativeBuildInputs = native-deps;

        cargoLock = { lockFile = lockFile; };
      };
      mod = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.programs.${project};
          tomlFormat = pkgs.formats.toml { };
        in {
          options = {
            programs.${project} = {
              enable = mkEnableOption "${project}";

              package = mkOption {
                type = types.package;
                default = pkgs.${project};
                defaultText = literalExpression "pkgs.${project}";
                description = "The ${project} package to install.";
              };

              settings = mkOption {
                type = tomlFormat.type;
                default = { };
                example = literalExpression ''
                  {
                    option1 = "string"
                    option2 = 1
                    
                    section = {
                      option3 = 1.0
                    }
                  }
                '';
                description = ''
                  Configuration written to
                  {file}`$XDG_CONFIG_HOME/${project}/config.toml`
                '';
              };
            };
          };

          config = mkIf cfg.enable {
            home.packages = [ cfg.package ];

            xdg.configFile."${project}/config.toml" =
              lib.mkIf (cfg.settings != { }) {
                source = tomlFormat.generate "config.toml" cfg.settings;
              };
          };
        };
    in {
      nixosModules.${project} = mod;
      nixosModules.default = self.nixosModules.${project};

      packages.${system}.default = package;

      devShell = systemPkgs.mkShell { inputsFrom = [ package ]; };

      overlays.default = (final: prev: with final; { "${project}" = package; });
    };
}
