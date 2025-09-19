{...}: {
  # Create media user and group for NFS media sharing
  users.groups.media = {
    gid = 9999;
  };
  users.users.media = {
    isSystemUser = true;
    group = "media";
  };
}
