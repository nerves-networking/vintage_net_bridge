# Changelog

## v0.10.3

* Changes
  * Fix retry failure in up_cmds due to not cleaning up the existing bridge.

## v0.10.2

* Changes
  * Normalize configurations to avoid errors when using static IP addresses.
    Thank to @pojiro for this fix.
  * Fix non-determinism is configuration file order when using OTP 26 due to map
    sort order change.

## v0.10.1

* Changes
  * Support `vintage_net v0.11.x` as well.

## v0.10.0

This release is backwards compatible with v0.9.2. No changes are needed to
existing code.

## v0.9.0

* New features
  * Synchronize with vintage_net v0.9.0's networking program path API update

## v0.8.0

Initial release
