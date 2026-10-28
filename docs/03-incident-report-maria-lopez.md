# Incident Report: Compromised Account, Maria Lopez (Accounts Payable)

> **About this report:** Potomac Defense Systems is a fictional company. This incident was a planned simulation in a lab tenant (part 2.6), written up as a real report would be.

| | |
|---|---|
| **Incident** | Compromised user account |
| **Account** | Maria Lopez, Accounts Payable Clerk (synced from AD) |
| **Severity** | High: a user with payment-related access |
| **Status** | Closed |
| **Responder** | Josh Agble (IAM) |
| **Walkthrough** | [Part 2.6](../parts/2.6-incident-response/README.md) |

## Summary

On Oct 26, Maria Lopez's account was signed in to from an anonymizing network using her password, and an MFA prompt was approved. Identity Protection detected the sign-ins in real time, but marked the risk as remediated once MFA was satisfied, and no alert was configured for this case. Over about 2 hours 20 minutes, the account was used to view security info and to request Finance Systems Access, which separation-of-duties rules refused. No changes were made and no access was gained. The account was contained on Oct 27 in 11 minutes and recovered on Oct 28. A new alert closes the detection gap.

## Timeline (EDT)

| Time | Event | Source |
|---|---|---|
| **Oct 26** 2:26 PM | 3 failed sign-ins (wrong password) from an anonymizing IP | SigninLogs |
| 2:29 PM | Successful sign-in. Sign-in risk high, MFA required by CA005 and satisfied | SigninLogs, risky sign-ins |
| 2:32 PM | Security info page opened. No method added | SigninLogs, auth methods |
| 2:34 PM | User risk automatically dismissed | Risky user history |
| 4:08–4:46 PM | Repeated Entitlement Management sign-ins. Finance Systems Access request refused (separation of duties) | SigninLogs, My Access |
| 4:46 PM | Last sign-in from a flagged IP | SigninLogs |
| **Oct 27** afternoon | Triage: timeline rebuilt, scope confirmed as one user | KQL |
| 4:44 PM | Sessions revoked | AuditLogs |
| 4:45 PM | Added to `CA-Block-Leavers` (cloud sign-in blocked) | AuditLogs |
| 4:47 PM | User confirmed compromised (risk: High) | AuditLogs |
| 4:53 PM | CA group membership alert fired on the containment step | Alert email |
| 4:55 PM | Password reset in AD to a random value | Run command output |
| **Oct 28** 10:06 AM | `ALERT-RiskySignIn-Success` created | Azure Monitor |
| 10:16 AM | User risk dismissed after a new password was issued out of band | AuditLogs |
| 10:18 AM | Removed from `CA-Block-Leavers` | AuditLogs |
| ~10:28 AM | User signs in normally | Sign-in |

## Detection

- **Detected by:** Identity Protection, "Anonymous IP address," real time, medium and high
- **Alerted:** no. Detections were auto-remediated by MFA, and no alert covered successful risky sign-ins
- **Found by:** manual review of Risky sign-ins

## Scope and impact

- **Accounts affected:** 1. 175 sign-ins from 6 IPs, all against this user
- **Changes made:** none (no audit events initiated by the account)
- **MFA persistence:** none. No new method registered; SMS and voice are disabled tenant-wide
- **Access gained:** none. The Finance Systems Access request was refused by the incompatible-group rule (`GG-Role-AccountsPayable`)
- **Data accessed:** the user's own profile and security info pages, and the access package catalog

## Root cause

- Password assumed phished
- MFA approved by the user for a prompt she didn't start. Push-based MFA can be talked or tricked through; phishing-resistant MFA cannot

## Containment and recovery

Followed the runbook: revoke sessions → block via `CA-Block-Leavers` → confirm compromised → reset the password in AD (synced account, no writeback) → verify the user out of band → issue a new password → dismiss risk → unblock → confirm a normal sign-in.

## What worked

- CA005 required MFA on the risky sign-in
- SMS and voice disabled: no easy way to add an MFA method
- Separation of duties refused Finance access at request time
- `CA-Block-Leavers` gave an immediate cloud block
- The CA group membership alert reported the containment change

## Follow-up actions

| # | Action | Status |
|---|---|---|
| 1 | Alert on successful medium or high risk sign-ins (`ALERT-RiskySignIn-Success`, Sev 1) | ✅ Done |
| 2 | Allow on-prem password changes to reset user risk | ✅ Done |
| 3 | Update the runbook: roles, scope query, synced-account reset, auto-remediation | ✅ Done |
| 4 | Make responders eligible for Authentication Administrator | Open |
| 5 | Require phishing-resistant MFA for finance and AP roles | Open |
| 6 | Enable password writeback so synced users can be reset from the cloud | Open |
