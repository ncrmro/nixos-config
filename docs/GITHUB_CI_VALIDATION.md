# GitHub CI NixOS Validation

This repository includes automated validation of NixOS configurations via GitHub Actions to ensure that all system configurations are valid and can be built successfully.

## Validation Workflow

The validation workflow (`.github/workflows/nixos-validation.yml`) runs automatically on:
- Pull requests to `master` or `main` branches
- Direct pushes to `master` or `main` branches
- Changes to specific paths:
  - `flake.nix` and `flake.lock`
  - `hosts/**` - All host configurations
  - `modules/**` - Custom modules
  - `home-manager/**` - Home Manager configurations
  - The workflow file itself

## Validation Jobs

### 1. Flake Validation (`validate-flake`)
- **Purpose**: Validates the flake structure and dependencies
- **Commands**:
  - `nix flake check --show-trace` - Comprehensive flake validation
  - `nix flake metadata` - Verify flake metadata and inputs

### 2. Code Formatting (`format-check`) 
- **Purpose**: Ensures consistent code formatting using alejandra
- **Commands**:
  - `nix fmt -- --check .` - Check if all Nix files are properly formatted

### 3. System Configuration Builds (`build-systems`)
- **Purpose**: Validates that all NixOS system configurations can build successfully
- **Strategy**: Matrix build testing multiple systems in parallel
- **Systems Tested**:
  - `test-vm` - Test virtual machine configuration
  - `mox` - Desktop/workstation configuration  
  - `maia` - Home server configuration
  - `mercury` - Infrastructure server
  - `ocean` - Storage server
  - `devbox` - Development environment
  - `testbox` - Test environment
- **Build Target**: `nixosConfigurations.<system>.config.system.build.toplevel`
- **Timeout**: 90 minutes per system
- **Performance**: Limited to 2 concurrent jobs to manage resource usage

### 4. Home Manager Builds (`build-home-manager`)
- **Purpose**: Validates Home Manager user configurations
- **Configurations Tested**:
  - `ncrmro@mox` - User configuration for mox host
- **Build Target**: `homeConfigurations.<config>.activationPackage`
- **Timeout**: 60 minutes

## Performance Optimizations

### Disk Space Management
The workflow includes automatic cleanup to maximize available disk space:
- Removes unnecessary system packages (.NET, Android SDK, GHC, CodeQL)
- Prunes Docker images
- Monitors disk usage with `df -h`

### Caching Strategy
- Uses official NixOS binary cache (`cache.nixos.org`)
- Includes community cache (`nix-community.cachix.org`) for faster builds
- Leverages GitHub Actions cache for Nix store

### Resource Limits
- Limited to 2 concurrent Nix jobs (`--max-jobs 2`) to prevent memory exhaustion
- Extended timeouts for complex system builds
- Parallel matrix builds for faster overall validation

## Failure Handling

### Build Failures
- Each job includes error handling with detailed output
- Uses `--show-trace` for comprehensive error diagnostics
- Individual system failures don't block other systems (`fail-fast: false`)

### Debugging Failed Builds
When a build fails:
1. Check the GitHub Actions logs for the specific error
2. Look for `--show-trace` output showing the build failure point
3. Reproduce locally using:
   ```bash
   nix build .#nixosConfigurations.<system>.config.system.build.toplevel --show-trace
   ```

## Local Testing

Before submitting pull requests, test locally:

```bash
# Validate flake
nix flake check --show-trace

# Check formatting
nix fmt -- --check .

# Build specific system
nix build .#nixosConfigurations.test-vm.config.system.build.toplevel

# Build Home Manager config
nix build .#homeConfigurations."ncrmro@mox".activationPackage
```

## Integration with Development Workflow

### Pre-commit Hooks
The repository includes pre-commit hooks for formatting:
```bash
./bin/setup-precommit
```

### Manual Validation
Use the existing check script:
```bash
./bin/check
```

## Adding New Systems

When adding new NixOS configurations:
1. Add the new system to `flake.nix` under `nixosConfigurations`
2. Update the validation workflow matrix in `.github/workflows/nixos-validation.yml`
3. Ensure the new system can build successfully locally before committing

## Workflow Triggers

The workflow is optimized to run only when relevant files change:
- Configuration files (`flake.nix`, `flake.lock`)
- Host definitions (`hosts/**`)
- Custom modules (`modules/**`)
- Home Manager configurations (`home-manager/**`)
- The workflow itself

This selective triggering reduces unnecessary CI runs and conserves GitHub Actions minutes.