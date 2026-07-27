# Link Operator

This directory installs the release-grade Link Operator on Ocean. It is shared
cluster infrastructure and contains no agent profile, `Organization`, `Agent`,
channel credentials, Pi state, or application-specific deployment logic.

## Install

After Link's release workflow publishes the public images, resolve their GHCR
digests and export them:

```bash
export LINK_OPERATOR_IMAGE=ghcr.io/ai-outfitter/link-operator@sha256:…
export LINK_AGENT_IMAGE=ghcr.io/ai-outfitter/link-agent@sha256:…
```

```bash
devenv shell -- k8s-apply-link --dry-run
devenv shell -- k8s-apply-link
```

Verify:

```bash
kubectl -n link-operator-system \
  rollout status deployment/link-operator-controller-manager
```

Private agent repositories own their resources and may overlay this
installation or install matching local Link manifests for development.
