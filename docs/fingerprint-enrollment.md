# Fingerprint enrollment (fprintd)

Add to your host config:
```nix
systemd.services.fprintd = {
  wantedBy = [ "multi-user.target" ];
  serviceConfig.Type = "simple";
};
services.fprintd.enable = true;
```

Then enroll:
```bash
fprintd-enroll
```