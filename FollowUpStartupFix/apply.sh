#!/bin/bash
set -euo pipefail
fix_root="$(cd "$(dirname "$0")" && pwd -P)"
if [[ $# -ne 1 ]]; then
  printf '%s\n' 'Usage: bash apply.sh /absolute/path/to/existing/FollowUpDemo' >&2
  exit 2
fi
target_root="$(cd "$1" && pwd -P)"
if [[ ! -f "$target_root/ios/DisplayAccess.xcodeproj/project.pbxproj" ]]; then
  printf '%s\n' 'The target is not the existing FollowUpDemo folder; nothing was changed.' >&2
  exit 2
fi
files=(
  scripts/mac-check.sh
  ios/FollowUp/FollowUpApp.swift
  ios/FollowUp/Models.swift
  ios/FollowUpTests/FollowUpTests.swift
)
for relative in "${files[@]}"; do
  if [[ ! -f "$fix_root/$relative" || ! -f "$target_root/$relative" ]]; then
    printf 'Missing patch or target file: %s. Nothing was changed.\n' "$relative" >&2
    exit 2
  fi
done
mkdir -p "$target_root/build-evidence"
backup_root="$(mktemp -d "$target_root/build-evidence/startup-fix-backup.XXXXXX")"
# Back up every affected file before making any replacements.
for relative in "${files[@]}"; do
  mkdir -p "$backup_root/$(dirname "$relative")"
  cp -p "$target_root/$relative" "$backup_root/$relative"
done
for relative in "${files[@]}"; do
  cp -p "$fix_root/$relative" "$target_root/$relative"
done
printf 'Startup/signing fix applied. Original files saved in:\n%s\n' "$backup_root"
printf '%s\n' 'Xcode project, Apple team settings, backend secrets and data were not replaced.'
printf '%s\n' 'From the existing FollowUpDemo folder, rerun mac-check.sh with your iPhone simulator UUID.'
