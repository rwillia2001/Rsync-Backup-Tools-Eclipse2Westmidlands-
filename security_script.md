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
