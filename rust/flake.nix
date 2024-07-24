{
  description = "Basic Rust flake with home-manager module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
  };

  outputs = { self, nixpkgs, }:
    let
      project = "project";
      mod = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.programs.${project};
          tomlFormat = pkgs.formats.toml { };
        in
        {
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

            xdg.configFile."${project}/config.toml" = lib.mkIf (cfg.settings != { }) {
              source = tomlFormat.generate "config.toml" cfg.settings;
            };
          };
        };
    in
    {
      nixosModules.${project} = mod;
      nixosModules.default = self.nixosModules.${project};

      overlays.default = (final: prev:
        with final;
        {
          page-rs = pkgs.rustPlatform.buildRustPackage {
            pname = "${project}";
            version = "0.1.0";
            src = ./.;

            cargoLock = {
              lockFile = ./Cargo.lock;
            };
          };
        });
    };
}
