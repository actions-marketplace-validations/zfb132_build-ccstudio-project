#!/usr/bin/env bash
set -euo pipefail

# Inputs
UBUNTU="${1:-}"
CCS_VER="${2:-}"
CCS_COMP="${3:-}"
MMW_VER="${4:-}"
MMW_COMP="${5:-}"
BIOS_VER="${6:-}"

# Base image names
IMAGE_BASE_GHCR="ghcr.io/zfb132/ccstudio"
IMAGE_BASE_DOCKERHUB="docker.io/whuzfb/ccstudio"
DOCKERFILE_REPO="https://github.com/zfb132/ccstudio.git"

# Allowed versions for pulling
declare -a ALLOWED_UBUNTU_VERSION=("20.04" "22.04" "24.04")
declare -a ALLOWED_CCS_VERSION=("10.4.0.00006" "11.2.0.00007" "12.8.1.00005" "20.2.0.00012")
declare -a ALLOWED_CCS_COMPONENTS=("PF_ALL")
declare -a ALLOWED_MMWSDK_VERSION=("03.06.02.00-LTS" "")
declare -a ALLOWED_MMWSDK_COMPONENTS=("ALL" "")
declare -a ALLOWED_BIOS_VERSION=("")
declare -a ALLOWED_COMBINATIONS=()
# generate all combinations of allowed versions use the following command:
for ubuntu in "${ALLOWED_UBUNTU_VERSION[@]}"; do
  for ccs in "${ALLOWED_CCS_VERSION[@]}"; do
    for ccs_comp in "${ALLOWED_CCS_COMPONENTS[@]}"; do
      for mmw in "${ALLOWED_MMWSDK_VERSION[@]}"; do
        for mmw_comp in "${ALLOWED_MMWSDK_COMPONENTS[@]}"; do
          for bios in "${ALLOWED_BIOS_VERSION[@]}"; do
            ALLOWED_COMBINATIONS+=("|${ubuntu}|${ccs}|${ccs_comp}|${mmw}|${mmw_comp}|${bios}|")
          done
        done
      done
    done
  done
done

# Compute image tag
MAJOR_MINOR="$(echo "${CCS_VER}" | awk -F. '{print $1 "." $2}')"
SUFFIX=""
if [[ -n "${MMW_VER}" ]]; then SUFFIX="-mmw"; fi
TAG="${MAJOR_MINOR}-ubuntu${UBUNTU}${SUFFIX}"
IMAGE_GHCR="${IMAGE_BASE_GHCR}:${TAG}"
IMAGE_DOCKERHUB="${IMAGE_BASE_DOCKERHUB}:${TAG}"

# Determine if pulling is allowed
can_pull=false
input_comb="|${UBUNTU}|${CCS_VER}|${CCS_COMP}|${MMW_VER}|${MMW_COMP}|${BIOS_VER}|"
for v in "${ALLOWED_COMBINATIONS[@]}"; do
  if [[ "${input_comb}" == "$v" ]]; then
    can_pull=true
    break
  fi
done

echo "::group::CCS Image Tag Info"
echo "CCS_VER = ${CCS_VER}"
echo "can_pull = ${can_pull}"
echo "Computed TAG = ${TAG}"
echo "::endgroup::"

# Pull image or build
if [[ "${can_pull}" == "true" ]]; then
  if docker pull "${IMAGE_GHCR}"; then
    IMAGE="${IMAGE_GHCR}"
    echo "::notice ::Pulled image from GHCR: ${IMAGE}"
  elif docker pull "${IMAGE_DOCKERHUB}"; then
    IMAGE="${IMAGE_DOCKERHUB}"
    echo "::notice ::Pulled image from DockerHub: ${IMAGE}"
  else
    echo "::warning ::Pull failed, falling back to build"
    BUILD_IMAGE=true
  fi
else
  echo "::notice ::Version not in allowed combinations, building image"
  echo "::warning ::Allowed combinations: ${ALLOWED_COMBINATIONS[*]}"
  BUILD_IMAGE=true
fi

# Build if needed
if [[ "${BUILD_IMAGE:-false}" == "true" ]]; then
  echo "::group::Building Docker image from source"
  git clone --depth=1 "${DOCKERFILE_REPO}" ccs-docker
  cd ccs-docker
  docker buildx build \
    --build-arg OS_VERSION="${UBUNTU}" \
    --build-arg CCS_VERSION="${CCS_VER}" \
    --build-arg CCS_COMPONENTS="${CCS_COMP}" \
    --build-arg MMWSDK_VERSION="${MMW_VER}" \
    --build-arg MMWSDK_COMPONENTS="${MMW_COMP}" \
    --build-arg BIOS_VERSION="${BIOS_VER}" \
    -t "${IMAGE_GHCR}" .
  cd -
  rm -rf ccs-docker
  IMAGE="${IMAGE_GHCR}"
  echo "::notice ::Built image locally: ${IMAGE}"
  echo "::endgroup::"
fi

# Export image name and tag
echo "IMAGE=${IMAGE}" >> "$GITHUB_OUTPUT"
echo "TAG=${TAG}" >> "$GITHUB_OUTPUT"
