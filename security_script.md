Awesome — here’s a single, safe Bash script that locks Ubuntu to security-only updates, disables the daily auto-upgrade timers, and keeps everything reversible.

It does not remove packages or reboot. It:

Pins APT so only noble-security (and optional Ubuntu Pro ESM security, if attached) are allowed.

Limits unattended-upgrades to security origins only.

Disables apt-daily timers so nothing surprises you.

Has --status and --revert modes.
2) Make it executable & apply
chmod +x security_only_updates.sh
sudo ./security_only_updates.sh --apply

3) Verify
sudo ./security_only_updates.sh --status


In APT policy, you should see noble-security (and possibly noble-*-security for ESM) but no upgrades from noble-updates/backports/proposed.

Timers/services for apt-daily* should be disabled/inactive.

The unattended-upgrades override should show only security origins.

4) Revert (if you ever want to)
sudo ./security_only_updates.sh --revert

Notes for power users

This approach uses APT pinning instead of deleting or rewriting your sources, so it’s non-destructive and easy to undo.

If you’re not attached to Ubuntu Pro, the ESM entries in the pin/override are harmless (they simply won’t apply).

You can still apply security patches manually any time:

sudo unattended-upgrade --dry-run
sudo unattended-upgrade


or

sudo apt update && sudo apt upgrade


(Only security updates will be candidates due to the pinning.)

Want me to tailor this for your other machines (Eclipse, Africa) and put it behind a one-liner curl installer or Ansible play?
=============================================================================================================================



Great—your status dump shows it’s working exactly as intended. Here’s the quick read:

What your output means

Security-only repos are active at priority 500:

noble-security ... origin security.ubuntu.com ✅

Non-security pockets are hard-blocked:

All noble-updates and noble-backports show Pin-Priority: -1 ✅

Base release (noble) is visible at 500 (that’s fine—doesn’t upgrade anything; it’s just the original release versions).

apt timers/services: disabled/inactive ✅

unattended-upgrades: restricted to security origins only ✅
(The debug lines show it’s actively pinning out non-security sources and third-party repos during unattended runs—expected.)

Two quick sanity checks (optional)
apt list --upgradable
# Expect: either nothing, or only security-tagged updates if available

sudo unattended-upgrade --dry-run --debug | egrep 'Packages that will be upgraded|Checking|Found'
# Expect: no non-security packages listed

Notes / options

Google Chrome: It won’t auto-update via unattended-upgrades now (because we allow only Ubuntu security origins). That’s conservative and avoids surprises. If you do want Chrome to auto-update for security, say the word and I’ll add a tiny safe stanza to permit only that origin.

Ubuntu Pro / ESM: You’re set to allow ESM security if you ever attach (pro attach <token>; pro enable esm-apps esm-infra). If you don’t use Pro, those lines are harmless.

You’re locked down to security patches only, with background updaters neutered—no feature updates, no version jumps, no surprise kernels. ✔️
