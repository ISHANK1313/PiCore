# Skill: Security Alert

## Trigger

Automatic — fires when Fail2Ban bans an IP, or when user asks
about security events, banned IPs, or intrusion attempts.

## Check Current Bans

```bash
sudo fail2ban-client status sshd
sudo fail2ban-client status nextcloud
```

## Check Auth Log for Recent Attempts

```bash
sudo grep "Failed password" /var/log/auth.log | tail -20
sudo grep "Ban " /var/log/fail2ban.log | tail -10
```

## Check UFW Denied Connections

```bash
sudo grep "UFW BLOCK" /var/log/ufw.log | tail -10
```

## Unban an IP (if you locked yourself out)

Confirm first, then:
```bash
sudo fail2ban-client set sshd unbanip <IP_ADDRESS>
```

## Alert Format

When reporting a ban event:
```
🚨 Intrusion attempt blocked
IP: <address>
Service: SSH / Nextcloud
Attempts: <count>
Action: Banned for 3600s
```

## Permanent Block via UFW

If a specific IP is repeatedly attacking, add permanent UFW rule:
```bash
sudo ufw deny from <IP_ADDRESS>
sudo ufw reload
```

Confirm before executing.
