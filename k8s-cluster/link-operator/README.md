# Vega resident agent

This directory installs Link Operator and declares Vega as a standalone
Outfitter agent on Ocean. Vega has no HTTP service or ingress. Channels keeps a
resident Pi session connected to Stalwart JMAP and Slack Socket Mode; Slack
wakes only on `app_mention`.

## Credentials

Store these two encrypted Kubernetes Secret manifests in the private
`agenix-secrets` checkout under `secrets/k8s/ocean/`:

- `vega-email.yaml.age`: Secret `agent-vega/vega-email` with
  `XIN_BASE_URL=https://mail.ncrmro.com`, `XIN_BASIC_USER=vega@ncrmro.com`, and
  `XIN_BASIC_PASS`.
- `vega-slack.yaml.age`: Secret `agent-vega/vega-slack` with
  `SLACK_APP_TOKEN` (`xapp-…`, `connections:write`) and `SLACK_BOT_TOKEN`
  (`xoxb-…`).

The Slack bot needs Socket Mode, the `app_mention` bot event, and bot scopes
`app_mentions:read`, `channels:history`, `chat:write`, and `reactions:write`.
Add `groups:history` only if Vega joins private channels. Invite Vega only to
the channels it should watch.

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
devenv shell -- k8s-apply-secrets
devenv shell -- vega-pi-sync
devenv shell -- k8s-apply-link
```

The final run should converge `Agent/vega` after both encrypted channel Secrets
and the PVC-backed Pi auth readiness ConfigMap exist.

Verify:

```bash
kubectl --kubeconfig ~/.kube/config.ocean.yml get agent vega
kubectl --kubeconfig ~/.kube/config.ocean.yml -n agent-vega \
  rollout status deployment/agent-runtime
kubectl --kubeconfig ~/.kube/config.ocean.yml -n agent-vega \
  logs deployment/agent-runtime -c agent
```
