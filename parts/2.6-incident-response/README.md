# Part 2.6: Incident Response

[← 2.5 Access Reviews](../2.5-access-reviews/README.md) · **2.6** · 2.7 Identity Metrics (next)

> **In this part:** I ran a simulated account compromise against a test user, Maria Lopez (Accounts Payable), then responded to it with the runbook I wrote in 2.1. I rebuilt the timeline from the logs, confirmed only one account was affected, contained it in 11 minutes, recovered it, and fixed the monitoring gap the incident exposed.
>
> **Headline finding:** Identity Protection detected the sign-ins in real time, but marked the risk **resolved** as soon as MFA was satisfied. Five minutes into the compromise, Maria's user risk read **"No risk,"** and no alert reached anyone.
>
> **Runbook:** [`docs/02-incident-response-runbook.md`](../../docs/02-incident-response-runbook.md) · **Incident report:** [`docs/03-incident-report-maria-lopez.md`](../../docs/03-incident-report-maria-lopez.md)

| # | Section | The lesson |
|---|---|---|
| 1 | [Setup](#1-setup) | The simulation and the response were kept separate |
| 2 | [Detection](#2-detection) | Detected in real time, then marked resolved |
| 3 | [Triage](#3-triage) | The timeline comes from the logs, not from memory |
| 4 | [Containment](#4-containment) | Revoke, block, confirm, reset: 11 minutes |
| 5 | [Investigation](#5-investigation) | No changes made, no new MFA method, fraud attempt refused |
| 6 | [Closing the gap](#6-closing-the-gap) | An alert for the sign-in nobody was told about |
| 7 | [Recovery](#7-recovery) | Account restored, risk cleared, every step logged |
| 8 | [Findings](#8-findings) | |

---

## 1. Setup

- **Scenario:** Maria's password is assumed phished. Her account is signed in to from an anonymizing network, and an MFA prompt she didn't start gets approved
- **Simulation:** run from a throwaway VM in its own resource group and network, not connected to PDS, and deleted afterward
- **Response:** done the next day, starting from the portal and the logs only, the way a responder would

Before the simulation, I recorded Maria's registered authentication methods as a baseline:

![Baseline: one Microsoft Authenticator](images/2.6-01-maria-methods-before.png)

## 2. Detection

Identity Protection flagged the sign-ins as **Anonymous IP address**, in real time, at medium and high risk:

![Risky sign-ins for Maria, all marked Remediated](images/2.6-04-risky-signins.png)

Every row says **Remediated**. The risk detail explains why:

![Anonymous IP address. Risk detail: User passed multifactor authentication](images/2.6-05-anonymous-ip-remediated.png)

CA005 did its job and required MFA on the risky sign-in. But once MFA was satisfied, Identity Protection treated the risk as resolved. **A compromised account that passes MFA looks the same as a legitimate user who passes MFA.**

## 3. Triage

**Timeline from the logs.** I didn't use any notes from the simulation. Everything below comes from `SigninLogs` and the risky sign-in details.

![First sign-in from the anonymizing network](images/2.6-07-first-attacker-signin.png)

![KQL: Maria's sign-ins in order](images/2.6-08-kql-attack-timeline.png)

| Time (EDT, Oct 26) | Event |
|---|---|
| 2:26 PM | 3 failed sign-ins, wrong password (50126), from a Colorado Springs IP |
| 2:28 PM | Password accepted |
| 2:29 PM | Sign-in succeeds. Sign-in risk **high**, MFA required by CA and satisfied |
| 2:29 PM onward | Source IP changes several times (Winchester, NH, and New York) |
| 2:32 PM | Security info page opened |
| 2:34 PM | Maria's user risk set to **Dismissed** by the system |
| 4:08–4:46 PM | Repeated sign-ins to **Entitlement Management** (access package requests) |
| 4:46 PM | Last sign-in from a flagged IP |

The 3 failed sign-ins were me mistyping the password during the simulation. In a real incident, failures followed by a success from the same anonymous IP would look like password guessing.

![The 4:09 PM sign-in: Entitlement Management, from a flagged IP](images/2.6-06-attacker-entitlement-signin.png)

**Scope.** Did the same IPs touch anyone else?

![KQL scope: 6 IPs, only Maria](images/2.6-09-kql-scope.png)

**175 sign-ins from 6 IPs, all against Maria.** One account to contain. My first scope query missed one IP because I typed the address prefixes by hand, and the source moved across networks. The second query caught it (see [finding 6](#8-findings)).

**User risk.** Maria showed **Dismissed, No risk**:

![Maria: Dismissed, risk level None](images/2.6-10-maria-risk-dismissed.png)

![Risk history: "Additional risk detected, Dismissed" at 2:34 PM, no actor](images/2.6-11-risk-history-dismissed.png)

I checked the audit log for an admin action in that window. There wasn't one, so the dismissal was automatic:

![No admin action against Maria during the attack window](images/2.6-12-who-dismissed-no-results.png)

**Decision:** in this scenario, Maria confirms by phone that she didn't sign in and approved a prompt she didn't start. **Confirmed compromise.**

## 4. Containment

**Role gap first.** My routine role, User Administrator, couldn't even see Maria's MFA methods. Removing a method someone else registered is a core containment step, so responders need **Authentication Administrator** ([finding 3](#8-findings)).

![User Administrator: "You do not have access to this data"](images/2.6-13-user-admin-cant-see-methods.png)

Containment, in the runbook's order. The times come from the audit log ([section 7](#7-recovery)):

| Time (EDT, Oct 27) | Action | Why |
|---|---|---|
| 4:44 PM | **Revoke sessions** | Kills tokens already issued |
| 4:45 PM | Add Maria to **`CA-Block-Leavers`** | CA004 blocks all cloud sign-ins immediately (the 2.2 leaver block, reused) |
| 4:47 PM | **Confirm user compromised** | Raises user risk to High, which re-arms CA006 |
| 4:55 PM | **Reset password in AD** to a random value | She's synced, so a cloud-only reset would be overwritten |

![Maria in CA-Block-Leavers](images/2.6-14-maria-in-block-group.png)

![Confirm user compromised](images/2.6-15-confirm-compromised.png)

![Confirmed compromised, High](images/2.6-16-confirmed-high-risk.png)

![AD password reset at 4:55:41 PM](images/2.6-17-ad-password-reset.png)

**11 minutes from first action to fully contained.** Responding the next day was a choice of the simulation, but it shows a real problem: with no alert, this compromise would only have been found by someone browsing Risky sign-ins.

## 5. Investigation

**What changed under Maria's account during the attack?**

![No directory changes made by Maria's account](images/2.6-18-kql-attacker-actions-none.png)

**Nothing.** No group changes, no app consents, no profile edits.

**Was a new MFA method added?** No. Her methods match the baseline:

![Methods after: still one Authenticator](images/2.6-19-methods-after.png)

SMS and voice are disabled in the tenant's authentication methods policy, so there was no phone option to register. **That removed the easiest way to keep access.**

**Was any access gained?** The Entitlement Management sign-ins were a request for **Finance Systems Access**. The separation-of-duties rule from 2.4 refused it before it was created, because Maria is in `GG-Role-AccountsPayable`:

![Finance request refused: incompatible group membership](images/2.6-03-attacker-finance-request-blocked.png)

## 6. Closing the gap

My alerts covered break-glass sign-ins, CA changes and Global Admin activation, but **not a successful risky sign-in**. I tested the query against the incident first:

```kql
SigninLogs
| where RiskLevelDuringSignIn in ("medium", "high")
| where ResultType == "0"
| project TimeGenerated, UserPrincipalName, IPAddress, City = tostring(LocationDetails.city), Risk = RiskLevelDuringSignIn, App = AppDisplayName
```

![The query returns the incident's sign-ins](images/2.6-20-kql-risky-success.png)

![ALERT-RiskySignIn-Success: Severity 1](images/2.6-21-alert-rule-risky-signin.png)

It alerts on the **sign-in itself**, so it fires even when Identity Protection later marks the risk as remediated.

One existing alert did fire during the response. Adding Maria to `CA-Block-Leavers` triggered the **CA group membership alert** from 2.2, at 4:53 PM:

![CA group membership alert fired on the containment step](images/2.6-22-block-group-alert-email.png)

That's the expected behavior: any change to the block or exclusion groups gets reported, including a responder's.

## 7. Recovery

1. Identity verified out of band (simulated)
2. New password set in AD and delivered out of band
3. User risk dismissed, **after** the reset, as the runbook says
4. Removed from `CA-Block-Leavers`
5. Maria signs in normally

The AD reset the day before didn't clear her risk. **"Allow on-premises password change to reset user risk"** was off, so I turned it on:

![On-premises password change now resets user risk](images/2.6-23-onprem-reset-setting.png)

![Maria signed in again](images/2.6-24-maria-signs-in-again.png)

Every response action is in the audit log, with who did it and when:

![Response timeline from the audit log](images/2.6-25-kql-response-timeline.png)

![Risk history: confirmed compromised, then dismissed by an admin](images/2.6-26-risk-history-final.png)

## 8. Findings

| # | Finding | Impact | Fix |
|---|---|---|---|
| 1 | **Passing MFA marked the risk as resolved** | Maria showed "No risk" five minutes into an active compromise | Alert on successful risky sign-ins, not on open risk (done). Phishing-resistant MFA for finance roles, like CA003 for admins |
| 2 | **No alert for a successful risky sign-in** | The compromise ran for over 2 hours with no notification | `ALERT-RiskySignIn-Success`, Severity 1 (done) |
| 3 | **User Administrator can't see or remove MFA methods** | The routine admin role can't do a core containment step | Make responders eligible for Authentication Administrator |
| 4 | **Synced accounts need an AD password reset** | No password writeback, so the reset went through the domain controller. Run command on the DC is itself a Tier 0 path ([2.3 finding 1](../2.3-privileged-identity-management/README.md#8-findings)) | Password writeback |
| 5 | **On-prem password change didn't reset user risk** | An admin had to dismiss risk by hand | Setting turned on (done) |
| 6 | **The first scope query missed an IP** | I typed IP prefixes by hand, and the source changed networks | Scope from the user's own risky sign-ins (query in the updated runbook) |

**What held:**
- **SMS and voice disabled:** no phone method could be registered
- **Separation of duties (2.4):** the Finance request was refused before it existed
- **CA004 block group (2.2):** an immediate cloud block, without waiting for sync
- **CA group membership alert (2.2):** fired on the containment step

## Test results

| Test | Expected | Result |
|---|---|---|
| Sign-in from an anonymizing network is detected | Anonymous IP address detection | ✅ Real-time, medium and high |
| Risky sign-in requires MFA | CA005 applies | ✅ |
| An alert fires on the compromise | Notification to the security inbox | ❌ None existed. Added `ALERT-RiskySignIn-Success` |
| A new MFA method can't be added by phone | No phone option | ✅ |
| Finance access can't be gained | Request refused | ✅ Separation of duties |
| Containment | Sessions revoked, cloud sign-in blocked, password reset | ✅ 11 minutes |
| Recovery | Account restored and risk cleared | ✅ |

## What I had at the end of 2.6

- [x] A simulated compromise detected, triaged, contained and recovered, following the 2.1 runbook
- [x] The full timeline rebuilt from logs
- [x] A new Severity 1 alert for successful risky sign-ins
- [x] On-prem password resets now clear user risk
- [x] A written [incident report](../../docs/03-incident-report-maria-lopez.md) and an updated runbook

---

**Next:** 2.7 Identity Metrics (coming next) · [← Back to the project overview](../../README.md)
