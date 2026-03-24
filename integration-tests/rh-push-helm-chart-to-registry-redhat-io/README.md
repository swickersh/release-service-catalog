# rh-push-helm-chart-to-registry-redhat-io test

End-to-end test for [`pipelines/managed/rh-push-helm-chart-to-registry-redhat-io`](../../pipelines/managed/rh-push-helm-chart-to-registry-redhat-io/README.md), mirroring [rh-push-to-registry-redhat-io](../rh-push-to-registry-redhat-io/README.md) with these differences:

- **Release pipeline:** `rh-push-helm-chart-to-registry-redhat-io` (includes `validate-helm-chart-snapshot`, `processHelmCharts` for Pyxis; no `push-rpm-data-to-pyxis`).
- **RPA mapping:** Delivery repo basename `rh-push-helm-e2e-fixture` and tag `0.1.0_e2e001` so they match Helm OCI annotations after `apply-mapping` (see `validate-helm-chart-snapshot`).
- **`pushSourceContainer: false`** in mapping defaults (Helm charts do not publish `.src` images like container builds).

## Prerequisite: e2e-base branch

The test clones a source **`e2e-base`** repo (see `component_base_repo_name` in [`test.env`](test.env); default **`swickersh/e2e-base`**, upstream **`hacbs-release-tests/e2e-base`**) branch **`rh-push-helm-chart-to-registry-redhat-io-base`** into a per-run repo under **`hacbs-release-tests`**. That branch **must exist** on the source remote and must:

1. Build and push a **Helm OCI** artifact to the tenant Quay repo Konflux uses for the component.
2. Produce chart annotations compatible with the RPA mapping (`org.opencontainers.image.title` = `rh-push-helm-e2e-fixture`, `version` = `0.1.0+e2e001`, tags aligned with `0.1.0_e2e001`).
3. Define **Konflux build** pipelines (e.g. under `.tekton/`) appropriate for Helm OCI.

Until that branch exists, the suite will fail at build or release validation. The container-only **`rh-push-to-registry-redhat-io-base`** branch is **not** sufficient.

## Component pipeline annotation

[`resources/tenant/component.yaml`](resources/tenant/component.yaml) sets `build.appstudio.openshift.io/pipeline` to a **Helm OCI** pipeline name (`helm-chart-oci-ta` if available on the cluster). Adjust to match your Konflux `build-pipeline-config` and the `rh-push-helm-chart-to-registry-redhat-io-base` branch (often driven by `.tekton/` in the cloned repo).

## Setup

Same as [rh-push-to-registry-redhat-io](../rh-push-to-registry-redhat-io/README.md): `GITHUB_TOKEN`, `VAULT_PASSWORD_FILE`, `RELEASE_CATALOG_GIT_*`, cluster access (`stg-rh01`, `dev-release-team-tenant` / `managed-release-team-tenant`), optional `KUBECONFIG` (e.g. `~/.kube/config-stg-rh01`).

### Running

```bash
cd integration-tests
./run-test.sh rh-push-helm-chart-to-registry-redhat-io
```

Use `./run-test.sh rh-push-helm-chart-to-registry-redhat-io --skip-cleanup` to keep resources for debugging; then [`utils/cleanup-resources.sh`](../utils/cleanup-resources.sh) and [`../scripts/delete-branches.sh`](../scripts/delete-branches.sh).

## Reference run (rh-push-to-registry-redhat-io, for parity)

A successful **container** rh-push e2e (`b2d27993` suffix) illustrated the same harness steps: per-run repo `hacbs-release-tests/rh-push-to-registry-redhat-io-b2d27993`, Application `rh-redhat-app-b2d27993`, tenant build PLR `…-on-push-g4zxg`, managed release PLR `managed-bkxpb`, Release `rh-redhat-app-b2d27993-20260324-151108-000-8e6e191-lxbxx`, verification against `quay.io/redhat-pending/rhtap----rh-advisories-component` and staging catalog. The Helm suite will follow the same shape with Helm-specific snapshot content and verification (`test.sh` uses `skopeo inspect --raw` for Helm).
