# foundry

This directory defines the base NixOS configuration used when this repo builds cloud VM images and installer ISOs through nixpkgs' native image variant system.

It is not a normal day-to-day machine profile. Think of it as the common image template behind the `osImages.<variant>` outputs from `flake.nix`.

## What It Is Used For

- building install and rescue ISOs
- building cloud images for providers like AWS, Azure, GCE, and DigitalOcean
- building VM images for formats like VirtualBox, VMware, Hyper-V, and Proxmox
- bootstrapping a minimal but useful admin environment with SSH, Tailscale, and common debugging tools

## Related Surfaces

- `flake.nix` exposes curated `osImages.<variant>` outputs backed by `system.build.images`
- `flake.nix` also exposes `osImages.google-compute-cuda`, which layers NVIDIA driver and CUDA tooling onto the base GCE image
- `hosts/foundry/images.nix` extends `image.modules` for foundry-specific variants and tweaks
- `hosts/foundry/variants/<variant>.nix` is the hook for per-variant fixes
- `.github/workflows/foundry.yml` handles the related container-image publishing workflow
- `mods/foundry.nix` builds the task-focused container images that share the same foundry name, but that is a separate surface from this host profile

---

## Build And Load

### Google Compute Engine

Build the default GCE image:

```bash
out=$(nix build --print-out-paths .#osImages.google-compute)
artifact="$out/$(nix eval --raw .#osImages.google-compute.passthru.filePath)"
echo "$artifact"
```

Build the CUDA-enabled GCE image:

```bash
out=$(nix build --print-out-paths .#osImages.google-compute-cuda)
artifact="$out/$(nix eval --raw .#osImages.google-compute-cuda.passthru.filePath)"
echo "$artifact"
```

Upload the resulting `.raw.tar.gz` to Cloud Storage and create a Compute Engine image from it:

```bash
PROJECT_ID=your-project
BUCKET=your-image-bucket
IMAGE_FAMILY=nixos-google-compute-cuda
IMAGE_NAME="${IMAGE_FAMILY}-$(date +%Y%m%d-%H%M%S)"
STORAGE_LOCATION=us

gcloud storage cp "$artifact" "gs://$BUCKET/$IMAGE_NAME.raw.tar.gz"

gcloud compute images create "$IMAGE_NAME" \
  --project="$PROJECT_ID" \
  --source-uri="gs://$BUCKET/$IMAGE_NAME.raw.tar.gz" \
  --family="$IMAGE_FAMILY" \
  --storage-location="$STORAGE_LOCATION" \
  --guest-os-features=GVNIC
```

### AWS AMI

Build the default AWS image:

```bash
out=$(nix build --print-out-paths .#osImages.amazon)
artifact="$out/$(nix eval --raw .#osImages.amazon.passthru.filePath)"
echo "$artifact"
```

The upstream Amazon image variant currently emits a `.vhd`. Upload it to S3, then import it as an AMI with VM Import/Export:

```bash
AWS_REGION=us-east-1
BUCKET=your-import-bucket
KEY="images/$(basename "$artifact")"

aws s3 cp "$artifact" "s3://$BUCKET/$KEY" --region "$AWS_REGION"

aws ec2 import-image \
  --region "$AWS_REGION" \
  --description "nixos foundry amazon image" \
  --disk-containers "Format=VHD,UserBucket={S3Bucket=$BUCKET,S3Key=$KEY}"
```

This requires the AWS VM Import/Export prerequisites, especially an S3 bucket in the target region and the `vmimport` IAM role.

---

## In this directory

### [configuration.nix](./configuration.nix)

This contains the base NixOS configuration shared by the generated cloud and installer images.
