# Zero Trust IAM Lab: Conditional Access, PIM and Access Governance in Entra ID

**Status: 🚧 In progress, 2 of 8 parts complete.** Parts are checked off as they ship. The design was written before implementation, the same way I'd plan a change to a production tenant.

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
| **2.1** | [Design and prep](parts/2.1-design-and-prep/README.md) | Design doc, break-glass account, trial and cost checks, logging | ✅ Done |
| **2.2** | [Conditional Access](parts/2.2-conditional-access/README.md) | 7 policies tested in report-only then enforced: MFA for all users, legacy auth blocked, phishing-resistant MFA for admins, leaver block, risk-based and location policies, plus alerts | ✅ Done |
| **2.3** | Privileged Identity Management | Just-in-time admin roles, approval for Global Admin, PIM alerts | Planned |
| **2.4** | Access packages | Request and approval workflow for program access, with expiration and separation-of-duties checks | Planned |
| **2.5** | Access reviews | Quarterly manager certifications and a privileged role review | Planned |
| **2.6** | Incident response | A simulated compromised account: detection, containment and a written incident report | Planned |
| **2.7** | Identity metrics | One-page report: MFA coverage, standing admins, review completion, stale accounts | Planned |
| **2.8** | Non-human identity review | Inventory of app registrations and service principals, risky credentials and permissions, a managed identity, app access review | Planned |

## Results so far

| Area | Result |
|---|---|
| **Conditional Access** | **7 policies** live, each tested with What If and in report-only before it was turned on, with no gap between security defaults and Conditional Access |
| **Admin sign-in** | Admins must use **phishing-resistant MFA**. My admin account signs in with a device-bound passkey |
| **Emergency access** | Break-glass proven to bypass every policy, and its sign-ins **email an alert within one 5-minute check** |
| **Tamper alerts** | Alerts on any Conditional Access policy change and any change to the exclusion or leaver block groups |
| **Findings** | 5, including no password writeback (high-risk synced users get blocked instead of resetting) and a missing sync exclusion caught before enforcement. [See 2.2](parts/2.2-conditional-access/README.md#11-findings) |

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
| [`docs/`](docs/) | The design and the incident response runbook |
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
