# This overlay provides `snowball`, a fun way to package up some (snow)flakes and throw it at another operating system!
### example
# sudo -i nix-env -f https://github.com/jpetrucciani/nix/archive/main.tar.gz -iA snowball.amazon-ssm-agent
# sudo ln -s /nix/var/nix/profiles/default/snowball/amazon-ssm-agent.service /etc/systemd/system/amazon-ssm-agent.service
# sudo systemctl daemon-reload
# sudo systemctl enable amazon-ssm-agent
final: prev:
let
  inherit (final.lib) attrNames concatMapStringsSep escapeShellArg filter fix foldl hasAttr hasPrefix hasSuffix mapAttrsToList optional optionalString recursiveUpdate replaceStrings;
  inherit (final.writers) writeBashBin;
  _merge = foldl recursiveUpdate { };

  defaults = {
    user = "root";
    group = "root";
    env = {
      SNOWBALL = "0.0.4";
      TZ = "America/New_York";
      TZDIR = "${final.tzdata}/share/zoneinfo";
    };
    wantedBy = [ "multi-user.target" ];
  };

  defaultPolicy = {
    enable = "preset";
    start = "if-enabled";
    upgrade = "try-restart";
    remove = "disable-stop";
    removeStorePaths = false;
  };

  sanitize = value: replaceStrings [ "/" " " ":" ] [ "-" "-" "-" ] value;
  rpmPackageName = name: "snowball-" + replaceStrings [ "_" ] [ "-" ] name;

  normalizeFile =
    bundleName: destination: spec:
    let
      normalized = if builtins.isAttrs spec then spec else { source = spec; };
      source =
        if normalized ? text then
          final.writeText "snowball-${bundleName}-${sanitize destination}" normalized.text
        else
          normalized.source;
      mode =
        normalized.mode or (if normalized ? executable && normalized.executable then "0755" else "0644");
      preserve = normalized.preserve or (hasPrefix "/etc/" destination);
    in
    {
      inherit destination mode preserve source;
    };

  installStagedFile =
    file: ''
      mkdir -p "$root$(dirname ${escapeShellArg file.destination})"
      install -D -m ${file.mode} ${escapeShellArg (toString file.source)} "$root${file.destination}"
    '';

  installUnit =
    unit: unitPath: ''
      mkdir -p "$root/usr/lib/systemd/system"
      install -D -m 0644 ${escapeShellArg "${unitPath}/${unit}"} "$root/usr/lib/systemd/system/${unit}"
    '';

  renderSystemdPost =
    { enableUnits, managedUnits, policy }:
    let
      presetLines = concatMapStringsSep "\n"
        (unit: ''
          systemctl preset ${unit} >/dev/null 2>&1 || :
        '')
        enableUnits;
      enableLines = concatMapStringsSep "\n"
        (unit: ''
          systemctl enable ${unit} >/dev/null 2>&1 || :
        '')
        enableUnits;
      ifEnabledStartLines = concatMapStringsSep "\n"
        (unit: ''
          if systemctl is-enabled ${unit} >/dev/null 2>&1; then
            systemctl start ${unit} >/dev/null 2>&1 || :
          fi
        '')
        managedUnits;
      alwaysStartLines = concatMapStringsSep "\n"
        (unit: ''
          systemctl start ${unit} >/dev/null 2>&1 || :
        '')
        managedUnits;
      tryRestartLines = concatMapStringsSep "\n"
        (unit: ''
          systemctl try-restart ${unit} >/dev/null 2>&1 || :
        '')
        managedUnits;
      restartLines = concatMapStringsSep "\n"
        (unit: ''
          systemctl restart ${unit} >/dev/null 2>&1 || :
        '')
        managedUnits;
      installEnable =
        if policy.enable == "preset" then presetLines
        else if policy.enable == "force" then enableLines
        else "";
      installStart =
        if policy.start == "if-enabled" then ifEnabledStartLines
        else if policy.start == "always" then alwaysStartLines
        else "";
      upgradeBody =
        if policy.upgrade == "try-restart" then tryRestartLines
        else if policy.upgrade == "restart" then restartLines
        else "";
    in
    ''
      if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload >/dev/null 2>&1 || :
        if [ "''${1:-1}" -eq 1 ]; then
          ${installEnable}
          ${installStart}
        else
          ${upgradeBody}
        fi
      fi
    '';

  renderSystemdPreun =
    { enableUnits, policy }:
    let
      disableLines = concatMapStringsSep "\n"
        (unit: ''
          systemctl --no-reload disable ${unit} >/dev/null 2>&1 || :
        '')
        enableUnits;
      disableStopLines = concatMapStringsSep "\n"
        (unit: ''
          systemctl --no-reload disable --now ${unit} >/dev/null 2>&1 || :
        '')
        enableUnits;
      body =
        if policy.remove == "disable" then disableLines
        else if policy.remove == "disable-stop" then disableStopLines
        else "";
    in
    ''
      if [ "''${1:-0}" -eq 0 ] && command -v systemctl >/dev/null 2>&1; then
        ${body}
      fi
    '';

  renderSystemdPostun = ''
    if command -v systemctl >/dev/null 2>&1; then
      systemctl daemon-reload >/dev/null 2>&1 || :
    fi
  '';

  renderSysusersPost =
    name:
    enabled:
    optionalString enabled ''
      if command -v systemd-sysusers >/dev/null 2>&1; then
        systemd-sysusers ${escapeShellArg "/usr/lib/sysusers.d/${name}.conf"} >/dev/null 2>&1 || :
      fi
    '';

  renderTmpfilesPost =
    name:
    enabled:
    optionalString enabled ''
      if command -v systemd-tmpfiles >/dev/null 2>&1; then
        systemd-tmpfiles --create ${escapeShellArg "/usr/lib/tmpfiles.d/${name}.conf"} >/dev/null 2>&1 || :
      fi
    '';

  buildRpm =
    { packageName
    , version
    , summary
    , description
    , license
    , buildArch
    , root
    , postScript
    , preunScript
    , postunScript
    }:
    final.runCommand "${packageName}-${version}.rpm"
      {
        nativeBuildInputs = with final; [
          coreutils
          findutils
          rpm
        ];
      } ''
            set -euo pipefail

            topdir="$PWD/rpmbuild"
            mkdir -p "$topdir"/BUILD "$topdir"/BUILDROOT "$topdir"/RPMS "$topdir"/SOURCES "$topdir"/SPECS "$topdir"/SRPMS "$PWD/tmp"

            filelist="$topdir/filelist"
            : >"$filelist"
            while IFS= read -r rel; do
              [ -n "$rel" ] || continue
              path="/''${rel#./}"
              full="${root}/''${rel#./}"
              if [ -L "$full" ]; then
                printf '%s\n' "$path" >>"$filelist"
              elif [ -d "$full" ]; then
                case "$path" in
                  /etc|/etc/systemd|/etc/systemd/system|/usr|/usr/lib|/usr/lib/systemd|/usr/lib/systemd/system|/usr/lib/tmpfiles.d|/usr/lib/sysusers.d|/usr/libexec|/usr/share)
                    continue
                    ;;
                  *)
                    printf '%%dir %s\n' "$path" >>"$filelist"
                    ;;
                esac
              elif [[ "$path" == /etc/* ]]; then
                printf '%%config(noreplace) %s\n' "$path" >>"$filelist"
              else
                printf '%s\n' "$path" >>"$filelist"
              fi
            done < <(cd ${root} && ${final.findutils}/bin/find . -mindepth 1 | LC_ALL=C sort)

            cat >"$topdir/SPECS/${packageName}.spec" <<EOF
      %global _build_id_links none
      Summary: ${summary}
      Name: ${packageName}
      Version: ${version}
      Release: 1
      License: ${license}
      BuildArch: ${buildArch}
      AutoReqProv: no

      %description
      ${description}

      %prep

      %build

      %install
      mkdir -p %{buildroot}
      cp -a ${root}/. %{buildroot}/

      %post
      ${postScript}

      %preun
      ${preunScript}

      %postun
      ${postunScript}

      %files -f %{_topdir}/filelist
      %defattr(-,root,root,-)
      EOF

            ${final.rpm}/bin/rpmbuild \
              --define "_topdir $topdir" \
              --define "_tmppath $PWD/tmp" \
              -bb "$topdir/SPECS/${packageName}.spec" >/dev/null

            rpm_path=$(${final.findutils}/bin/find "$topdir/RPMS" -type f -name '*.rpm' | head -n 1)
            cp "$rpm_path" "$out"
    '';

  _snowball =
    { name
    , conf
    , version ? defaults.env.SNOWBALL
    , summary ? "Snowball bundle ${name}"
    , description ? "Portable systemd bundle for ${name}"
    , license ? "Unspecified"
    , units ? null
    , files ? { }
    , tmpfiles ? [ ]
    , sysusers ? [ ]
    , policy ? { }
    , preInstall ? ""
    , postInstall ? ""
    , preUninstall ? ""
    , postUninstall ? ""
    , prePack ? ""
    , postPack ? ""
    , imports ? [ ]
    }:
    let
      defaults = { system.stateVersion = final.lib.mkDefault "25.05"; };
      empty = final.nixos defaults;
      os = final.nixos { imports = [ defaults ] ++ imports ++ [ conf ]; };
      uniqueKeys = a: b: filter (k: !hasAttr k b) (attrNames a);
      discovered-units = uniqueKeys os.config.systemd.units empty.config.systemd.units;
      systemd-units = if units != null then units else discovered-units;
      enable_units = filter (x: !(hasSuffix ".target" x)) systemd-units;
      timer_units = filter (x: hasSuffix ".timer" x) systemd-units;
      policy' = defaultPolicy // policy;
      normalized-files = mapAttrsToList (normalizeFile name) files;
      tmpfilesSource =
        if tmpfiles == [ ] then
          null
        else
          final.writeText "snowball-${name}.tmpfiles.conf" "${concatMapStringsSep "\n" (line: line) tmpfiles}\n";
      sysusersSource =
        if sysusers == [ ] then
          null
        else
          final.writeText "snowball-${name}.sysusers.conf" "${concatMapStringsSep "\n" (line: line) sysusers}\n";
      closureRoots =
        (map (unit: os.config.systemd.units.${unit}.unit) systemd-units)
        ++ (map (file: file.source) normalized-files)
        ++ optional (tmpfilesSource != null) tmpfilesSource
        ++ optional (sysusersSource != null) sysusersSource;
      buildArch =
        {
          x86_64-linux = "x86_64";
          aarch64-linux = "aarch64";
        }.${final.stdenv.hostPlatform.system} or final.stdenv.hostPlatform.parsed.cpu.name;
      staticManifest =
        builtins.toJSON
          {
            inherit name version summary description license;
            runtime = {
              bundlePath = null;
              closureRoots = map toString closureRoots;
              closureInfo = null;
            };
            hooks = {
              inherit preInstall postInstall preUninstall postUninstall prePack postPack;
            };
            policy = policy';
            units = map
              (unit: {
                inherit unit;
                installPath = "/usr/lib/systemd/system/${unit}";
                source = "${os.config.systemd.units.${unit}.unit}/${unit}";
              })
              systemd-units;
            files = map
              (file: {
                inherit (file) destination mode preserve;
                source = toString file.source;
              })
              normalized-files;
            tmpfiles = if tmpfilesSource == null then null else "/usr/lib/tmpfiles.d/${name}.conf";
            sysusers = if sysusersSource == null then null else "/usr/lib/sysusers.d/${name}.conf";
            discoveredUnits = discovered-units;
          };
    in
    fix (result:
    let
      closureInfo = final.closureInfo { rootPaths = closureRoots; };
      manifestBase = final.writeText "snowball_${name}_manifest_base.json" staticManifest;
      manifest = final.runCommand "snowball_${name}_manifest.json"
        {
          nativeBuildInputs = [ final.jq ];
        } ''
        set -euo pipefail
        closure_paths=$(${final.jq}/bin/jq -R -s 'split("\n") | map(select(length > 0))' ${closureInfo}/store-paths)
        ${final.jq}/bin/jq \
          --arg bundle_path ${escapeShellArg (toString result)} \
          --arg closure_info ${escapeShellArg (toString closureInfo)} \
          --argjson closure_paths "$closure_paths" \
          '.runtime.bundlePath = $bundle_path
          | .runtime.closureInfo = $closure_info
          | .runtime.closurePaths = $closure_paths' \
          ${manifestBase} >"$out"
      '';

      storefulRoot = final.runCommand "snowball_${name}_storeful_root"
        {
          nativeBuildInputs = [ final.coreutils ];
        } ''
        set -euo pipefail
        root="$out"
        mkdir -p "$root"

        while IFS= read -r path; do
          [ -n "$path" ] || continue
          dest="$root$path"
          mkdir -p "$(dirname "$dest")"
          cp -a "$path" "$dest"
        done < ${closureInfo}/store-paths

        ${concatMapStringsSep "\n" (unit: installUnit unit os.config.systemd.units.${unit}.unit) systemd-units}
        ${concatMapStringsSep "\n" installStagedFile normalized-files}
        ${optionalString (tmpfilesSource != null) ''
          mkdir -p "$root/usr/lib/tmpfiles.d"
          install -D -m 0644 ${escapeShellArg (toString tmpfilesSource)} "$root/usr/lib/tmpfiles.d/${name}.conf"
        ''}
        ${optionalString (sysusersSource != null) ''
          mkdir -p "$root/usr/lib/sysusers.d"
          install -D -m 0644 ${escapeShellArg (toString sysusersSource)} "$root/usr/lib/sysusers.d/${name}.conf"
        ''}
        mkdir -p "$root/usr/share/snowball/${name}"
        install -D -m 0644 ${escapeShellArg (toString manifest)} "$root/usr/share/snowball/${name}/manifest.json"
      '';

      portableRoot = final.runCommand "snowball_${name}_portable_root"
        {
          nativeBuildInputs = with final; [
            coreutils
            findutils
            gnugrep
            gnused
            patchelf
            ripgrep
          ];
        } ''
        set -euo pipefail

        root="$out"
        portable_prefix="/usr/lib/snowball/${name}"
        portable_store="$root$portable_prefix/store"
        mkdir -p "$portable_store"

        while IFS= read -r path; do
          [ -n "$path" ] || continue
          dest="$portable_store/$(${final.coreutils}/bin/basename "$path")"
          mkdir -p "$(dirname "$dest")"
          cp -a "$path" "$dest"
        done < ${closureInfo}/store-paths

        ${concatMapStringsSep "\n" (unit: installUnit unit os.config.systemd.units.${unit}.unit) systemd-units}
        ${concatMapStringsSep "\n" installStagedFile normalized-files}
        ${optionalString (tmpfilesSource != null) ''
          mkdir -p "$root/usr/lib/tmpfiles.d"
          install -D -m 0644 ${escapeShellArg (toString tmpfilesSource)} "$root/usr/lib/tmpfiles.d/${name}.conf"
        ''}
        ${optionalString (sysusersSource != null) ''
          mkdir -p "$root/usr/lib/sysusers.d"
          install -D -m 0644 ${escapeShellArg (toString sysusersSource)} "$root/usr/lib/sysusers.d/${name}.conf"
        ''}
        mkdir -p "$root/usr/share/snowball/${name}"
        install -D -m 0644 ${escapeShellArg (toString manifest)} "$root/usr/share/snowball/${name}/manifest.json"

        ${final.findutils}/bin/find "$root" -type d -exec chmod u+w '{}' +
        ${final.findutils}/bin/find "$root" -type f -exec chmod u+w '{}' +

        rewrite_refs() {
          local value="$1"
          while IFS= read -r store_path; do
            [ -n "$store_path" ] || continue
            value=$(${final.gnused}/bin/sed "s|$store_path|$portable_prefix/store/$(${final.coreutils}/bin/basename "$store_path")|g" <<<"$value")
          done < ${closureInfo}/store-paths
          printf '%s' "$value"
        }

        while IFS= read -r link; do
          target=$(${final.coreutils}/bin/readlink "$link")
          case "$target" in
            /nix/store/*)
              ln -sfn "$(rewrite_refs "$target")" "$link"
              ;;
          esac
        done < <(${final.findutils}/bin/find "$root" -type l)

        while IFS= read -r file; do
          [ -n "$file" ] || continue
          interpreter=$(${final.patchelf}/bin/patchelf --print-interpreter "$file" 2>/dev/null || true)
          if [ -n "$interpreter" ]; then
            ${final.patchelf}/bin/patchelf --set-interpreter "$(rewrite_refs "$interpreter")" "$file"
          fi
          rpath=$(${final.patchelf}/bin/patchelf --print-rpath "$file" 2>/dev/null || true)
          if [ -n "$rpath" ]; then
            ${final.patchelf}/bin/patchelf --set-rpath "$(rewrite_refs "$rpath")" "$file"
          fi
        done < <(
          ${final.findutils}/bin/find "$root$portable_prefix/store" -type f \
            \( -perm /111 -o -name '*.so' -o -name '*.so.*' \)
        )

        while IFS= read -r file; do
          [ -n "$file" ] || continue
          tmp="$file.snowball"
          cp "$file" "$tmp"
          while IFS= read -r store_path; do
            [ -n "$store_path" ] || continue
            ${final.gnused}/bin/sed -i "s|$store_path|$portable_prefix/store/$(${final.coreutils}/bin/basename "$store_path")|g" "$tmp"
          done < ${closureInfo}/store-paths
          if ! cmp -s "$file" "$tmp"; then
            mv "$tmp" "$file"
          else
            rm -f "$tmp"
          fi
        done < <(${final.ripgrep}/bin/rg -l -F '/nix/store/' "$root" || true)
      '';

      storefulManagedOwnedPaths = final.runCommand "snowball_${name}_storeful_managed_owned_paths"
        {
          nativeBuildInputs = with final; [
            coreutils
            findutils
            gawk
          ];
        } ''
        set -euo pipefail
        cd ${storefulRoot}
        ${final.findutils}/bin/find . -mindepth 1 -printf '/%P\n' \
          | while IFS= read -r path; do
              case "$path" in
                /nix|/nix/*)
                  ${if policy'.removeStorePaths then ''
                    printf '%s\n' "$path"
                  '' else ''
                    continue
                  ''}
                  ;;
                *)
                  printf '%s\n' "$path"
                  ;;
              esac
            done \
          | ${final.gawk}/bin/awk '{ print length($0), $0 }' \
          | sort -rn \
          | cut -d" " -f2- >"$out"
      '';

      scriptPayload = final.runCommand "snowball_${name}_payload.tar.gz"
        {
          nativeBuildInputs = with final; [
            coreutils
            gnutar
            gzip
          ];
        } ''
        set -euo pipefail
        tar -C ${storefulRoot} -czf "$out" .
      '';

      scriptPayloadBase64 = final.runCommand "snowball_${name}_payload.base64"
        {
          nativeBuildInputs = [ final.coreutils ];
        } ''
        set -euo pipefail
        base64 -w 76 ${scriptPayload} >"$out"
      '';

      systemdPostScript = renderSystemdPost {
        enableUnits = enable_units;
        managedUnits = enable_units;
        policy = policy';
      };
      systemdPreunScript = renderSystemdPreun {
        enableUnits = enable_units;
        policy = policy';
      };
      systemdPostunScript = renderSystemdPostun;
      sysusersPostScript = renderSysusersPost name (sysusersSource != null);
      tmpfilesPostScript = renderTmpfilesPost name (tmpfilesSource != null);

      script = final.runCommand "snowball_${name}_script.sh"
        {
          nativeBuildInputs = [ final.coreutils ];
        } ''
                  set -euo pipefail

                  cat >"$out" <<'EOF'
        #!${final.bash}/bin/bash
        set -euo pipefail

        require_root() {
          if [ "$(id -u)" -ne 0 ]; then
            echo "snowball installer must run as root" >&2
            exit 1
          fi
        }

        extract_payload() {
          local tmpdir="$1"
          local archive="$tmpdir/payload.tar.gz"
          cat <<'__SNOWBALL_PAYLOAD__' | base64 -d >"$archive"
        EOF
                  cat ${scriptPayloadBase64} >>"$out"
                  cat >>"$out" <<'EOF'
        __SNOWBALL_PAYLOAD__
          mkdir -p "$tmpdir/root"
          tar -xzf "$archive" -C "$tmpdir/root"
        }

        install_payload() {
          local tmpdir
          tmpdir=$(mktemp -d)
          trap 'rm -rf "$tmpdir"' RETURN

          require_root
          extract_payload "$tmpdir"

          if [ -d "$tmpdir/root/etc" ]; then
            while IFS= read -r rel; do
              target="/''${rel#./}"
              if [ -e "$target" ]; then
                rm -f "$tmpdir/root/''${rel#./}"
              fi
            done < <(cd "$tmpdir/root" && find ./etc -mindepth 1 \( -type f -o -type l \))
          fi

        ${preInstall}
          cp -a "$tmpdir/root/." /

        ${sysusersPostScript}
        ${tmpfilesPostScript}
        ${systemdPostScript}
        ${postInstall}
        }

        remove_payload() {
          require_root

        ${preUninstall}
        ${systemdPreunScript}
          while IFS= read -r path; do
            [ -n "$path" ] || continue
            case "$path" in
              /etc/*)
                continue
                ;;
            esac
            if [ -L "$path" ] || [ -f "$path" ]; then
              rm -f "$path" || :
            elif [ -d "$path" ]; then
              rmdir "$path" 2>/dev/null || :
            fi
          done <<'__SNOWBALL_OWNED_PATHS__'
        EOF
                  cat ${storefulManagedOwnedPaths} >>"$out"
                  cat >>"$out" <<'EOF'
        __SNOWBALL_OWNED_PATHS__

        ${systemdPostunScript}
        ${postUninstall}
        }

        case "''${1:-install}" in
          install)
            install_payload
            ;;
          uninstall)
            remove_payload
            ;;
          *)
            echo "usage: $0 [install|uninstall]" >&2
            exit 1
            ;;
        esac
        EOF
                  chmod +x "$out"
      '';

      rpm = buildRpm {
        packageName = rpmPackageName name;
        inherit version summary description license buildArch;
        root = storefulRoot;
        postScript = ''
          ${sysusersPostScript}
          ${tmpfilesPostScript}
          ${systemdPostScript}
          ${postInstall}
        '';
        preunScript = ''
          ${preUninstall}
          ${systemdPreunScript}
        '';
        postunScript = ''
          ${systemdPostunScript}
          ${postUninstall}
        '';
      };

      rpmPortable = buildRpm {
        packageName = "${rpmPackageName name}-portable";
        inherit version summary description license buildArch;
        root = portableRoot;
        postScript = ''
          ${sysusersPostScript}
          ${tmpfilesPostScript}
          ${systemdPostScript}
          ${postInstall}
        '';
        preunScript = ''
          ${preUninstall}
          ${systemdPreunScript}
        '';
        postunScript = ''
          ${systemdPostunScript}
          ${postUninstall}
        '';
      };

      tests = {
        manifest = final.runCommand "snowball_${name}_test_manifest"
          {
            nativeBuildInputs = [ final.jq ];
          } ''
          set -euo pipefail
          ${final.jq}/bin/jq -e --arg bundle_name ${escapeShellArg name} '.name == $bundle_name' ${manifest} >/dev/null
          ${final.jq}/bin/jq -e '.runtime.closurePaths | length > 0' ${manifest} >/dev/null
          ${final.jq}/bin/jq -e '.files | length == ${toString (builtins.length normalized-files)}' ${manifest} >/dev/null
          ${optionalString (systemd-units != [ ]) ''
            ${final.jq}/bin/jq -e --arg first_unit ${escapeShellArg (builtins.head systemd-units)} '.units | map(.unit) | index($first_unit) != null' ${manifest} >/dev/null
          ''}
          touch "$out"
        '';

        script = final.runCommand "snowball_${name}_test_script"
          {
            nativeBuildInputs = [ final.gnugrep ];
          } ''
          set -euo pipefail
          ${final.gnugrep}/bin/grep -q "usage: .*\\[install|uninstall\\]" ${script}
          ${concatMapStringsSep "\n" (unit: "${final.gnugrep}/bin/grep -q ${escapeShellArg unit} ${script}") systemd-units}
          touch "$out"
        '';

        rpm = final.runCommand "snowball_${name}_test_rpm"
          {
            nativeBuildInputs = with final; [
              coreutils
              cpio
              findutils
              gnugrep
              final.rpm
            ];
          } ''
          set -euo pipefail
          work="$PWD/unpack"
          mkdir -p "$work"
          cd "$work"
          ${final.rpm}/bin/rpm2cpio ${rpm} | ${final.cpio}/bin/cpio -id --quiet
          ${concatMapStringsSep "\n" (unit: "[ -f ./usr/lib/systemd/system/${unit} ]") systemd-units}
          ${concatMapStringsSep "\n" (file: "[ -e ${escapeShellArg ".${file.destination}"} ]") normalized-files}
          ${final.rpm}/bin/rpm -qlp ${rpm} >"$PWD/paths.txt"
          ! ${final.gnugrep}/bin/grep -Fx '/usr' "$PWD/paths.txt"
          ! ${final.gnugrep}/bin/grep -Fx '/usr/lib' "$PWD/paths.txt"
          ! ${final.gnugrep}/bin/grep -Fx '/usr/lib/systemd' "$PWD/paths.txt"
          ! ${final.gnugrep}/bin/grep -Fx '/usr/lib/systemd/system' "$PWD/paths.txt"
          ! ${final.gnugrep}/bin/grep -Fx '/usr/libexec' "$PWD/paths.txt"
          ! ${final.gnugrep}/bin/grep -Fx '/usr/share' "$PWD/paths.txt"
          [ -d ./nix/store ]
          touch "$out"
        '';

        rpmPortable = final.runCommand "snowball_${name}_test_rpm_portable"
          {
            nativeBuildInputs = with final; [
              coreutils
              cpio
              findutils
              gnugrep
              final.rpm
            ];
          } ''
          set -euo pipefail
          work="$PWD/unpack"
          mkdir -p "$work"
          cd "$work"
          ${final.rpm}/bin/rpm2cpio ${rpmPortable} | ${final.cpio}/bin/cpio -id --quiet
          ${concatMapStringsSep "\n" (unit: "[ -f ./usr/lib/systemd/system/${unit} ]") systemd-units}
          ${concatMapStringsSep "\n" (file: "[ -e ${escapeShellArg ".${file.destination}"} ]") normalized-files}
          ${final.rpm}/bin/rpm -qlp ${rpmPortable} >"$PWD/paths.txt"
          ! ${final.gnugrep}/bin/grep -Fx '/usr' "$PWD/paths.txt"
          ! ${final.gnugrep}/bin/grep -Fx '/usr/lib' "$PWD/paths.txt"
          ! ${final.gnugrep}/bin/grep -Fx '/usr/lib/systemd' "$PWD/paths.txt"
          ! ${final.gnugrep}/bin/grep -Fx '/usr/lib/systemd/system' "$PWD/paths.txt"
          ! ${final.gnugrep}/bin/grep -Fx '/usr/libexec' "$PWD/paths.txt"
          ! ${final.gnugrep}/bin/grep -Fx '/usr/share' "$PWD/paths.txt"
          [ -d ./usr/lib/snowball/${name}/store ]
          ${optionalString (systemd-units != [ ]) ''
            ! ${final.gnugrep}/bin/grep -q '/nix/store/' ./usr/lib/systemd/system/${builtins.head systemd-units}
          ''}
          touch "$out"
        '';
      };
    in
    final.buildEnv {
      name = "snowball_${name}";
      extraPrefix = "/snowball";
      paths = map (unit: os.config.systemd.units.${unit}.unit) systemd-units;
      passthru =
        let
          vars = ''
            _name="${name}"
            _units="${concatMapStringsSep " " (unit: unit) systemd-units}"
          '';
        in
        rec {
          inherit manifest rpm rpmPortable script tests;
          stage = {
            storeful = storefulRoot;
            portable = portableRoot;
          };
          install = (writeBashBin "install" ''
            _drv=${result}
            ${vars}
            # preInstall
            echo "[${name}] preInstall" >&2
            ${preInstall}
            sudo -i nix-env -i "$_drv"
            ${concatMapStringsSep "\n" (unit: ''sudo ln -sf /nix/var/nix/profiles/default/snowball/${unit} /etc/systemd/system/${unit}'') systemd-units}
            # install
            sudo systemctl daemon-reload
            # enable everything except targets
            ${concatMapStringsSep "\n" (unit: ''sudo systemctl enable ${unit}'') enable_units}

            # start timers
            ${concatMapStringsSep "\n" (unit: ''sudo systemctl start ${unit}'') timer_units}

            # postInstall
            echo "[${name}] postInstall" >&2
            ${postInstall}
          '').overrideAttrs { name = "snowball_${name}_install"; meta.mainProgram = "install"; };
          pack = (writeBashBin "pack" ''
            _install=${install}
            ${vars}
            # prePack
            echo "[${name}] prePack" >&2
            ${prePack}
            install_store_path=$(nix build --no-link --print-out-paths $_install)
            echo "built the snowball installer to $install_store_path" >&2

            # postPack
            echo "[${name}] postPack" >&2
            ${postPack}
          '').overrideAttrs { name = "snowball_${name}_pack"; };
        };
    });

  job =
    { name
    , script
    , description ? ""
    , user ? defaults.user
    , group ? defaults.group
    , _path ? with final; [ bash coreutils ]  # default paths to add (so we can remove if needed)
    , path ? [ ] # extra paths to append to _path
    , env ? { }
    , envFile ? null
    , calendar ? [ ]
    , needs ? [ ]
    , wantedBy ? defaults.wantedBy
    , onSuccess ? "echo 'success!'"
    , onFailure ? "echo 'failure!'"
    , extra ? { }
    }:
    let
      toServiceName = name: if hasSuffix ".service" name then name else name + ".service";
      all_paths = _path ++ path;
      after = map toServiceName needs;
    in
    assert (calendar != [ ] || needs != [ ]) || throw "you must specify a list of 'calendar' entries, or a list of 'needs'";
    {
      systemd.services = {
        ${name} = _merge [
          {
            inherit description script;
            path = all_paths;
            environment = defaults.env // env;
            ${if calendar != [ ] then "startAt" else null} = calendar;
            serviceConfig = {
              Group = group;
              User = user;
              ${if envFile != null then "EnvironmentFile" else null} = envFile;
            };
            inherit after;
            requires = after;
            unitConfig.PartOf = after;
            postStop = ''
              if [ $SERVICE_RESULT = "success" ]; then
                ${onSuccess}
              else
                ${onFailure}
              fi
            '';
            wantedBy = if needs == [ ] then wantedBy else after;
          }
          extra
        ];
      };
    };

  svc = { name, script, env ? { }, wantedBy ? defaults.wantedBy, extra ? { } }: {
    systemd.services.${name} = _merge [
      {
        inherit wantedBy script;
        environment = defaults.env // env;
      }
      extra
    ];
  };

  # examples/tests
  apiScript = final.writeText "snowball-api.py" ''
    #!/usr/bin/env -S uv run --script
    # /// script
    # requires-python = ">=3.13,<3.14"
    # dependencies = [
    #   "fastapi",
    #   "uvicorn",
    # ]
    # ///

    from __future__ import annotations

    import os

    from fastapi import FastAPI

    app = FastAPI()


    @app.get("/")
    def read_root() -> dict[str, str]:
        return {"message": "Hello World"}


    @app.get("/items/{item_id}")
    def read_item(item_id: int, q: str | None = None) -> dict[str, int | str | None]:
        return {"item_id": item_id, "q": q}


    def main() -> None:
        import uvicorn

        uvicorn.run(
            app,
            host=os.environ.get("SNOWBALL_API_HOST", "0.0.0.0"),
            port=int(os.environ.get("SNOWBALL_API_PORT", "8000")),
        )


    if __name__ == "__main__":
        main()
  '';
  job_x = job { name = "job_x"; script = ''echo 123 >/tmp/job_x.out.txt''; calendar = [ "minutely" ]; };
  job_y = job { name = "job_y"; script = ''cat /tmp/job_x.out.txt /tmp/job_x.out.txt /tmp/job_x.out.txt >/tmp/job_y.out.txt''; needs = [ "job_x" ]; };
  job_z = job { name = "job_z"; script = ''${final.busybox}/bin/wc -l /tmp/job_y.out.txt >/tmp/job_z.out.txt''; needs = [ "job_y" ]; };
in
{
  snowball =
    {
      # snowball tools
      templates = {
        inherit job svc;
      };
      tools = {
        inherit _merge _snowball;
      };
      pack = _snowball;

      # examples
      amazon-ssm-agent = _snowball { name = "amazon-ssm-agent"; conf = { services.amazon-ssm-agent.enable = true; }; };
      api =
        let
          python = final.python313;
          pythonPackages = with final.python313Packages; [
            fastapi
            uvicorn
          ];
          pythonPath = final.python313.pkgs.makePythonPath pythonPackages;
        in
        _snowball {
          name = "api";
          summary = "Snowball FastAPI example";
          description = "FastAPI example packaged with an explicit Python runtime for portable RPM installs";
          units = [ "snowball-api.service" ];
          files."/usr/libexec/snowball/api.py" = {
            source = apiScript;
            mode = "0755";
          };
          conf = {
            systemd.services.snowball-api = {
              description = "Snowball FastAPI example";
              wantedBy = [ "multi-user.target" ];
              environment = {
                PYTHONUNBUFFERED = "1";
                PYTHONPATH = pythonPath;
                SNOWBALL_API_HOST = "0.0.0.0";
                SNOWBALL_API_PORT = "8000";
              };
              serviceConfig = {
                DynamicUser = true;
                ExecStart = "${python}/bin/python /usr/libexec/snowball/api.py";
                Restart = "on-failure";
                RestartSec = 5;
              };
            };
          };
        };
      api-uv =
        _snowball {
          name = "api-uv";
          summary = "Snowball FastAPI example using uv";
          description = "FastAPI example that ships uv and lets the target host realize the script environment at runtime";
          units = [ "snowball-api-uv.service" ];
          files."/usr/libexec/snowball/api.py" = {
            source = apiScript;
            mode = "0755";
          };
          conf = {
            systemd.services.snowball-api-uv = {
              description = "Snowball FastAPI example via uv";
              wantedBy = [ "multi-user.target" ];
              path = [ final.uv ];
              environment = {
                HOME = "%S/snowball-api-uv";
                PYTHONUNBUFFERED = "1";
                SNOWBALL_API_HOST = "0.0.0.0";
                SNOWBALL_API_PORT = "8001";
                UV_CACHE_DIR = "%C/snowball-api-uv";
                XDG_CACHE_HOME = "%C";
              };
              serviceConfig = {
                CacheDirectory = "snowball-api-uv";
                DynamicUser = true;
                ExecStart = "/usr/libexec/snowball/api.py";
                Restart = "on-failure";
                RestartSec = 5;
                StateDirectory = "snowball-api-uv";
                TimeoutStartSec = 300;
                WorkingDirectory = "%S/snowball-api-uv";
              };
            };
          };
        };
      nvme-exporter = _snowball { name = "nvme-exporter"; conf = { imports = [ ../hosts/modules/exporters/nvme.nix ]; services.nvme-exporter.enable = true; }; };
      earlyoom = _snowball {
        name = "earlyoom";
        conf = {
          systemd.services.earlyoom.serviceConfig.ExecStart = "${final.earlyoom}/bin/earlyoom";
          services.earlyoom = {
            enable = true;
            freeSwapThreshold = 10;
            freeMemThreshold = 10;
            extraArgs = [
              "-g"
              "--avoid '(^|/)(sshd|systemd|kubelet)$'"
              "--prefer '(^|/)(python.*|node)$'"
            ];
          };
        };
      };

      _examples = {
        example_jobset = _snowball { name = "job_test"; conf = _merge [ job_x job_y job_z ]; };
      };
    };
}
