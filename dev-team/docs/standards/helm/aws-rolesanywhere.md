# AWS IAM Roles Anywhere Sidecar (Lerian)

How Lerian workloads get **temporary AWS credentials without static keys or IRSA**:
an `aws-signing-helper` (credential-helper) **sidecar** exchanges an X.509 client
cert for AWS creds and serves them on a local metadata endpoint the app reads.

Used today by `fetcher`, `matcher`, `plugin-fees`, `reporter` (manager **and**
worker, incl. the KEDA ScaledJob). Gated everywhere on
`.Values.aws.rolesAnywhere.enabled` (default `false`) — zero cost when off.

This pattern has **two halves**: the chart ships the sidecar; the GitOps deploy
provisions the client cert. Both must be present or the app can't get AWS creds.

## Chart side (ring:helm)

`values.yaml` — `aws.rolesAnywhere` block (from reporter):

```yaml
aws:
  rolesAnywhere:
    enabled: false
    trustAnchorArn: ""
    profileArn: ""
    roleArn: ""
    region: "us-east-2"          # RolesAnywhere trust anchor region
    sessionDuration: 3600
    certificateSecretName: "{svc}-iam-tls"   # cert-manager Secret the sidecar mounts
    sidecar:
      image:
        repository: public.ecr.aws/rolesanywhere/credential-helper
        tag: "latest-amd64"
        pullPolicy: IfNotPresent
      port: 9911
      resources: { ... }
```

Deployment template — everything gated on `and .Values.aws .Values.aws.rolesAnywhere .Values.aws.rolesAnywhere.enabled`:

- **Pod** `securityContext.fsGroup: 65532` (so the sidecar can read the mounted cert).
- **App container env**:
  ```yaml
  - name: AWS_EC2_METADATA_SERVICE_ENDPOINT
    value: "http://127.0.0.1:{{ .Values.aws.rolesAnywhere.sidecar.port | default 9911 }}"
  - name: AWS_EC2_METADATA_SERVICE_ENDPOINT_MODE
    value: "IPv4"
  ```
  (the AWS SDK reads creds from this fake IMDS endpoint served by the sidecar).
- **Sidecar container** `aws-signing-helper`:
  ```yaml
  - name: aws-signing-helper
    image: "{{ .repository }}:{{ .tag }}"
    args: [ serve, --certificate, <mounted cert>, --private-key, <mounted key>,
            --trust-anchor-arn, ..., --profile-arn, ..., --role-arn, ..., --port, 9911 ]
    # mounts the cert-manager Secret certificateSecretName
  ```
- MUST be applied to **every** component that needs AWS (manager + worker + ScaledJob),
  not just the API.

## GitOps side (ring:helm-deploy)

The client cert is a **cert-manager `Certificate`** created as an extra release
(`iam-cert`, via `incubator/raw`) that the app release `needs:`. From fetcher:

```yaml
releases:
  - name: iam-cert
    namespace: {ns}
    chart: incubator/raw
    values:
      - resources:
          - apiVersion: cert-manager.io/v1
            kind: Certificate
            metadata: { name: {svc}-iam-cert, namespace: {ns} }
            spec:
              secretName: {svc}-iam-tls          # == values.aws.rolesAnywhere.certificateSecretName
              duration: 2160h                     # 90 days
              renewBefore: 720h                   # 30 days
              commonName: "{svc}"
              issuerRef:
                name: {env}-iam-roles-anywhere-issuer   # ClusterIssuer whose CA is the AWS Trust Anchor
                kind: ClusterIssuer
                group: cert-manager.io
  - name: {svc}
    chart: oci://ghcr.io/lerianstudio/{svc}-helm
    needs: [ {ns}/ghcr-credential, {ns}/iam-cert ]   # cert must exist before the pod
    values: [ values.yaml ]
```

- The `ClusterIssuer` `{env}-iam-roles-anywhere-issuer` and the AWS **Trust Anchor**
  (`arn:aws:rolesanywhere:...:trust-anchor/...`) are provisioned by
  **lerian-infrastructure** (per-env trust-anchor module) — NOT by this chart/deploy.
  Reference the issuer; do not create the trust anchor here.
- `values.yaml` must set `aws.rolesAnywhere.enabled: true` + the ARNs +
  `certificateSecretName` matching the Certificate `secretName`.
- Requires **cert-manager** installed in the cluster (it is, as an addon).

## Checklist
- [ ] Sidecar gated on `aws.rolesAnywhere.enabled`; off by default.
- [ ] Applied to ALL AWS-needing components (manager + worker + ScaledJob).
- [ ] Pod `fsGroup: 65532`; app env points to `127.0.0.1:<port>`.
- [ ] Deploy: `iam-cert` Certificate release; app `needs:` it; `secretName` ==
      `certificateSecretName`.
- [ ] `issuerRef` → `{env}-iam-roles-anywhere-issuer` (exists via lerian-infrastructure).

## Anti-patterns
- Static AWS keys / IRSA when the service standard is RolesAnywhere.
- Sidecar on the API but not the worker (worker then can't reach AWS).
- Creating the Trust Anchor in the chart/deploy (it's infra-owned).
- `certificateSecretName` ≠ Certificate `secretName` (sidecar mounts nothing).
