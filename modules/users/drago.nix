{ config, pkgs, ... }:
{
  users.users.drago = {
    isNormalUser = true;
    description = "Autonomous Agent";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    initialPassword = "password"; # For testing, change later
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEE6cFSyJoiaURB7+961zETflBNPJUZszH9xyowzbpNu ncrmro@ocean"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 ncrmro@ncrmro-laptop-fw7k"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAGBpgX+4rqqVdHNnLWFXPOyVMf3Cp00VbUCLyR6tP15qHWTO9OKyjRbHIxmwFfw2hkfzCKD9MtN8vheH2NWWzg= ncrmro@iphone-14-pro"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCUAyM7/owpfpJPuzQMmkmnlAcqB91QIfVsj1TueIU3hUtoHGR6FcKfFgJA5gkhww10A91M6iPSHD2kd/BNBGD4= ncrmro@ncrmro-laptop"
    ];
  };
}
