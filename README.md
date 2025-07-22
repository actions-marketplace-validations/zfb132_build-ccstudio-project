[![GitHub release](https://img.shields.io/github/release/zfb132/build-ccstudio-project.svg?style=flat-square)](https://github.com/zfb132/build-ccstudio-project/releases/latest)
[![GitHub marketplace](https://img.shields.io/badge/marketplace-ccstudio--docker--build-blue?logo=github&style=flat-square)](https://github.com/marketplace/actions/ti-ccstudio-docker-build-projects)

# TI CCStudio Docker Build Projects

GitHub Action to build TI Code Composer Studio (CCStudio) projects inside a Docker container, with automatic image build or pull support. This helps you build embedded projects reproducibly in CI environments without installing CCS manually.  
The prebuilt Docker image is available on [GitHub Container Registry](https://github.com/zfb132/build-ccstudio-project/pkgs/container/ccstudio) and [Docker Hub](https://hub.docker.com/r/whuzfb/ccstudio).  

## Docker Image Resolution Order
When running this GitHub Action, Docker images are resolved in the following priority order:

1. **GitHub Docker Registry**  
   If credentials are provided and permissions are configured (`contents: read`, `packages: write`), the Action will first attempt to pull prebuilt images from GitHub's Docker registry. You must authenticate with `ghcr.io` before using this Action by adding a login step, such as [docker/login-action](https://github.com/docker/login-action).

2. **Docker Hub Registry**  
   If the image is not found or configured in GitHub's registry, the Action will attempt to pull from Docker Hub.

3. **Local Image Build**  
   If the specified CCS configuration parameters (e.g., Ubuntu version, CCS version, mmwave SDKs, etc.) do not match any prebuilt image, the Action will automatically build a custom Docker image locally based on the provided inputs.


## Usage

```yaml
name: ci

on:
  push:
    branches: [main]

# this is only needed if you want to use the prebuilt image from GitHub Container Registry
permissions:
  contents: read
  packages: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      # this is only needed if you want to use the prebuilt image from GitHub Container Registry
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Run CCS build
        uses: zfb132/build-ccstudio-project@v1
        with:
          project_location: "./your_project.projectspec"
          build_type: "Release"
```

## Examples

```yaml
      - name: Build multiple CCS projects
        uses: zfb132/build-ccstudio-project@v1
        with:
          project_location: "proj1,proj2,proj3"
          build_type: "Debug"
          results_dir: "./ccs_build_results"
          ubuntu_version: "22.04"
          ccs_version: "12.8.1.00005"
          mmwsdk_version: "03.06.02.00-LTS"
          time_zone: "Asia/Shanghai"
```

## Inputs

|         Name        |                   Default                  | Description |
|        :---:        |                    :---:                   |    :---:    |
| `project_location`  | —                                          | **required** Comma-separated paths to `.projectspec` or CCS project folders; locations can be relative to `${{ github.workspace }}`; referenced projects are imported automatically. e.g. `./out_of_box_6843_isk_mss.projectspec` |
| `build_type`        | `Release`                                  | Build type (`Release` or `Debug`) |
| `results_dir`       | `results_${{ github.run_id }}_${{ github.run_attempt }}` | Directory where build results will be saved (relative to `${{ github.workspace }}`) |
| `time_zone`         | `UTC`                                      | Time zone (e.g., `Asia/Shanghai`) |
| `ubuntu_version`    | `24.04`                                    | Ubuntu version: `20.04`, `22.04`, or `24.04` |
| `ccs_version`       | `20.2.0.00012`                             | [Code Composer Studio](https://www.ti.com/tool/download/CCSTUDIO) version, e.g., `20.2.0.00012` |
| `ccs_components`    | `PF_ALL`                                   | [CCS components](https://software-dl.ti.com/ccs/esd/documents/ccs_installer-cli.html) to install, e.g., `PF_ALL` or `"PF_MMWAVE,PF_C6000SC,PF_TM4C"` |
| `mmwsdk_version`    | `03.06.02.00-LTS`                          | [mmWave SDK](https://www.ti.com/tool/download/MMWAVE-SDK) version, e.g., `03.06.02.00-LTS` or `""`(skip installation) |
| `mmwsdk_components` | `ALL`                                      | mmWave SDK components, e.g., `ALL` or `""`(skip installation) |
| `bios_version`      | `""`                                       | [SYS/BIOS](https://software-dl.ti.com/dsps/dsps_public_sw/sdo_sb/targetcontent/bios/sysbios/) version, e.g., `"6.73.01.01"` or `""`(skip installation) |
| `entrypoint`        | `""`                                       | **Advanced usage**: script path to override Docker entrypoint (relative to `${{ github.workspace }}`), e.g. `./entrypoint.sh` |

## Outputs

| Name         | Description |
|--------------|-------------|
| `results_dir`| The absolute path to the build results directory |

## Prebuilt Docker Images
The build configurations for prebuilt Docker images are defined in the following table:  

|       Docker Tag       | Ubuntu Version |   CCS Version     | CCS Components | mmWave SDK Version | mmWave SDK Components | SYS/BIOS Version |
|         :---:          |      :---:     |       :---:       |      :---:     |       :---:        |         :---:         |      :---:       |
| `20.2-ubuntu24.04-mmw` | `24.04`        | `20.2.0.00012`    | `PF_ALL`       | `03.06.02.00-LTS`  | `ALL`                 | `""` (skip)      |
| `20.2-ubuntu24.04`     | `24.04`        | `20.2.0.00012`    | `PF_ALL`       | `""` (skip)        | `ALL`                 | `""` (skip)      |
| `20.2-ubuntu22.04-mmw` | `22.04`        | `20.2.0.00012`    | `PF_ALL`       | `03.06.02.00-LTS`  | `ALL`                 | `""` (skip)      |
| `20.2-ubuntu22.04`     | `22.04`        | `20.2.0.00012`    | `PF_ALL`       | `""` (skip)        | `ALL`                 | `""` (skip)      |
| `20.2-ubuntu20.04-mmw` | `20.04`        | `20.2.0.00012`    | `PF_ALL`       | `03.06.02.00-LTS`  | `ALL`                 | `""` (skip)      |
| `20.2-ubuntu20.04`     | `20.04`        | `20.2.0.00012`    | `PF_ALL`       | `""` (skip)        | `ALL`                 | `""` (skip)      |
| `12.8-ubuntu24.04-mmw` | `24.04`        | `12.8.1.00005`    | `PF_ALL`       | `03.06.02.00-LTS`  | `ALL`                 | `""` (skip)      |
| `12.8-ubuntu24.04`     | `24.04`        | `12.8.1.00005`    | `PF_ALL`       | `""` (skip)        | `ALL`                 | `""` (skip)      |
| `12.8-ubuntu22.04-mmw` | `22.04`        | `12.8.1.00005`    | `PF_ALL`       | `03.06.02.00-LTS`  | `ALL`                 | `""` (skip)      |
| `12.8-ubuntu22.04`     | `22.04`        | `12.8.1.00005`    | `PF_ALL`       | `""` (skip)        | `ALL`                 | `""` (skip)      |
| `12.8-ubuntu20.04-mmw` | `20.04`        | `12.8.1.00005`    | `PF_ALL`       | `03.06.02.00-LTS`  | `ALL`                 | `""` (skip)      |
| `12.8-ubuntu20.04`     | `20.04`        | `12.8.1.00005`    | `PF_ALL`       | `""` (skip)        | `ALL`                 | `""` (skip)      |
| `11.2-ubuntu24.04-mmw` | `24.04`        | `11.2.0.00007`    | `PF_ALL`       | `03.06.02.00-LTS`  | `ALL`                 | `""` (skip)      |
| `11.2-ubuntu24.04`     | `24.04`        | `11.2.0.00007`    | `PF_ALL`       | `""` (skip)        | `ALL`                 | `""` (skip)      |
| `11.2-ubuntu22.04-mmw` | `22.04`        | `11.2.0.00007`    | `PF_ALL`       | `03.06.02.00-LTS`  | `ALL`                 | `""` (skip)      |
| `11.2-ubuntu22.04`     | `22.04`        | `11.2.0.00007`    | `PF_ALL`       | `""` (skip)        | `ALL`                 | `""` (skip)      |
| `11.2-ubuntu20.04-mmw` | `20.04`        | `11.2.0.00007`    | `PF_ALL`       | `03.06.02.00-LTS`  | `ALL`                 | `""` (skip)      |
| `11.2-ubuntu20.04`     | `20.04`        | `11.2.0.00007`    | `PF_ALL`       | `""` (skip)        | `ALL`                 | `""` (skip)      |
| `10.4-ubuntu24.04-mmw` | `24.04`        | `10.4.0.00006`    | `PF_ALL`       | `03.06.02.00-LTS`  | `ALL`                 | `""` (skip)      |
| `10.4-ubuntu24.04`     | `24.04`        | `10.4.0.00006`    | `PF_ALL`       | `""` (skip)        | `ALL`                 | `""` (skip)      |
| `10.4-ubuntu22.04-mmw` | `22.04`        | `10.4.0.00006`    | `PF_ALL`       | `03.06.02.00-LTS`  | `ALL`                 | `""` (skip)      |
| `10.4-ubuntu22.04`     | `22.04`        | `10.4.0.00006`    | `PF_ALL`       | `""` (skip)        | `ALL`                 | `""` (skip)      |
| `10.4-ubuntu20.04-mmw` | `20.04`        | `10.4.0.00006`    | `PF_ALL`       | `03.06.02.00-LTS`  | `ALL`                 | `""` (skip)      |
| `10.4-ubuntu20.04`     | `20.04`        | `10.4.0.00006`    | `PF_ALL`       | `""` (skip)        | `ALL`                 | `""` (skip)      |

## How it works

1. A Docker image with CCS and SDK components is built or pulled.
2. The specified project(s) are built inside a container.
3. Build artifacts are placed in the `results_dir`.

This action ensures reproducibility, simplifies CCS CI integration, and isolates build dependencies in Docker.  
