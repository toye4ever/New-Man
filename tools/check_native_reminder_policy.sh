#!/usr/bin/env bash
# Portable policy evidence only. Does not compile Android or operate a device.
set -euo pipefail
cd "$(dirname "$0")/.."
java_bin="${JAVA_HOME:?Set JAVA_HOME to JDK 21}/bin"
classes=$(mktemp -d "${TMPDIR:-/tmp}/new-man-native-policy.XXXXXX")
trap 'rm -rf "$classes"' EXIT
"$java_bin/javac" -encoding UTF-8 -d "$classes" \
  android/app/src/main/java/com/newman/newmanapp/*.java \
  android/app/src/test/java/com/newman/newmanapp/*.java
for suite in TaskReminderNativePolicyTest GuardFeaturePolicyTest GuardQualificationLeaseTest; do
  "$java_bin/java" -ea -cp "$classes" "com.newman.newmanapp.$suite"
done
