# validate-helm-chart-snapshot task

Tekton task that validates a mapped snapshot for Helm OCI chart releases.

For each component it:

1. Confirms the artifact is a Helm chart (`config.mediaType` is `application/vnd.cncf.helm.config.v1+json`) via `skopeo inspect --raw`.
2. Requires `org.opencontainers.image.title` and `org.opencontainers.image.version` on the manifest.
3. Compares the chart title to the basename of each `repositories[].url` (path after the registry host, with `----` replaced by `/`, then the last path segment).
4. Compares each release tag in `repositories[].tags` to the chart version. OCI tags use `_` where SemVer uses `+` for build metadata; the task maps the first `_` in a tag to `+` before comparison.

Intended for use in the `rh-push-helm-chart-to-registry-redhat-io` pipeline after `apply-mapping`.
