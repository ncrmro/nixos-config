{...}: {
  # Create media user and group for NFS media sharing
  users.groups.media = {};
  users.users.media = {
    isSystemUser = true;
    group = "media";
  };
}
