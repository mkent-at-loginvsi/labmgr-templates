# azure-rds-lab

Stands up a small, on-premises-style Remote Desktop Services (RDS) lab —
a real RD Connection Broker with pure Active Directory login, no Entra ID
or Azure RBAC involved anywhere:

- A Windows Server 2022 VM promoted to the first domain controller of a new
  Active Directory forest (`domain_name`).
- A dedicated RD Connection Broker / RD Web Access server, domain-joined.
- `session_host_count` Windows Server 2022 session hosts, domain-joined,
  running the RD Session Host role, collected into a single "SessionDesktop"
  session collection managed by the broker.
- `test_user_count` AD test accounts (`testuser01`, `testuser02`, ...),
  members of a `SessionDesktop` AD group that's granted local RDP access
  (`Remote Desktop Users`) on every session host.

This is the sibling of `azure-avd-lab` for scenarios that need a real
broker but can't (or don't want to) involve Entra ID: Windows 11
multi-session images are licensed exclusively for Azure Virtual Desktop /
Windows 365 and can't run the on-premises RD Session Host role, so this
template uses Windows Server session hosts instead.

## How it works

Terraform provisions the network and VMs, then outputs `ansible_inventory`.
Lab Manager runs `ansible/site.yml` against that inventory to:

1. Promote the DC (`microsoft.ad.domain`, forest creation + reboot).
2. Create the `SessionDesktop` AD group and `test_user_count` test
   accounts, added to that group (`microsoft.ad.group`, `microsoft.ad.user`).
3. Join the session hosts and the broker to the domain
   (`microsoft.ad.membership`) and add `SessionDesktop` to each session
   host's local `Remote Desktop Users` group (`win_group_membership`).
4. Install the RD Session Host role on the session hosts, and the RD
   Connection Broker / RD Web Access / RSAT-RDS-Tools roles on the broker
   (`win_feature`, with reboots as needed).
5. Create the RDS deployment and a `SessionDesktop` session collection
   spanning the session hosts, from the broker (`New-RDSessionDeployment`,
   `New-RDSessionCollection` via the `RemoteDesktop` PowerShell module).

Every VM gets a `CustomScriptExtension` at boot that enables WinRM (HTTP,
basic auth) so Ansible can connect immediately — access is restricted by
the NSG to `admin_source_cidr` only. This is intentionally simple for a
short-lived lab; it is **not** a hardened configuration and shouldn't be
reused for anything long-lived or exposed beyond your own IP.

## Connecting

- **RD Web Access**: browse to the `rd_web_access_url` terraform output
  (`https://<broker-ip>/RDWeb`) and sign in with any AD account (e.g. one
  of the `testuser01..N` accounts, or `admin_username`). The certificate
  is self-signed, so expect a browser warning.
- **Direct RDP**: any session host's public IP also accepts RDP directly
  with an AD account already in `Remote Desktop Users` — useful for load
  test tooling that connects straight to hosts rather than through the
  broker's web portal.

## Prerequisites on the Lab Manager host

- Azure credentials available to the `azurerm` Terraform provider (e.g.
  `az login`, or `ARM_CLIENT_ID`/`ARM_CLIENT_SECRET`/`ARM_SUBSCRIPTION_ID`/
  `ARM_TENANT_ID` environment variables) with rights to create resource
  groups, networking, and VMs in the target subscription.
- Ansible collections installed once: `ansible-galaxy collection install -r ansible/requirements.yml`.
- RDS licensing: this template doesn't configure an RD Licensing server or
  CALs. Windows Server RDS deployments run for a 120-day grace period
  without one, which comfortably covers a short-lived lab — if you extend
  an instance's TTL well beyond that, you'll need to add RDS CAL licensing
  yourself.

## Required variables

- `admin_source_cidr` has no default — set it to your own public IP (e.g.
  `203.0.113.4/32`) so RDP, WinRM, and RD Web aren't reachable from the
  whole internet.
- `test_user_password` has no default — set a password for the AD test
  accounts (shared across all of them).
