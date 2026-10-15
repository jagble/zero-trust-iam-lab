# Design: Zero Trust and Identity Governance for PDS

> **Summary:** The planned Conditional Access policies, PIM settings, access packages, access reviews and monitoring for the Potomac Defense Systems Entra ID tenant, written before implementation. Each section ends with how I'll test it.

> **About this lab:** Potomac Defense Systems is a fictional company. All people and data are made up.

**Status:** design approved, implementation in progress. Anything that changes during the build gets recorded in the build log, not silently edited here.

---

## 1. Guiding rules

1. **Never lock out every admin.** A break-glass account exists before the first policy, and every policy excludes it
2. **Report-only first.** Every Conditional Access policy runs in report-only mode, I check its impact in the sign-in logs, and only then turn it on
3. **No standing privilege.** The only permanent admin is break-glass. Everything else is just in time
4. **Access expires by default.** Requested access has an end date and a review. Nothing is granted "until someone remembers to remove it"
5. **Cloud groups for cloud changes.** Synced AD groups are read-only in Entra, so anything Entra has to change uses a cloud-only group

## 2. Emergency access (break-glass)

| Setting | Value | Why |
|---|---|---|
| Account | `breakglass01@PotomacDefenseSystems.onmicrosoft.com` | Cloud-only `.onmicrosoft.com` account, so it works even if sync or a custom domain breaks |
| Role | Global Administrator, **permanently active** | The one exception to PIM. If PIM or approvals break, this still works |
| Password | 25+ character passphrase, stored offline | Never used day to day |
| MFA | Registered (Microsoft requires MFA for admin portals) | In production this would be a FIDO2 security key kept in a safe |
| Conditional Access | Excluded from every policy through `CA-Exclude-EmergencyAccess` | A single bad policy can't lock out every admin |
| Monitoring | Alert on **any** sign-in (Log Analytics alert rule) | It should never be used. If it is, someone needs to know immediately |

**Test:** sign in with it in a private window before creating any policy, and confirm the alert fires.

## 3. Conditional Access policies

Before any of these are turned on, **security defaults are turned off**, in the same session. The tenant is never left with neither.

| Policy | Users | Apps / conditions | Control | Notes |
|---|---|---|---|---|
| **CA001** Require MFA for all users | All users | All resources | Require MFA | Replaces security defaults |
| **CA002** Block legacy authentication | All users | Client apps: Exchange ActiveSync, other clients | Block | Legacy protocols can't do MFA, so they're an MFA bypass |
| **CA003** Phishing-resistant MFA for admins | Admin directory roles (Global, Privileged Role, User, Helpdesk, Security, Conditional Access Administrator) | All resources | Authentication strength: **phishing-resistant MFA** | Passkeys or FIDO2 keys. Admins are the main target of MFA phishing |
| **CA004** Block leavers | Group `CA-Block-Leavers` (cloud group) | All resources | **Block** | Closes the Project 1 gap. See section 4 |
| **CA005** Sign-in risk | All users | Sign-in risk: medium or high | Require MFA | Identity Protection. Catches anonymous IPs, impossible travel, unfamiliar sign-ins |
| **CA006** User risk | All users | User risk: high | Require secure password change + MFA | For accounts Identity Protection believes are compromised |
| **CA007** Block outside the US | All users | Locations: all except named location "United States" | Block | Common in federal and defense environments. Break-glass excluded like every other policy |

All policies exclude `CA-Exclude-EmergencyAccess`.

**Test:** for each policy, run report-only, read the *Report-only* result on real sign-ins, then turn it on and sign in as an affected test user. The **What If** tool confirms which policies apply to a given user before turning anything on.

## 4. The leaver block (closing the 79-second gap)

**The problem from Project 1:** disabling a user in AD doesn't reach Entra until the next sync, and their old password was still accepted in the cloud 79 seconds after the leaver ran.

**The design:**
1. A cloud-only security group, `CA-Block-Leavers`
2. CA004 blocks every member of that group from every app
3. The Project 1 leaver adds the user to the group **through Microsoft Graph**, right after revoking their sessions. A cloud group changes instantly, with no sync involved
4. When the cleanup is complete and the account shows disabled in Entra, the user stays in the group until the account is deleted

**Trade-off:** adding users to a group requires a new Graph permission for the engine (`GroupMember.ReadWrite.All`), which is broader than "this one group." I'll document the risk, and in production I'd look at restricting it, for example with a restricted-management administrative unit.

**Test:** repeat the Project 1 measurement. Sign in as a test user, run the leaver, and record how long the old password still works. Compare against 79 seconds.

## 5. Privileged Identity Management

| Role | Assignment | Max activation | Requires | Approver |
|---|---|---|---|---|
| Global Administrator | Eligible | 1 hour | MFA, justification, **approval** | Monica Hayes (Security) |
| Privileged Role Administrator | Eligible | 1 hour | MFA, justification, **approval** | Monica Hayes (Security) |
| User Administrator | Eligible | 4 hours | MFA, justification | None |
| Helpdesk Administrator | Eligible | 8 hours | MFA, justification | None |
| Security Reader | Eligible | 8 hours | MFA | None |

- **Permanent active roles:** break-glass only. My daily cloud admin account goes from permanent Global Admin to **eligible**
- **Notifications:** every activation emails the Security team
- **PIM alerts:** turned on for "roles assigned outside PIM" and "too many Global Administrators"

**Test:** activate Global Admin, confirm the approval request reaches the approver, approve it, confirm the role expires on its own after an hour, and check the audit log for each step.

## 6. Access packages (entitlement management)

**Catalog:** `PDS Programs`

| Access package | Resource | Who can request | Approval | Expires |
|---|---|---|---|---|
| Radar Program Access | Cloud group `AP-Radar-Program-Data` | Members of `GG-Role-Engineers` | Stage 1: requester's **manager**. Stage 2: Radar program manager (**Tom Haskins**) | 90 days |
| Satellite Program Access | Cloud group `AP-Satellite-Program-Data` | Members of `GG-Role-Engineers` | Manager, then **Elena Vasquez** | 90 days |
| Shipboard Program Access | Cloud group `AP-Shipboard-Program-Data` | Members of `GG-Role-Engineers` | Manager, then **Gregory Okafor** | 90 days |

- **Request questions:** business justification, and an attestation that CUI training is complete, which mirrors the Project 1 program checks
- **Separation of duties:** separate packages for Finance and Accounts Payable access, configured as **incompatible**, so nobody can hold both. This is the Project 1 SoD rule enforced at request time instead of after the fact
- **Expiration:** users get a notification before access expires, and can request an extension, which goes through approval again

**Test:** request Radar access as an engineer, approve both stages, confirm group membership, then confirm that a request for an incompatible package is refused.

## 7. Access reviews

| Review | Scope | Reviewer | Frequency | If the reviewer doesn't respond |
|---|---|---|---|---|
| Program access | Assignments of each access package | User's **manager** (fallback: Monica Hayes) | Quarterly | Remove access |
| Privileged roles | Eligible and active Entra admin roles | Monica Hayes (Security) | Quarterly | Remove access |

- **Auto-apply results:** on. A "deny" removes access without someone having to do it by hand
- **Reviewer helpers:** show recommendations (for example, users who haven't signed in for 30 days)

**Test:** run each review once, deny one assignment, and confirm the access is removed automatically.

## 8. Monitoring and logging

- **Diagnostic settings:** send Entra **sign-in** and **audit** logs to a Log Analytics workspace (small, short retention to keep cost low)
- **Alerts:**
  - Any sign-in by `breakglass01`
  - Any change to a Conditional Access policy
  - Any Global Administrator activation
- **KQL queries** saved for the incident response part: sign-ins by risk level, failed MFA, sign-ins blocked by CA004

## 9. Identity metrics (part 2.7)

| Metric | Source | Target |
|---|---|---|
| MFA registration coverage | Authentication methods → user registration details | 100% of active users |
| Standing privileged role assignments | PIM | 1 (break-glass) |
| Access review completion | Access reviews | 100%, with removals counted |
| Stale accounts (no sign-in in 90 days) | Sign-in activity | Identified and reviewed |
| Sign-ins blocked by legacy auth policy | Sign-in logs | Tracked |

## 10. Rollback

If a policy causes unexpected lockouts:
1. Sign in as break-glass
2. Set the policy back to **report-only** (not deleted, so the configuration is kept for troubleshooting)
3. Use the sign-in logs and **What If** to find the cause, fix it, and repeat report-only before turning it back on
