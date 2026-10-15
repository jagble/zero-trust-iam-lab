# Runbook: Suspected Compromised Account

> **Summary:** What to do, in order, when an Entra ID account is suspected of being compromised. Written before the part 2.6 simulation, which will test it.

> **About this lab:** Potomac Defense Systems is a fictional company. All people and data are made up.

**Triggers:** an Identity Protection risk detection (for example, sign-in from an anonymous IP), a user reporting MFA prompts they didn't start, or a SIEM alert.

## 1. Triage (first 15 minutes)

1. Open the user in **Identity Protection → Risky users** and **Risky sign-ins**. Note the detection type, time, IP address, location and app
2. Check the **sign-in logs** for the user: successful sign-ins from the same IP or location? Was MFA satisfied, or did the sign-in fail at MFA?
3. Contact the user **out of band** (phone, not email or Teams, which the attacker may control): did they sign in from there?
4. **Decide:** confirmed compromise, false positive, or unknown. Treat unknown as compromised

## 2. Contain (cut access first)

Same principle as the Project 1 leaver: cut access before investigating further.

1. **Revoke sessions** (Entra → user → Revoke sessions, or Graph `revokeSignInSessions`)
2. **Reset the password.** If the account is synced, reset it in AD so it doesn't get overwritten by the next sync
3. **Block sign-in** if the compromise is confirmed and the user is not reachable (add to `CA-Block-Leavers` for an immediate cloud block)
4. **Confirm compromised** in Identity Protection, which raises user risk to high and triggers CA006 on the next sign-in

## 3. Investigate

1. **Authentication methods:** did the attacker register a new MFA method? Remove anything the user doesn't recognize
2. **Audit logs:** changes made by or to the user since the first suspicious sign-in (group memberships, app consents, role activations)
3. **App consents:** any new enterprise app permissions granted by the user
4. **Scope:** same IP or pattern against any other users? Run the saved KQL query across all sign-ins

## 4. Recover

1. User re-registers MFA in person or through a verified process, then signs in with the new password
2. Dismiss the user risk **only after** the password reset and MFA re-registration
3. Remove the user from `CA-Block-Leavers` if they were added

## 5. Report

Write an incident report with:
- **Timeline:** detection, triage, containment, recovery, each with a timestamp
- **What happened** and how it was detected
- **Impact:** what the attacker could access, and whether they did
- **Root cause** (how the credential was likely obtained)
- **Lessons learned and follow-up actions** (policy changes, user training)
