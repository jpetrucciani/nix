# [`deepseek-harness`](https://github.com/deepseek-ai/deepseek-harness) is an open-source agent harness developed by DeepSeek AI
{ lib
, stdenv
, fetchFromGitHub
, fetchPnpmDeps
, pnpmConfigHook
, pnpm_11
, nodejs_24
, makeWrapper
, autoPatchelfHook
, pkgsStatic
, bash
, git
, ncurses
}:
let
  pnpm = pnpm_11.override { nodejs-slim = nodejs_24; };
  rev = "b150a551b8d465e31e418e1b2eaf5e79bbb7d28e";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "deepseek-harness";
  version = "0.1.1-rc.2";

  src = fetchFromGitHub {
    owner = "deepseek-ai";
    repo = "deepseek-harness";
    inherit rev;
    hash = "sha256-rrjXoyccTxKIbZ00Z4Vy7EA9tGZ15WUqLBFnZSgw1YE=";
  };

  pnpmDeps = (fetchPnpmDeps.override { inherit pnpm; }) {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 4;
    hash = "sha256-+PsdK9u3ZKv4XtSc8tBKKP48J/95/CGTMIUf8Q8dbok=";
  };

  nativeBuildInputs = [
    nodejs_24
    pnpm
    (pnpmConfigHook.override { inherit pnpm; })
    makeWrapper
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    ncurses
  ];

  # Koffi ships glibc and musl variants together. The glibc binary is the one
  # selected on NixOS; its dormant musl sibling keeps its musl loader reference.
  autoPatchelfIgnoreMissingDeps = lib.optionals stdenv.hostPlatform.isLinux [
    "libc.musl-*.so.*"
  ];

  env.DSH_CLIENT_COMMIT_HASH = rev;

  buildPhase = ''
    runHook preBuild

    pnpm run build:official

    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      mkdir -p native/landlock-run/packages/linux-${stdenv.hostPlatform.node.arch}/bin
      ${lib.getExe pkgsStatic.stdenv.cc} \
        -std=c11 -Os -Wall -Wextra -Werror -static -s \
        -o native/landlock-run/packages/linux-${stdenv.hostPlatform.node.arch}/bin/landlock-run \
        native/landlock-run/packages/entry/src/main.c
    ''}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Upstream's packed-install verification installs every published DSH and
    # vendored package at the consumer root. Reproduce that topology so the
    # workspace peer dependencies remain resolvable after pnpm deploy.
    node --input-type=module <<'EOF'
    import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs'
    import { dirname, posix } from 'node:path'
    import { dump, load } from 'js-yaml'

    const manifests = [
      ...readdirSync('vendor').map(name => posix.join('vendor', name, 'package.json')),
      ...readdirSync('packages', { withFileTypes: true })
        .filter(entry => entry.isDirectory() && entry.name !== 'experimental')
        .flatMap(({ name: group }) =>
          readdirSync(posix.join('packages', group), { withFileTypes: true })
            .filter(entry => entry.isDirectory())
            .map(({ name }) => posix.join('packages', group, name, 'package.json')),
      ),
      'apps/web/package.json',
      'native/landlock-run/packages/entry/package.json',
    ].filter(existsSync).map(path => ({
      directory: dirname(path),
      manifest: JSON.parse(readFileSync(path, 'utf8')),
    }))

    const cliPath = 'apps/cli/package.json'
    const cli = JSON.parse(readFileSync(cliPath, 'utf8'))
    cli.dependencies = Object.fromEntries([
      ...Object.entries(cli.dependencies ?? {}),
      ...manifests.map(({ manifest }) => [manifest.name, 'workspace:*']),
    ].sort(([left], [right]) => left.localeCompare(right)))
    for (const { manifest } of manifests) delete cli.devDependencies?.[manifest.name]
    writeFileSync(cliPath, JSON.stringify(cli, null, 2) + '\n')

    const lockPath = 'pnpm-lock.yaml'
    const lock = load(readFileSync(lockPath, 'utf8'))
    const dependencies = lock.importers['apps/cli'].dependencies
    for (const { directory, manifest } of manifests) {
      dependencies[manifest.name] = {
        specifier: 'workspace:*',
        version: 'link:' + posix.relative('apps/cli', directory),
      }
      delete lock.importers['apps/cli'].devDependencies?.[manifest.name]
    }
    lock.importers['apps/cli'].dependencies = Object.fromEntries(
      Object.entries(dependencies).sort(([left], [right]) => left.localeCompare(right)),
    )
    writeFileSync(lockPath, dump(lock, { lineWidth: -1, noRefs: true }))
    EOF

    pnpm --filter @deepseek-ai/dsh \
      --prod \
      --offline \
      --ignore-scripts \
      --config.inject-workspace-packages=true \
      --config.node-linker=hoisted \
      --config.link-workspace-packages=true \
      deploy \
      "$out/libexec/deepseek-harness"

    find "$out/libexec/deepseek-harness" -type f -name spawn-helper -exec chmod +x {} +

    # The HMR service needs Node's module-loader internals. Its native fallback
    # cannot recognize the stripped Node executable shipped by nixpkgs.
    makeWrapper ${lib.getExe nodejs_24} "$out/bin/dsh" \
      --add-flags "--expose-internals" \
      --add-flags "$out/libexec/deepseek-harness/lib/bin.js" \
      --prefix PATH : ${lib.makeBinPath [ bash git nodejs_24 pnpm ]} \
      ${lib.optionalString stdenv.hostPlatform.isLinux ''--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]}''}

    runHook postInstall
  '';

  # Sharp's native addon deliberately uses an ELF RPATH so libvips remains
  # visible to its transitive dependencies. autoPatchelf converts that RPATH to
  # a RUNPATH, which makes importing Sharp segfault. Keep those upstream files
  # intact and expose the Nix C++ runtime through the wrapper instead.
  preFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    sharpNativeBackup=$(mktemp -d)
    mv "$out/libexec/deepseek-harness/node_modules/@img/sharp-linux-${stdenv.hostPlatform.node.arch}" "$sharpNativeBackup/"
    mv "$out/libexec/deepseek-harness/node_modules/@img/sharp-libvips-linux-${stdenv.hostPlatform.node.arch}" "$sharpNativeBackup/"

    restoreSharpNative() {
      mv "$sharpNativeBackup/sharp-linux-${stdenv.hostPlatform.node.arch}" "$out/libexec/deepseek-harness/node_modules/@img/"
      mv "$sharpNativeBackup/sharp-libvips-linux-${stdenv.hostPlatform.node.arch}" "$out/libexec/deepseek-harness/node_modules/@img/"
    }
    postFixupHooks+=(restoreSharpNative)
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    test "$("$out/bin/dsh" --version)" = "${finalAttrs.version}"
    DSH_HOME="$TMPDIR/dsh-home" "$out/bin/dsh" --profile web --dump-default-config > /dev/null

    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      "$out/libexec/deepseek-harness/node_modules/@deepseek-ai/node-addon-landlock-run-linux-${stdenv.hostPlatform.node.arch}/bin/landlock-run" --probe
    ''}

    DSH_HOME="$TMPDIR/dsh-home" DSH_TELEMETRY_DISABLED=1 \
      "$out/bin/dsh" web --no-open --port 0 > "$TMPDIR/dsh-web.log" 2>&1 &
    webPid=$!
    stopWeb() {
      kill "$webPid" 2>/dev/null || true
      wait "$webPid" 2>/dev/null || true
    }
    trap stopWeb EXIT

    webReady=
    for _ in $(seq 1 100); do
      if ! kill -0 "$webPid" 2>/dev/null; then
        cat "$TMPDIR/dsh-web.log"
        exit 1
      fi
      webUrl=$(sed -n 's#^dsh web: \(http://127\.0\.0\.1:[0-9][0-9]*\)$#\1#p' "$TMPDIR/dsh-web.log" | head -n 1)
      if [ -n "$webUrl" ] && ${lib.getExe nodejs_24} -e \
        "fetch(process.argv[1]).then(response => process.exit(response.ok ? 0 : 1)).catch(() => process.exit(1))" \
        "$webUrl"
      then
        webReady=1
        break
      fi
      sleep 0.1
    done
    if [ -z "$webReady" ]; then
      cat "$TMPDIR/dsh-web.log"
      exit 1
    fi

    stopWeb
    trap - EXIT

    runHook postInstallCheck
  '';

  meta = {
    description = "Open-source agent harness developed by DeepSeek AI";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "dsh";
    platforms = lib.platforms.unix;
  };
})
