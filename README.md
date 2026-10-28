# Zero Trust IAM Lab: Conditional Access, PIM and Access Governance in Entra ID

**Status: ✅ Complete, all 8 parts.** The design was written before implementation, the same way I'd plan a change to a production tenant.

This is Project 2 of my IAM portfolio. It builds on [Project 1: Hybrid IAM Lab (JML automation)](https://github.com/jagble/hybrid-iam-jml-lab) and uses the same fictional company, **Potomac Defense Systems (PDS)**, the same Entra ID tenant and the same users.

> **About this lab:** PDS is a fictional defense and space contractor. Every person, account and piece of data is made up. The lab runs in my own Azure subscription and Entra ID tenant (Entra ID P2 trial).

---

## Why this project

Project 1 automated the identity lifecycle and then exposed four gaps. This project closes them:

| Gap found in Project 1 | How this project closes it |
|---|---|
| A terminated user's old password still worked in the cloud **79 seconds** after offboarding | Conditional Access **leaver block**: a cloud group the leaver adds people to instantly, blocked from every app |
| Admin access was **standing**: always on, even when not in use | **PIM**: admin roles become eligible, activated just in time with MFA, a reason, and approval for the most powerful roles |
| No **request and approval** process. Access was granted only by scripts and HR data | **Access packages**: users request program access, their manager and program manager approve, and access expires on its own |
| No **access certifications**. Nobody confirmed that access was still needed | **Access reviews**: managers certify their team's access every quarter, and denied access is removed automatically |

## Parts

| Part | Title | What gets built | Status |
|:---:|---|---|:---:|
| **2.1** | [Design and prep](parts/2.1-design-and-prep/README.md) | Design doc, break-glass account, trial and cost checks, logging | ✅ |
| **2.2** | [Conditional Access](parts/2.2-conditional-access/README.md) | 7 policies tested in report-only then enforced: MFA for all users, legacy auth blocked, phishing-resistant MFA for admins, leaver block, risk-based and location policies, plus alerts | ✅ |
| **2.3** | [Privileged Identity Management](parts/2.3-privileged-identity-management/README.md) | Standing GA removed. Just-in-time admin roles with approval for Global Admin, automatic expiry, activation alerts | ✅ |
| **2.4** | [Access packages](parts/2.4-access-packages/README.md) | Two-stage request and approval for program data with 90-day expiry, and Finance/AP separation of duties blocked at request time | ✅ |
| **2.5** | [Access reviews](parts/2.5-access-reviews/README.md) | Quarterly privileged role review by Security and manager reviews of program access, with denied access removed automatically | ✅ |
| **2.6** | [Incident response](parts/2.6-incident-response/README.md) | A simulated compromised account: detection, triage from the logs, containment in 11 minutes, recovery, a new alert, and a written [incident report](docs/03-incident-report-maria-lopez.md) | ✅ |
| **2.7** | [Identity metrics](parts/2.7-identity-metrics/README.md) | A one-page [metrics report](docs/04-identity-metrics-report.md): MFA coverage, standing admins, review completion, stale accounts, legacy auth | ✅ |
| **2.8** | [Non-human identities](parts/2.8-non-human-identities/README.md) | An [inventory](docs/05-nhi-inventory.md) of every app and its credentials, a planted risky app caught and deleted, an alert on new app credentials, and the metrics report running as a managed identity | ✅ |

## Results so far

| Area | Result |
|---|---|
| **Conditional Access** | **7 policies** live, each tested with What If and in report-only before it was turned on, with no gap between security defaults and Conditional Access |
| **Admin sign-in** | Admins must use **phishing-resistant MFA**. My admin account signs in with a device-bound passkey |
| **Emergency access** | Break-glass proven to bypass every policy, and its sign-ins **email an alert within one 5-minute check** |
| **Privileged access** | **No standing admin** except break-glass. Global Admin is eligible, needs approval, and **expired on its own after exactly 60 minutes**, with every step in the audit log |
| **Access requests** | An engineer's request for program data went through **two approvers** and was granted automatically, with a **90-day end date** |
| **Separation of duties** | An AP clerk's request for Finance access was **refused before any approver saw it** |
| **Access reviews** | A **decision helper flagged an over-privileged helpdesk admin**, Security denied it, and the role was removed automatically. A manager's deny ended an engineer's program access **87 days early** and removed him from the group |
| **Incident response** | A simulated compromised account was **contained in 11 minutes** and recovered. The incident showed that **passing MFA marked the risk as resolved**, so I added an alert for successful risky sign-ins |
| **Identity metrics** | **100% MFA** among users who sign in, **1 standing admin** (break-glass), **100%** access review completion. But 315 never-used accounts have no MFA yet |
| **Non-human identities** | Found an **Entra Connect app with Tier 0 rights** I didn't know existed, caught and deleted a planted app with a 2-year secret and directory-wide read, and moved the metrics report to a **managed identity with no stored credential** |
| **Tamper alerts** | Alerts on any Conditional Access policy change and any change to the exclusion or leaver block groups |
| **Findings** | 40 in total, including: no password writeback, Azure Run command on a DC VM acting as Domain Admin, access packages nobody could request until "Self" was selected, access reviews that remove nothing until the review ends, and a compromised account that showed "No risk" because MFA was satisfied. See [2.2](parts/2.2-conditional-access/README.md#11-findings), [2.3](parts/2.3-privileged-identity-management/README.md#8-findings), [2.4](parts/2.4-access-packages/README.md#8-findings), [2.5](parts/2.5-access-reviews/README.md#7-findings), [2.6](parts/2.6-incident-response/README.md#8-findings), [2.7](parts/2.7-identity-metrics/README.md#3-findings) and [2.8](parts/2.8-non-human-identities/README.md#5-findings) |

## Design

The full design is in [`docs/01-design.md`](docs/01-design.md). In short:

- **Conditional Access:** 7 policies, all named `CA0xx`, all deployed in **report-only mode first** and switched on only after checking the sign-in logs for impact. Every policy excludes the emergency access group
- **Emergency access:** one cloud-only break-glass account with permanent Global Admin, excluded from Conditional Access, protected by a long passphrase and MFA, and alerted on every sign-in
- **PIM:** no standing admin roles except break-glass. Global Admin requires approval from the Security team
- **Access governance:** program access requested through an access package, approved in two stages, expiring after 90 days, and reviewed quarterly. Finance and Accounts Payable are marked as incompatible, carrying over the SoD rule from Project 1
- **Non-human identities:** every app registration and service principal gets an owner, a certificate or managed identity instead of a secret, and only the permissions it uses
- **Incident response:** follows the runbook in [`docs/02-incident-response-runbook.md`](docs/02-incident-response-runbook.md)

## Repository

| Folder | What's in it |
|---|---|
| [`parts/`](parts/) | Step-by-step walkthroughs with screenshots, one per part |
| [`docs/`](docs/) | The design, the incident response runbook, the 2.6 incident report, the 2.7 metrics report and the 2.8 non-human identity inventory |
| [`scripts/`](scripts/) | The export and inventory scripts, the managed identity setup, and the metrics runbook |
| [`policies/`](policies/) | The Conditional Access policies as JSON |

## Environment

- **Tenant:** Microsoft Entra ID with P2 (trial), synced from on-prem Active Directory by Entra Connect (Project 1)
- **Users:** the PDS users from Project 1. Synced groups stay read-only in the cloud, so anything that has to change in the cloud (access package resources, the leaver block group) uses **cloud groups**
- **Logs:** Entra sign-in and audit logs sent to a Log Analytics workspace for KQL queries and alerting

## How I used AI

I used AI assistants (Claude and ChatGPT) as a second pair of eyes throughout this project:

- **Planning:** I talked through the design and its trade-offs with AI before building, then wrote down the decisions in the design doc
- **Drafting:** the KQL queries and PowerShell were AI-drafted. I ran them read-only first and checked every result against the portal
- **Review:** I shared screenshots as I built. That review caught a missing sync account exclusion on CA005 before the policy was enforced
- **Verification:** every setting is backed by a test I ran myself: What If simulations, report-only results on real sign-ins, enforced sign-ins, and a live alert

I configured every setting in the portal myself, and the walkthroughs include what went wrong as well as what worked.

## Skills this project covers

Conditional Access · Zero Trust · MFA and authentication strengths · Identity Protection (sign-in and user risk) · Privileged Identity Management (PIM) · just-in-time access · entitlement management (access packages) · access reviews and certifications · separation of duties · incident response · KQL · identity metrics · non-human identity governance · service principals · managed identities

---

Built by **Josh Agble** · [github.com/jagble](https://github.com/jagble)
