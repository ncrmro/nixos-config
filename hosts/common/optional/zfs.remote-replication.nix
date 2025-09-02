{
  pkgs,
  config,
  lib,
  ...
}: {
  # Base configuration for ZFS remote replication
  # This module provides common settings for sanoid/syncoid-based ZFS replication
  # Each host should extend this with their specific dataset configurations

  # Install necessary packages
  environment.systemPackages = with pkgs; [
    sanoid # For ZFS snapshot management and replication
  ];

  # Enable basic ZFS maintenance services
  services.zfs.trim.enable = lib.mkDefault true;
  services.zfs.autoScrub.enable = lib.mkDefault true;
  services.zfs.autoSnapshot.enable = lib.mkDefault true;
  
  # Each host should configure their own sanoid and syncoid services
  # by importing this module and adding their own configuration
}