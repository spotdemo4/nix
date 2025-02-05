{
  description = "Nixos config flake";

  # Use Cachix https://wiki.hyprland.org/Nix/Cachix/
  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];

    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Use Lix https://lix.systems/
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.1-1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen browser
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # Catppuccin
    catppuccin.url = "github:catppuccin/nix";
    catppuccin-vsc.url = "https://flakehub.com/f/catppuccin/vscode/*.tar.gz";

    # Hyprland
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix vscode extensions
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    # Filebrowser-upload
    filebrowser-upload.url = "github:spotdemo4/filebrowser-upload";

    # Trevbar
    trevbar.url = "github:spotdemo4/trevbar";
  };

  outputs = { self, nixpkgs, lix-module, ... }@inputs: {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [ 
        ./hosts/laptop/configuration.nix 
        lix-module.nixosModules.default
      ];
    };
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/desktop/configuration.nix
        lix-module.nixosModules.default
      ];
    };
    nixosConfigurations.server = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/server/configuration.nix
        lix-module.nixosModules.default
      ];
    };
  };
}
