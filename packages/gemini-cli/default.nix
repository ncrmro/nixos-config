{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  jq,
  pkg-config,
  clang_20,
  libsecret,
  ripgrep,
  nodejs_22,
  nix-update-script,
}:

buildNpmPackage (finalAttrs: {
  pname = "gemini-cli";
  version = "0.26.0";

  src = fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-wvCSYr5BUS5gggTFHfG+SRvgAyRE63nYdaDwH98wurI=";
  };

  nodejs = nodejs_22;

  npmDepsHash = "sha256-nfmIt+wUelhz3KiW4/pp/dGE71f2jsPbxwpBRT8gtYc=";

  dontPatchElf = stdenv.isDarwin;

  nativeBuildInputs = [
    jq
    pkg-config
  ]
  ++ lib.optionals stdenv.isDarwin [ clang_20 ]; # clang_21 breaks @vscode/vsce's optionalDependencies keytar

  buildInputs = [
    ripgrep
    libsecret
  ];

  preConfigure = ''
    mkdir -p packages/generated
    echo "export const GIT_COMMIT_INFO = { commitHash: '${finalAttrs.src.rev}' };" > packages/generated/git-commit.ts
  '';

  postPatch = ''
    # Remove node-pty dependencies (including lydell fork)
    ${jq}/bin/jq '.optionalDependencies |= with_entries(select(.key | contains("node-pty") | not))' package.json > package.json.tmp && mv package.json.tmp package.json
    ${jq}/bin/jq '.optionalDependencies |= with_entries(select(.key | contains("node-pty") | not))' packages/core/package.json > packages/core/package.json.tmp && mv packages/core/package.json.tmp packages/core/package.json

    # Fix ripgrep path for SearchText; ensureRgPath() on its own may return the path to a dynamically-linked ripgrep binary without required libraries
    substituteInPlace packages/core/src/tools/ripGrep.ts \
      --replace-fail "await ensureRgPath();" "'${lib.getExe ripgrep}';"

    # Disable auto-update default in schema
    sed -i '/enableAutoUpdate: {/,/}/ s/default: true/default: false/' packages/cli/src/config/settingsSchema.ts
    sed -i '/enableAutoUpdateNotification: {/,/}/ s/default: true/default: false/' packages/cli/src/config/settingsSchema.ts

    # Force disable update notifications in code (Longer match first to avoid prefix collision)
    substituteInPlace packages/cli/src/utils/handleAutoUpdate.ts \
      --replace-fail "settings.merged.general.enableAutoUpdateNotification" "false"
    substituteInPlace packages/cli/src/ui/utils/updateCheck.ts \
      --replace-fail "settings.merged.general.enableAutoUpdateNotification" "false"

    # Force disable auto-update in code
    substituteInPlace packages/cli/src/utils/handleAutoUpdate.ts \
      --replace-fail "settings.merged.general.enableAutoUpdate" "false"

    # Remove node-pty import from shellExecutionService.ts
    substituteInPlace packages/core/src/services/shellExecutionService.ts \
      --replace-fail "import type { IPty } from '@lydell/node-pty';" "type IPty = any;"

    # Disable PTY support in getPty.ts but keep type definition compatible with ShellExecutionResult and Config
    echo "export type PtyImplementation = { module: any; name: 'lydell-node-pty' | 'node-pty'; } | null; export interface PtyProcess {}; export const getPty = async (): Promise<PtyImplementation> => null;" > packages/core/src/utils/getPty.ts
  '';

  # Prevent npmDeps and python from getting into the closure
  disallowedReferences = [
    finalAttrs.npmDeps
    nodejs_22.python
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,share/gemini-cli}

    npm prune --omit=dev

    # Remove python files to prevent python from getting into the closure
    find node_modules -name "*.py" -delete
    # keytar/build has gyp-mac-tool with a Python shebang that gets patched,
    # creating a python3 reference in the closure
    rm -rf node_modules/keytar/build

    cp -r node_modules $out/share/gemini-cli/

    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-core
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-a2a-server
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-test-utils
    rm -f $out/share/gemini-cli/node_modules/gemini-cli-vscode-ide-companion
    cp -r packages/cli $out/share/gemini-cli/node_modules/@google/gemini-cli
    cp -r packages/core $out/share/gemini-cli/node_modules/@google/gemini-cli-core
    cp -r packages/a2a-server $out/share/gemini-cli/node_modules/@google/gemini-cli-a2a-server

    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-core/dist/docs/CONTRIBUTING.md

    ln -s $out/share/gemini-cli/node_modules/@google/gemini-cli/dist/index.js $out/bin/gemini
    chmod +x "$out/bin/gemini"

    # Clean up any remaining references to npmDeps in node_modules metadata
    find $out/share/gemini-cli/node_modules -name "package-lock.json" -delete
    find $out/share/gemini-cli/node_modules -name ".package-lock.json" -delete
    find $out/share/gemini-cli/node_modules -name "config.gypi" -delete

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "AI agent that brings the power of Gemini directly into your terminal";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    maintainers = with lib.maintainers; [
      brantes
      xiaoxiangmoe
      FlameFlag
      taranarmo
    ];
    platforms = lib.platforms.all;
    mainProgram = "gemini";
  };
})
