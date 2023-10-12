#!/usr/bin/env bash

set -o pipefail

# Kustomize Build Options
kustomize_flags=("--load-restrictor=LoadRestrictionsNone")
kustomize_config="kustomization.yaml"

# Kubeconform Options
kubeconform_flags=("-skip=Secret")
kubeconform_config=("-strict" "-ignore-missing-schemas" "-schema-location" "default" "-schema-location" "/tmp/flux-crd-schemas" "-verbose")

# Download Additional Schemas
echo "---=== Downloading Flux OpenAPI schemas ===---"
mkdir -p /tmp/flux-crd-schemas/master-standalone-strict
curl -sL https://github.com/fluxcd/flux2/releases/latest/download/crd-schemas.tar.gz | tar zxf - -C /tmp/flux-crd-schemas/master-standalone-strict

# Validate Files
echo "---=== Validating kustomize overlays ===---"
find . -type f -name $kustomize_config -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "=== Validating kustomization ${file/%$kustomize_config} ==="
    kustomize build "${file/%$kustomize_config}" "${kustomize_flags[@]}" | \
      kubeconform "${kubeconform_flags[@]}" "${kubeconform_config[@]}"
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
      exit 1
    fi
done