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
    details: 'The repo starts from one pinned <code>nixpkgs</code>, Nix''s main package collection, then layers flake inputs and local overlays on top so packages and machines share the same foundation.'
    link: /architecture
    linkText: Read the architecture

  - icon: 🧰
    title: Daily Entry Point
    details: '<code>home.nix</code> is the main <a href="/home-manager">Home Manager guide in this site</a>, and it builds on <a href="https://github.com/nix-community/home-manager" target="_blank" rel="noreferrer">Home Manager itself</a> to power shell tools, wrappers, and per-machine user environments.'

  - icon: 📦
    title: More Than Packages
    details: 'Custom derivations, reusable modules, and higher-level overlays coexist here instead of being split across separate Nix repos.'
    link: /packages/index
    linkText: Browse packages

  - icon: 🖥️
    title: Repo-Specific Tooling
    details: '<a href="/tooling/pog"><code>pog</code></a>, <a href="/tooling/hex"><code>hex</code></a>, <a href="/tooling/snowball"><code>snowball</code></a>, <a href="/tooling/hms-and-hmx"><code>hms</code></a>, and <a href="/tooling/scripts">checked script outputs</a> are part of the story, not side quests. Start with the <a href="/tooling/index">tooling overview</a>.'

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
