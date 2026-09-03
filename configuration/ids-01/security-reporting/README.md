# ids-01 security reporting authority

Runtime target state:

- `homelab-greenbone-email.timer`: enabled, daily at 07:40.
- `homelab-secops-management-report.timer`: disabled.
- `homelab-greenbone-email.service` requires and runs after `homelab-secops-management-report.service`.
- `pihole-evidence.conf` runs the Pi-hole evidence collector before the email sender.
- The sender must retain fail-closed same-day report freshness validation.

Files beneath `systemd/` mirror their intended `/etc/systemd/system/` names and layout.
