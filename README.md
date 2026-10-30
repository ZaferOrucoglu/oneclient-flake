# OneClient Flake

[![CI Build Check](https://github.com/ZaferOrucoglu/oneclient-flake/actions/workflows/check.yml/badge.svg)](https://github.com/ZaferOrucoglu/oneclient-flake/actions/workflows/check.yml)
[![Auto Update OneClient](https://github.com/ZaferOrucoglu/oneclient-flake/actions/workflows/update.yml/badge.svg)](https://github.com/ZaferOrucoglu/oneclient-flake/actions/workflows/update.yml)

Nix flake for [OneClient / OneLauncher](https://github.com/Polyfrost/OneLauncher) — a modern, open-source Minecraft launcher with built-in client support.

This flake packages the official Linux AppImage using Nixpkgs' `appimageTools.wrapType2`, avoiding heavy from-source compilation while ensuring a sandboxed and reproducible runtime. It includes automated GitHub Actions for daily upstream release checks and automatic updates.

---

## Features

- **Fast & Lightweight:** Uses official AppImage releases wrapped via `appimageTools`, building in seconds rather than compiling Chromium/Rust from source.
- **Daily Auto-Updates:** GitHub Actions workflow automatically checks for new upstream releases, updates package hashes, tests the build, and creates PRs/commits.
- **Flake Integration:** Provides packages, apps, overlays, and a NixOS module out of the box.

---

## Usage

### Direct Run

Run OneClient without permanent installation:

```bash
nix run github:ZaferOrucoglu/oneclient-flake
```

### In NixOS Configuration (`flake.nix`)

1. Add the flake to your `inputs`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    oneclient = {
      url = "github:ZaferOrucoglu/oneclient-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, oneclient, ... }@inputs: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      # ...
      modules = [
        # Option A: Import as a NixOS module
        oneclient.nixosModules.default

        # Option B: Or add directly to environment.systemPackages
        # ({ pkgs, ... }: {
        #   environment.systemPackages = [
        #     oneclient.packages.${pkgs.stdenv.hostPlatform.system}.default
        #   ];
        # })
      ];
    };
  };
}
```

### Overlay

You can apply `oneclient.overlays.default` to add `pkgs.oneclient` to your Nixpkgs instance:

```nix
nixpkgs.overlays = [
  oneclient.overlays.default
];
```

---

## Maintenance & Updating

To manually check for upstream updates and bump `package.nix`:

```bash
# Using the flake app
nix run .#update

# Or directly via bash script
./update.sh
```

---

## License

The packaging and flake files are licensed under the [MIT License](LICENSE). OneClient itself is licensed under the GPL-3.0 License.
