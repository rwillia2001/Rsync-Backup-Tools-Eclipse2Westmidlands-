Awesome — here’s a single, safe Bash script that locks Ubuntu to security-only updates, disables the daily auto-upgrade timers, and keeps everything reversible.

It does not remove packages or reboot. It:

Pins APT so only noble-security (and optional Ubuntu Pro ESM security, if attached) are allowed.

Limits unattended-upgrades to security origins only.

Disables apt-daily timers so nothing surprises you.

Has --status and --revert modes.
