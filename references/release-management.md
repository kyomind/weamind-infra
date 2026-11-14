# Release Management

This repo is versioned with git tags, GitHub Releases, and `CHANGELOG.md` (written in Traditional Chinese, Keep a Changelog format). The changelog is read by people as portfolio material: every entry states why the change was made and what trade-off it carries, not only what changed.

## What a Tag Means

A tag marks a state that is already synced to the cluster and verified. It is recorded after the fact; it never triggers a deployment.

- Now (before GitOps): merge → manual `kubectl apply` → verify → tag.
- After GitOps is implemented: merge to `main` → Argo CD syncs automatically → the Application shows Synced and Healthy → tag. Argo CD tracks `main`, not tags. From then on, manual `kubectl apply` is prohibited in principle.

## Version Rules

Independent SemVer with a `v` prefix (`v1.2.3`). It is not tied to the WeaMind app version.

- major: a truly major change. Rare; see below.
- minor: a large change, such as a deployment behavior change (for example topology spread, PDB, NetworkPolicy)
- patch: a small change (for example image bump, value tuning)

Do not move to the next major version lightly. When unsure between minor and major, choose minor; only a change Kyo judges to be truly major bumps major.

## Changelog Flow

- A PR that changes cluster state adds its entry under `## [Unreleased]` in `CHANGELOG.md`, in the same PR.
- At release time, rename that block to `## [X.Y.Z] - YYYY-MM-DD` and leave a new empty `## [Unreleased]` above it.
- There is no changelog script, Makefile target, or approval gate. Edit the file by hand.

## Release Steps

To release, follow `.github/prompts/release.prompt.md`. It checks that `main` matches the cluster, suggests a version, asks Kyo to choose it, then finalizes `CHANGELOG.md`, tags, pushes, and verifies the result.

`.github/workflows/release.yml` creates the GitHub Release from that version's `CHANGELOG.md` section. It fails when the section is missing or empty; do not use auto-generated release notes.

Tagging and pushing are Kyo's decision. Do not tag or publish a release unless asked.
