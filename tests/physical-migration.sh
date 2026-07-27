#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
script="$repo_root/bin/keystone-physical-migration"
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

origin="$test_root/origin.git"
primary="$test_root/repos/testadmin/ks-config"
worktrees="$test_root/repos/testadmin/ks-config.worktrees"
state="$test_root/state"
fake_bin="$test_root/bin"

mkdir -p "$fake_bin"
printf '#!/usr/bin/env bash\nexit 0\n' >"$fake_bin/nix"
chmod +x "$fake_bin/nix"

git init --bare "$origin" >/dev/null
git clone "$origin" "$primary" >/dev/null 2>&1
git -C "$primary" config user.name "Physical Migration Test"
git -C "$primary" config user.email "physical-migration@example.invalid"
mkdir -p "$primary/hosts/ocean/vms"
printf '{ description = "fixture"; }\n' >"$primary/flake.nix"
printf 'seed\n' >"$primary/README.md"
git -C "$primary" add .
git -C "$primary" commit -m "test: seed" >/dev/null
git -C "$primary" branch -M main
git -C "$primary" push -u origin main >/dev/null
git --git-dir="$origin" symbolic-ref HEAD refs/heads/main

export PATH="$fake_bin:$PATH"
export USER=testadmin
export KEYSTONE_MIGRATION_STATE_ROOT="$state"

"$script" --repo "$primary" --worktrees-root "$worktrees" init \
  --source /dev/disk/by-id/test-windows \
  --serial TESTSERIAL \
  --bytes 4096 \
  --host ocean \
  --dataset ocean/physical-migrations \
  --mountpoint /ocean/physical-migrations \
  --zvol ocean/vms/ncrmro-desktop-windows \
  >/dev/null

"$script" --repo "$primary" --worktrees-root "$worktrees" source-ready \
  --confirm-clean-shutdown \
  --confirm-recovery-key \
  >/dev/null
"$script" --repo "$primary" --worktrees-root "$worktrees" init \
  --source /dev/disk/by-id/test-windows \
  --serial TESTSERIAL \
  --bytes 4096 \
  >/dev/null
jq -e '
  .sourceReadiness.cleanWindowsShutdown and
  .sourceReadiness.recoveryKeyAvailable
' "$state/ncrmro-desktop-windows/migration.json" >/dev/null

"$script" --repo "$primary" --worktrees-root "$worktrees" manifest-sync >/dev/null

proposal="$worktrees/feat/migrate-ncrmro-desktop-windows"
manifest="$proposal/hosts/ocean/vms/ncrmro-desktop-windows.nix"
secondary="$worktrees/feat/migrate-ncrmro-desktop-windows-recovery"
git -C "$primary" worktree add \
  -b feat/migrate-ncrmro-desktop-windows-recovery \
  "$secondary" origin/main \
  >/dev/null
secondary_git_dir=$(git -C "$secondary" rev-parse --path-format=absolute --git-dir)
jq -n \
  --arg vm ncrmro-desktop-windows \
  '{vm:$vm, role:"proposal"}' \
  >"$secondary_git_dir/keystone-physical-migration-owner.json"

"$script" --repo "$primary" --worktrees-root "$worktrees" manifest-sync >/dev/null
secondary_manifest="$secondary/hosts/ocean/vms/ncrmro-desktop-windows.nix"
[[ -f $manifest ]]
cmp "$manifest" "$secondary_manifest"
grep -q 'enable = false;' "$manifest"
grep -q 'sourceSerial = "TESTSERIAL";' "$manifest"
grep -q 'sourceBytes = 4096;' "$manifest"
[[ ! -e "$primary/hosts/ocean/vms/ncrmro-desktop-windows.nix" ]]

first_hash=$(sha256sum "$manifest")
"$script" --repo "$primary" --worktrees-root "$worktrees" manifest-sync >/dev/null
second_hash=$(sha256sum "$manifest")
[[ $first_hash == "$second_hash" ]]

state_file="$state/ncrmro-desktop-windows/migration.json"
state_tmp=$(mktemp)
jq '
  .git.enabled = true |
  .source.sha256 = ("a" * 64) |
  .transfer.stagedSha256 = ("a" * 64) |
  .promotion.snapshot = "ocean/vms/ncrmro-desktop-windows@test"
' "$state_file" >"$state_tmp"
mv "$state_tmp" "$state_file"
"$script" --repo "$primary" --worktrees-root "$worktrees" manifest-sync >/dev/null
grep -q 'enable = true;' "$manifest"
grep -q 'sourceSha256 = "aaaaaaaa' "$manifest"
cmp "$manifest" "$secondary_manifest"

marker=$(git -C "$proposal" rev-parse --path-format=absolute --git-dir)
jq -e '
  .vm == "ncrmro-desktop-windows" and .role == "proposal"
' "$marker/keystone-physical-migration-owner.json" >/dev/null

printf 'physical migration manifest worktree test: PASS\n'
