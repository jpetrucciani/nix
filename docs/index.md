---
layout: home

hero:
  name: 'jpetrucciani/nix'
  text: 'nixpkgs pins, custom overlays, and other abstractions'
  tagline: A personal Nix repo that turns one pinned package set into machines, user environments, custom packages, and practical tooling
  actions:
    - theme: brand
      text: Get Started
      link: /getting-started
    - theme: alt
      text: Read the Architecture
      link: /architecture
    - theme: alt
      text: View on GitHub
      link: https://github.com/jpetrucciani/nix

features:
  - icon: ❄️
    title: One Pinned Base
    details: "The repo starts from one pinned <code>nixpkgs</code>, Nix's main package collection, then layers flake inputs and local overlays on top so packages and machines share the same foundation."
    link: /architecture
    linkText: Read the architecture

  - icon: 🧰
    title: Daily Entry Point
    details: '<code>home.nix</code> configures the daily user environment with Home Manager, including shell tools, wrappers, and editor setup.'
    link: /home-manager
    linkText: Explore Home Manager

  - icon: 📦
    title: More Than Packages
    details: 'Custom derivations, reusable modules, and higher-level overlays coexist here instead of being split across separate Nix repos.'
    link: /packages/index
    linkText: Browse packages

  - icon: 🖥️
    title: Repo-Specific Tooling
    details: '<code>pog</code>, <code>hex</code>, <code>snowball</code>, <code>foundry</code>, and rebuild helpers turn the package set into daily workflows.'
    link: /tooling/index
    linkText: Browse tooling

  - icon: 🔐
    title: Multi-Host Layering
    details: 'NixOS and nix-darwin hosts share modules, constants, and package overlays while keeping machine-specific differences isolated.'
    link: /hosts/index
    linkText: Explore hosts

  - icon: ✅
    title: Curated + Generated Docs
    details: 'Guide pages explain the important ideas, and generated reference indexes cover the full repo surface when you need exact paths.'
    link: /reference/index
    linkText: Open reference
---
