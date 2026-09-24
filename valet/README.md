# Valet Linux DNS fixes

Snapshot of the working configuration from 2026-09-24. These files are stored
individually so changes can be reviewed in Git.

| Saved file | Installed location | Purpose |
| --- | --- | --- |
| `opt/valet-linux/valet-dns` | `/opt/valet-linux/valet-dns` | Read live resolver sources only, exclude loopback upstream servers, normalize search domains, and write complete files atomically. Ignore events caused by generated files. |
| `etc/dnsmasq.d/valet-vpn-kosatec` | `/etc/dnsmasq.d/valet-vpn-kosatec` | Send `kosatec.lan` queries to the company VPN DNS servers. |
| `etc/systemd/system/valet-dns.service.d/90-dns-watcher-cleanup.conf` | `/etc/systemd/system/valet-dns.service.d/90-dns-watcher-cleanup.conf` | Stop all watcher subprocesses when restarting the service. |

The Composer package itself was not modified. Valet copies its packaged watcher
template to `/opt/valet-linux/valet-dns` during `valet install`, overwriting the
installed fix. Compare a newer Valet version with this snapshot before restoring
the script. The VPN configuration uses DNS servers `192.168.113.102` and
`192.168.113.103`; adjust it if the company VPN DNS addresses change.

## Restore

Install Valet first as described in [MANUAL.md](../MANUAL.md). Run the following
commands from the dotfiles repository root. Restarting DNS briefly interrupts
name resolution.

```bash
bash -n valet/opt/valet-linux/valet-dns

# Apply process cleanup before stopping an older watcher.
sudo install -D -m 0644 \
  valet/etc/systemd/system/valet-dns.service.d/90-dns-watcher-cleanup.conf \
  /etc/systemd/system/valet-dns.service.d/90-dns-watcher-cleanup.conf
sudo systemctl daemon-reload
sudo systemctl stop valet-dns.service

sudo install -m 0755 valet/opt/valet-linux/valet-dns \
  /opt/valet-linux/valet-dns
sudo install -m 0644 valet/etc/dnsmasq.d/valet-vpn-kosatec \
  /etc/dnsmasq.d/valet-vpn-kosatec
sudo dnsmasq --test
sudo systemctl start valet-dns.service
sudo systemctl restart dnsmasq.service
sudo resolvectl flush-caches
```

The watcher regenerates `/opt/valet-linux/resolv.conf` and `dns-servers` from the
current network configuration. These generated files are deliberately excluded
from this snapshot. `install.sh` and `collect.sh` do not manage this snapshot;
restoration and refreshing the saved copies are manual.

## Validation on the original machine

- Before the repair, public HTTPS requests spent about five seconds resolving DNS.
- After the repair, public requests resolved in milliseconds with and without VPN.
- Internal `kosatec.lan` DNS records resolved through the VPN servers.
- Local `.test` names continued to resolve to `127.0.0.1`.
- Generated files and watcher CPU usage stayed unchanged while idle.
