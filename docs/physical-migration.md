# Physical machine adoption

`bin/keystone-physical-migration` lets a Keystone user preserve a physical
machine as a VM before replacing that machine with Keystone OS. The first
adoption is the workstation's BitLocker-protected Windows NVMe, registered as
`ncrmro-desktop-windows` on Ocean.

The lifecycle is deliberately implemented in shell. Nix only installs the
tool, prepares Ocean's staging dataset, renders Git-tracked domain XML, and
defines enabled VMs. The script owns transfer state, proposal worktrees,
validation, pull requests, squash merges, and the exact-revision deployment.
Before it is installed on a host, agents can inspect the checked-in shell file
or run it reproducibly with `nix run .#keystone-physical-migration -- help`.

## Safety invariants

- BitLocker stays enabled. The moved disk is expected to request its recovery
  key because the virtual TPM and hardware identity have changed.
- The source is pinned by `/dev/disk/by-id`, serial, and exact byte count.
- The physical disk, verified staging file, final zvol, and post-copy ZFS
  snapshot are retained. This workflow contains no cleanup/delete command.
- The network copy goes directly from the physical block device to Ocean. It
  never needs workstation-sized scratch storage.
- Promotion requires `sudo` on Ocean. Ordinary SSH can write only the staging
  dataset.
- Only worktrees carrying this migration's private ownership marker are
  mutated. The primary checkout and unrelated worktrees are never touched.
- The Nix manifest cannot be enabled until its source and staging hashes match
  and a promoted snapshot is recorded.

## State and Git layout

Local operational state:

```text
~/.local/state/keystone/physical-migration/<vm>/migration.json
```

Ocean's independent on-disk ledger:

```text
/ocean/physical-migrations/<vm>/migration.json
```

Script-owned Git lifecycle:

```text
~/repos/<admin>/ks-config.worktrees/
├── feat/migrate-<vm>   # mutable proposal worktree
└── deploy/<vm>         # immutable deployment worktree at the squash commit
```

`manifest-sync` renders `hosts/ocean/vms/<vm>.nix` into every active,
migration-owned proposal worktree. Deployment worktrees are intentionally
immutable: `switch` compares the merged file byte-for-byte with a fresh render
before using it.

## Windows migration

Deploy this implementation to Ocean and the workstation first so the receiver
and packaged dependencies exist. Then, on the workstation:

```bash
keystone-physical-migration init
keystone-physical-migration source-ready \
  --confirm-clean-shutdown \
  --confirm-recovery-key
keystone-physical-migration preflight
keystone-physical-migration push
keystone-physical-migration logs
keystone-physical-migration verify-transfer
keystone-physical-migration promote
keystone-physical-migration promote --execute
```

`source-ready` does not read or store the recovery key. It records that
Windows was shut down normally and that the user can retrieve the key on the
other side. BitLocker protection is never changed.

The first `promote` is a non-mutating plan. The explicit `--execute` performs
the local Ocean file-to-zvol copy, verifies the full zvol, and snapshots it.

Boot the zvol transiently before enabling it in Git:

```bash
keystone-physical-migration validate
keystone-physical-migration console
```

Enter the BitLocker recovery key in the console. Do not suspend or disable
BitLocker. Once Windows is at the desktop:

```bash
keystone-physical-migration rdp
```

The RDP helper discovers the NAT address, opens an SSH tunnel through Ocean,
and starts FreeRDP without placing a password on the command line. Confirm the
successful session, shut Windows down normally, and seal validation:

```bash
keystone-physical-migration validate-complete
```

Finally:

```bash
keystone-physical-migration publish
keystone-physical-migration switch
```

`publish` flips `enable` only after validation, runs Nix checks, pushes the
proposal branch, waits for checks/review, and requests a squash merge.
`switch` requires the recorded squash commit to be the exact current
`origin/main`, creates the deployment worktree at that commit, switches Ocean,
and lets the Nix registry start the VM once.

The transitional workstation module does not write libvirt XML. It only keeps
the physical NVMe accessible by immutable serial during migration. Remove that
module in a follow-up commit after the Ocean deployment has been verified.
