# Vega resident agent

This directory installs Link Operator and declares Vega as a standalone
Outfitter agent on Ocean. Vega has no HTTP service or ingress. Channels keeps a
resident Pi session connected to Stalwart JMAP.

## Credentials

Create the live Kubernetes Secret directly on Ocean from a protected temporary
environment file. Do not commit its manifest or values; this deployment does
not require SOPS or agenix for the channel credential. Follow the direct
Kubernetes handoff in the platform skill's
`references/stalwart-accounts.md`:

- Secret `agent-vega/vega-email` with
  `XIN_BASE_URL=https://mail.ncrmro.com`, `XIN_BASIC_USER=vega`, and
  `XIN_BASIC_PASS`.

Provision the Stalwart individual principal `vega` with email
`vega@ncrmro.com`, its generated password, and role `user`. The account API and
role requirement are documented in `docs/stalwart.md`. Do not place the
password in ks-config.

## Deployment

After Link's release workflow publishes the public images, resolve their GHCR
digests and export them:

```bash
export LINK_OPERATOR_IMAGE=ghcr.io/ai-outfitter/link-operator@sha256:…
export LINK_AGENT_IMAGE=ghcr.io/ai-outfitter/link-agent@sha256:…
```

Commit and push the Vega catalog before applying it; the deployment script
refuses a dirty or unpublished ks-config revision.

```bash
devenv shell -- k8s-apply-link --dry-run
devenv shell -- k8s-apply-link
# Create vega-email directly with the Ocean kubeconfig.
devenv shell -- vega-pi-sync
devenv shell -- k8s-apply-link
```

The final run should converge `Agent/vega` after the email Secret and the
PVC-backed Pi auth readiness ConfigMap exist.

Verify:

```bash
kubectl --kubeconfig ~/.kube/config.ocean.yml get agent vega
kubectl --kubeconfig ~/.kube/config.ocean.yml -n agent-vega \
  rollout status deployment/agent-runtime
kubectl --kubeconfig ~/.kube/config.ocean.yml -n agent-vega \
  logs deployment/agent-runtime -c agent
```
