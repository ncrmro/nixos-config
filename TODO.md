# TODO: Fix Keystone Submodule Migration

## Status
✅ **RESOLVED**: Option A implemented on 2025-12-18. Flake input updated to `git+file:./.submodules/keystone?submodules=1`.

## Problem Summary

We migrated local `modules/keystone/` content to the `.submodules/keystone` repository. The migration itself succeeded:

1. ✅ Copied all files to keystone repo
2. ✅ Committed and pushed to github.com/ncrmro/keystone
3. ✅ Removed local `modules/keystone/` directory
4. ✅ Updated references from `outputs.nixosModules.keystone-desktop` to `inputs.keystone.nixosModules.keystoneDesktop`
5. ✅ Updated references from `outputs.homeManagerModules.keystone-*` to `inputs.keystone.homeModules.keystone*`

## Current Issue

The flake input uses `path:./.submodules/keystone` which doesn't work because:

- Nix's `path:` fetcher copies the git tree to the store
- Git submodules appear as empty directories in the store (submodule content is not included)
- Result: `error: path '.../source/.submodules/keystone/flake.nix' does not exist`

This happens even with a clean git tree (all changes committed).

## Files Modified (Uncommitted)

- `flake.nix` - keystone input (currently `path:`, need to fix)
- `flake.lock` - needs update after keystone input is fixed
- `hosts/mox/default.nix` - fixed user path, commented missing modules
- `hosts/test-vm/default.nix` - updated to use `inputs.keystone.nixosModules.keystoneDesktop`
- `hosts/workstation/default.nix` - updated to use `inputs.keystone.nixosModules.keystoneDesktop`
- `hosts/build-vm-desktop/default.nix` - updated to use `inputs.keystone.nixosModules.keystoneDesktop`
- `modules/nixos/default.nix` - removed keystone-desktop reference
- `modules/home-manager/default.nix` - removed keystone module references
- `home-manager/ncrmro/base.nix` - updated to use `inputs.keystone.homeModules.keystoneDesktop`
- `home-manager/ncrmro/test-vm.nix` - updated to use `inputs.keystone.homeModules.keystoneDesktop`
- `home-manager/ncrmro/build-vm-desktop.nix` - updated to use `inputs.keystone.homeModules.keystoneDesktop`
- `home-manager/ncrmro/ocean.nix` - updated to use `inputs.keystone.homeModules.keystoneTerminal`
- `home-manager/common/features/macos-dev.nix` - updated to use `inputs.keystone.homeModules.keystoneTerminal`

## Next Steps

Try alternative approaches to make `path:` work with submodules:

1. ✅ **Option A**: Use `git+file:` URL format which may support submodules
   ```nix
   keystone.url = "git+file:./.submodules/keystone?submodules=1";
   ```

2. **Option B**: Keep submodule for development but use GitHub URL in flake
   ```nix
   keystone.url = "github:ncrmro/keystone";
   ```
   - Use `--override-input keystone path:./.submodules/keystone` for local testing

3. **Option C**: Don't use submodule, directly include keystone as a path
   - Remove submodule, copy keystone content directly
   - Less clean but avoids submodule complexity

## Keystone Repo State

Commits pushed to github.com/ncrmro/keystone:
- `c9b5633` - feat(flake): export keystoneTerminal and keystoneDesktop homeModules
- `fd8a8d7` - feat(flake): export keystoneDesktop module
- `e50d231` - chore: remove orphaned submodule reference
- `ff2f8a7` - feat(desktop): migrate modules from nixos-config
