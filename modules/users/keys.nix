# SSH public keys for authorized_keys across all hosts.
# Single source of truth — import this file wherever keys are needed.
{
  # ncrmro's personal device keys (used for ncrmro user, agent users, zfs-sync)
  ncrmro = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 ncrmro@ncrmro-laptop-fw7k"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiFUbcDdzBGNgo7GdRvuRvZ9Yf195pIm2jbiM0uJwW0 ncrmro@ncrmro-workstation"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEE6cFSyJoiaURB7+961zETflBNPJUZszH9xyowzbpNu ncrmro@ocean"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAGBpgX+4rqqVdHNnLWFXPOyVMf3Cp00VbUCLyR6tP15qHWTO9OKyjRbHIxmwFfw2hkfzCKD9MtN8vheH2NWWzg= ncrmro@iphone-14-pro"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCUAyM7/owpfpJPuzQMmkmnlAcqB91QIfVsj1TueIU3hUtoHGR6FcKfFgJA5gkhww10A91M6iPSHD2kd/BNBGD4= ncrmro@ncrmro-laptop"
  ];

  # Root access keys (ed25519 keys only for admin access)
  root = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 ncrmro@ncrmro-laptop-fw7k"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiFUbcDdzBGNgo7GdRvuRvZ9Yf195pIm2jbiM0uJwW0 ncrmro@ncrmro-workstation"
  ];
}
