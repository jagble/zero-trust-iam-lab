# Zero Trust IAM Lab: Conditional Access, PIM and Access Governance in Entra ID

Parts are checked off as they ship. The design below was written before implementation, the same way I'd plan a change to a production tenant.

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
| **2.1** | Design and prep | Design doc, break-glass account, trial and cost checks, logging | 🚧 In progress |
| **2.2** | Conditional Access | MFA for all users, legacy auth blocked, phishing-resistant MFA for admins, leaver block, risk-based policies | Planned |
| **2.3** | Privileged Identity Management | Just-in-time admin roles, approval for Global Admin, PIM alerts | Planned |
| **2.4** | Access packages | Request and approval workflow for program access, with expiration and separation-of-duties checks | Planned |
| **2.5** | Access reviews | Quarterly manager certifications and a privileged role review | Planned |
| **2.6** | Incident response | A simulated compromised account: detection, containment and a written incident report | Planned |
| **2.7** | Identity metrics | One-page report: MFA coverage, standing admins, review completion, stale accounts | Planned |

## Design

The full design is in [`docs/01-design.md`](docs/01-design.md). In short:

- **Conditional Access:** 7 policies, all named `CA0xx`, all deployed in **report-only mode first** and switched on only after checking the sign-in logs for impact. Every policy excludes the emergency access group
- **Emergency access:** one cloud-only break-glass account with permanent Global Admin, excluded from Conditional Access, protected by a long passphrase and MFA, and alerted on every sign-in
- **PIM:** no standing admin roles except break-glass. Global Admin requires approval from the Security team
- **Access governance:** program access requested through an access package, approved in two stages, expiring after 90 days, and reviewed quarterly. Finance and Accounts Payable are marked as incompatible, carrying over the SoD rule from Project 1
- **Incident response:** follows the runbook in [`docs/02-incident-response-runbook.md`](docs/02-incident-response-runbook.md)

## Environment

- **Tenant:** Microsoft Entra ID with P2 (trial), synced from on-prem Active Directory by Entra Connect (Project 1)
- **Users:** the PDS users from Project 1. Synced groups stay read-only in the cloud, so anything that has to change in the cloud (access package resources, the leaver block group) uses **cloud groups**
- **Logs:** Entra sign-in and audit logs sent to a Log Analytics workspace for KQL queries and alerting

## Skills this project covers

Conditional Access · Zero Trust · MFA and authentication strengths · Identity Protection (sign-in and user risk) · Privileged Identity Management (PIM) · just-in-time access · entitlement management (access packages) · access reviews and certifications · separation of duties · incident response · KQL · identity metrics

---

Built by **Josh Agble** · [github.com/jagble](https://github.com/jagble)
