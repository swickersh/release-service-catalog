# rh-push-helm-chart-to-registry-redhat-io pipeline

Tekton pipeline to release **Helm OCI charts** to registry.redhat.io (same flow as
[`rh-push-to-registry-redhat-io`](../rh-push-to-registry-redhat-io/README.md) with these differences):

- After `apply-mapping`, runs [`validate-helm-chart-snapshot`](../../tasks/managed/validate-helm-chart-snapshot/README.md) to ensure each component is a Helm OCI artifact and that chart title/version match mapped repository names and tags.
- `verify-conforma`, `push-snapshot`, and `run-file-updates` consume the trusted artifact produced by that validation task.
- `create-pyxis-image` is invoked with `processHelmCharts: "true"` so Helm charts are recorded in Pyxis (the default `rh-push-to-registry-redhat-io` pipeline skips Helm for Pyxis).
- Does **not** run [`push-rpm-data-to-pyxis`](../../../tasks/managed/push-rpm-data-to-pyxis/README.md): that task pushes RPM manifest data derived from image SBOMs; Helm OCI charts are not part of that flow.

## Parameters

Same as [`rh-push-to-registry-redhat-io`](../rh-push-to-registry-redhat-io/README.md) (`release`, `snapshot`, `enterpriseContractPolicy`, `taskGitRevision`, etc.).

Use this pipeline from a ReleasePlanAdmission `pipelineRef` when releasing Helm charts built as OCI artifacts (not container images).

## Integration test

[`integration-tests/rh-push-helm-chart-to-registry-redhat-io/`](../../../integration-tests/rh-push-helm-chart-to-registry-redhat-io/) mirrors [`integration-tests/rh-push-to-registry-redhat-io/`](../../../integration-tests/rh-push-to-registry-redhat-io/) with a **Helm OCI** snapshot fixture (`rh-push-helm-e2e-fixture`); the container rh-push suite uses a **Dockerfile** image and `quay.io/redhat-pending` plus staging Pyxis. Typical setup: cluster **`stg-rh01`**, namespaces **`dev-release-team-tenant`** / **`managed-release-team-tenant`**, **`KUBECONFIG`** e.g. **`~/.kube/config-stg-rh01`**. After a **`--skip-cleanup`** run, clean up with [`integration-tests/utils/cleanup-resources.sh`](../../../integration-tests/utils/cleanup-resources.sh) and [`scripts/delete-branches.sh`](../../../scripts/delete-branches.sh).
