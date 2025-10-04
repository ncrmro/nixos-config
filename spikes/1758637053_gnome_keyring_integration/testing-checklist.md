# GNOME Keyring Integration Testing Checklist

This checklist ensures all integrations are working correctly after setup.

## Pre-Testing Setup

- [ ] System has been rebuilt with new configuration
- [ ] User has logged out and back in to initialize PAM integration
- [ ] GNOME Keyring daemon is running: `ps aux | grep gnome-keyring`

## SSH Integration Testing

### Basic SSH Agent Functionality
- [ ] SSH_AUTH_SOCK environment variable is set: `echo $SSH_AUTH_SOCK`
- [ ] SSH agent is running: `ssh-add -l` (should not error)
- [ ] Can add SSH keys: `ssh-add ~/.ssh/id_ed25519`
- [ ] Keys persist after adding: `ssh-add -l` shows loaded keys
- [ ] Keys automatically load on login (if configured)

### SSH Authentication Testing
- [ ] Can authenticate to GitHub: `ssh -T git@github.com`
- [ ] Can authenticate to other SSH services
- [ ] Git operations work with SSH: `git clone git@github.com:user/repo.git`
- [ ] SSH key passphrase is requested only once per session

### SSH Agent Persistence
- [ ] Keys remain loaded after terminal restart
- [ ] Keys are cleared on logout/reboot (security)
- [ ] Keyring unlocks automatically with login

## Docker Credential Helper Testing

### Configuration Verification
- [ ] Docker config file exists: `cat ~/.docker/config.json`
- [ ] Secretservice is configured as credential store
- [ ] docker-credential-secretservice is installed and accessible

### Credential Storage Testing
- [ ] Can login to Docker Hub: `docker login`
- [ ] Credentials are stored in keyring: `secret-tool search --all | grep docker`
- [ ] Can pull images without re-authentication: `docker pull hello-world`
- [ ] Can login to additional registries (e.g., `docker login gcr.io`)

### Credential Retrieval Testing
- [ ] Credentials auto-populate on subsequent logins
- [ ] Can logout and login again without issues: `docker logout && docker login`
- [ ] Multiple registry credentials work simultaneously

## 1Password Integration Testing

### Installation and Setup
- [ ] 1Password CLI is installed: `op --version`
- [ ] Can configure account: `op account add --address my.1password.com --email user@example.com`
- [ ] Can signin manually: `op signin`

### Keyring Integration Testing
- [ ] Can store session in keyring: `op-keyring-login`
- [ ] Session is retrieved from keyring: `secret-tool lookup service "1password" account "default"`
- [ ] Session restoration service is active: `systemctl --user status onepassword-session-restore`
- [ ] Environment variable is set: `echo $OP_SESSION_default`

### Session Persistence Testing
- [ ] Session survives terminal restart
- [ ] Can access 1Password items: `op item list`
- [ ] Session expires and is cleaned up appropriately
- [ ] New sessions overwrite old ones

## Bitwarden Integration Testing

### Installation and Setup
- [ ] Bitwarden CLI is installed: `bw --version`
- [ ] Can login manually: `bw login`
- [ ] Can unlock vault: `bw unlock`

### Keyring Integration Testing
- [ ] Can store session in keyring: `bw-keyring-login`
- [ ] Session is retrieved from keyring: `secret-tool lookup service "bitwarden" session "main"`
- [ ] Session restoration service is active: `systemctl --user status bitwarden-session-restore`
- [ ] Environment variable is set: `echo $BW_SESSION`

### Session Persistence Testing
- [ ] Session survives terminal restart
- [ ] Can access Bitwarden items: `bw list items`
- [ ] Session expires and is cleaned up appropriately
- [ ] Can sync vault: `bw sync`

## Keyring Management Testing

### Basic Keyring Operations
- [ ] Can view keyring status: `keyring-status`
- [ ] Can search stored secrets: `secret-tool search --all`
- [ ] Can manually store secrets: `secret-tool store --label="Test" service "test" key "value"`
- [ ] Can retrieve stored secrets: `secret-tool lookup service "test" key "value"`
- [ ] Can delete secrets: `secret-tool clear service "test" key "value"`

### GUI Management (if installed)
- [ ] Seahorse opens and shows keyring: `seahorse`
- [ ] Can view stored passwords and keys
- [ ] Can manage keyring settings
- [ ] Can lock/unlock keyring manually

### Security Testing
- [ ] Keyring locks when expected (logout, timeout)
- [ ] Keyring unlocks with correct password
- [ ] Wrong password is rejected
- [ ] Keyring integrates with system authentication

## Integration Testing

### Cross-Tool Testing
- [ ] SSH keys work for Git operations with 1Password/Bitwarden vault access
- [ ] Docker registry auth works while using password managers
- [ ] Multiple authentication flows work simultaneously
- [ ] No conflicts between different credential sources

### Performance Testing
- [ ] Keyring operations are reasonably fast (< 1 second)
- [ ] No noticeable delay in SSH authentication
- [ ] Docker operations don't hang on credential retrieval
- [ ] System startup time not significantly impacted

## Troubleshooting

### Common Issues to Check
- [ ] SELinux/AppArmor not blocking keyring access
- [ ] D-Bus session is properly configured
- [ ] Environment variables are properly set in all shell contexts
- [ ] Services start correctly: `systemctl --user list-units | grep keyring`

### Logging and Debugging
- [ ] Check systemd user service logs: `journalctl --user -u gnome-keyring-*`
- [ ] Check session logs for errors
- [ ] Verify PAM configuration is correct
- [ ] Test in clean environment (new user account)

## Security Validation

### Access Control
- [ ] Only user can access their keyring
- [ ] Keyring is encrypted at rest
- [ ] Memory is properly cleared on logout
- [ ] No credentials stored in plaintext

### Audit Trail
- [ ] Can identify what has access to keyring
- [ ] Failed authentication attempts are logged
- [ ] Unusual access patterns can be detected

## Documentation and Maintenance

- [ ] Document any configuration changes made
- [ ] Note any specific setup requirements for the environment
- [ ] Plan for regular credential rotation
- [ ] Verify backup/recovery procedures

## Cleanup Testing

### Removal Testing (Optional)
- [ ] Can cleanly disable keyring integration
- [ ] Old credentials are properly removed
- [ ] No residual configuration remains
- [ ] System reverts to previous authentication methods

---

## Test Results

Date: ___________
Tester: ___________
System: ___________

### Summary
- [ ] All SSH integration tests passed
- [ ] All Docker integration tests passed  
- [ ] All 1Password integration tests passed
- [ ] All Bitwarden integration tests passed
- [ ] All security tests passed
- [ ] System is ready for production use

### Notes
```
[Space for additional notes and observations]
```