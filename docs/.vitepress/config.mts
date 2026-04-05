import footnote from 'markdown-it-footnote';
import { defineConfig } from 'vitepress';

const base = process.env.DOCS_BASE || '/';
const iconHref = `${base}nixos.svg`;

const referenceItems = [
  { text: 'Reference Home', link: '/reference/index' },
  { text: 'Generated Host Index', link: '/reference/generated-hosts' },
  { text: 'Generated Module Index', link: '/reference/generated-modules' },
  { text: 'Generated Package Index', link: '/reference/generated-packages' },
  { text: 'Generated Wrapper Index', link: '/reference/generated-wrappers' },
  { text: 'Generated Script Index', link: '/reference/generated-scripts' },
  { text: 'Generated Workflow Index', link: '/reference/generated-workflows' }
];

export default defineConfig({
  title: 'jpetrucciani/nix',
  description: 'Pinned nixpkgs, layered overlays, custom packages, host configs, and repo-specific tooling',
  base,
  cleanUrls: true,
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: iconHref }],
    ['link', { rel: 'shortcut icon', href: iconHref }],
    ['meta', { name: 'theme-color', content: '#2f6fed' }],
  ],
  themeConfig: {
    logo: iconHref,
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Getting Started', link: '/getting-started' },
      { text: 'Learn Nix', link: '/learn-nix' },
      { text: 'Architecture', link: '/architecture' },
      { text: 'Tooling', link: '/tooling/index' },
      { text: 'Reference', link: '/reference/index' }
    ],
    sidebar: [
      {
        text: 'Start',
        items: [
          { text: 'Home', link: '/' },
          { text: 'Getting Started', link: '/getting-started' },
          { text: 'Learn Nix', link: '/learn-nix' },
          { text: 'Case Study', link: '/case-study-poglets' },
          { text: 'Architecture', link: '/architecture' }
        ]
      },
      {
        text: 'Core Layers',
        items: [
          { text: 'Home Manager', link: '/home-manager' },
          { text: 'Hosts', link: '/hosts/index' },
          { text: 'Modules', link: '/modules/index' },
          { text: 'Packages', link: '/packages/index' }
        ]
      },
      {
        text: 'Tooling',
        items: [
          { text: 'Tooling Overview', link: '/tooling/index' },
          { text: 'pog', link: '/tooling/pog' },
          { text: 'kshell', link: '/tooling/kshell' },
          { text: 'hex', link: '/tooling/hex' },
          { text: 'snowball', link: '/tooling/snowball' },
          { text: 'foundry', link: '/tooling/foundry' },
          { text: 'mica', link: '/tooling/mica' },
          { text: 'hms and hmx', link: '/tooling/hms-and-hmx' },
          { text: 'scripts Outputs', link: '/tooling/scripts' }
        ]
      },
      {
        text: 'Operations',
        items: [
          { text: 'Daily Workflows', link: '/daily-workflows' },
          { text: 'Secrets', link: '/secrets' },
          { text: 'CI and Automation', link: '/ci-and-automation' }
        ]
      },
      {
        text: 'Reference',
        items: referenceItems
      }
    ],
    socialLinks: [{ icon: 'github', link: 'https://github.com/jpetrucciani/nix' }],
    search: {
      provider: 'local'
    }
  },
  markdown: {
    config: (md) => {
      md.use(footnote);
    }
  }
});
