# Part 2.4: Access Packages

[← 2.3 Privileged Identity Management](../2.3-privileged-identity-management/README.md) · **2.4** · 2.5 Access Reviews (next)

> **In this part:** I built a request-and-approval process for program data. Engineers ask for access, their manager and the program manager approve it, and it ends after 90 days. I also brought back the Project 1 separation-of-duties rule (no one holds both Finance and Accounts Payable), but this time the conflict is blocked **when the request is made**, not found by a script afterward.
>
> **Design:** [`docs/01-design.md` section 6](../../docs/01-design.md#6-access-packages-entitlement-management)

| # | Section | The lesson |
|---|---|---|
| 1 | [Birthright vs. requested access](#1-birthright-vs-requested-access) | Two kinds of access, two processes |
| 2 | [Groups and the catalog](#2-groups-and-the-catalog) | Cloud groups, because entitlement management has to write to them |
| 3 | [The Radar package](#3-the-radar-package) | Two approval stages, a CUI attestation, 90 days |
| 4 | [Finance, Payables and separation of duties](#4-finance-payables-and-separation-of-duties) | Block the conflict before anyone approves it |
| 5 | [Getting ready to test](#5-getting-ready-to-test) | Licenses moved, and nobody could request at first |
| 6 | [Test 1: Chris requests Radar](#6-test-1-chris-requests-radar) | Request → manager → program manager → access |
| 7 | [Test 2: Maria is blocked](#7-test-2-maria-is-blocked) | Separation of duties at request time |
| 8 | [Findings](#8-findings) | |

---

## 1. Birthright vs. requested access

| | Birthright (Project 1) | Requested (Project 2) |
|---|---|---|
| Example | `GG-Role-Radar-Engineers`, from the HR Program attribute | `AP-Radar-Program-Data`, through an access package |
| Granted by | The JML engine, from HR data | Two approvers |
| Ends | When the job changes | After 90 days, unless extended and approved again |
| Who it's for | Engineers assigned to Radar | Everyone else who needs it for a task |

Chris Douglas is an engineer with **no program**. If he needs to help the Radar team, he shouldn't be moved into Radar in HR, and he shouldn't be added to a group by hand. He should ask, get approved, and lose the access when the task is done.

## 2. Groups and the catalog

![The five AP- groups](images/2.4-01-ap-groups.png)

Five **cloud** security groups: three for program data, plus `AP-Finance-Systems` and `AP-Payables-Systems`. Synced AD groups are read-only in Entra, and entitlement management has to add and remove members itself, so these have to be cloud groups. (I used `Payables`, not "AccountsPayable," because `AP-` already means "access package.")

![The PDS Programs catalog](images/2.4-02-catalog.png)

![All five groups in the catalog](images/2.4-03-catalog-resources.png)

The **catalog** sets the outer limit: a package can only hand out what's in its catalog.

## 3. The Radar package

| Setting | Value | Why |
|---|---|---|
| Who can request | **Self** and **Manager**, for members of `GG-Role-Engineers` | Engineers only. Finance and HR staff never see it |
| Stage 1 | The requester's **manager** (fallback: Monica Hayes) | Does this person need it for their job? |
| Stage 2 | **Tom Haskins**, Radar program manager | Is it appropriate for the program? |
| Justification | Required from the requester and both approvers | Every decision has a reason on record |
| Questions | Which Radar task? · CUI training in the past 12 months? (Yes/No) | The Project 1 training check, as an attestation |
| Expiry | **90 days**. Extensions go through both stages again | Access has an end date |

![Two approval stages](images/2.4-04-radar-approval-stages.png)

![Who can request: Self, Manager, GG-Role-Engineers](images/2.4-05-radar-who-can-request.png)

![Requestor questions](images/2.4-06-radar-questions.png)

![Yes and No answers for the CUI question](images/2.4-07-cui-answer-options.png)

![Lifecycle: 90 days, extensions need approval](images/2.4-08-radar-lifecycle.png)

![Radar Program Access created](images/2.4-09-radar-created.png)

**A gap I'm aware of:** a "No" on the CUI question doesn't block the request automatically. Approvers see the answer and are expected to deny it. The attestation relies on approvers reading it.

**Satellite** and **Shipboard** use the same settings, with Elena Vasquez and Gregory Okafor as the stage 2 program managers.

![Satellite Program Access](images/2.4-10-satellite-created.png)

![Shipboard Program Access](images/2.4-11-shipboard-created.png)

## 4. Finance, Payables and separation of duties

**The Project 1 rule:** no one holds both Finance and Accounts Payable access, because one person could create a vendor and also pay it. In Project 1 a script found conflicts after they existed. Here, Entra refuses the request.

Both packages have one approval stage (the manager) and a 90-day expiry. Both can be requested by members of **either** `GG-Role-Finance` or `GG-Role-AccountsPayable`. If only Finance staff could see the Finance package, AP staff could never try, and the rule would never be tested.

Each package has two conflict rules:

| Package | Incompatible package | Incompatible group |
|---|---|---|
| Finance Systems Access | Payables Systems Access | `GG-Role-AccountsPayable` |
| Payables Systems Access | Finance Systems Access | `GG-Role-Finance` |

![Finance: incompatible with the Payables package](images/2.4-12-finance-sod-packages.png)

![Finance: incompatible with the AP group](images/2.4-13-finance-sod-groups.png)

![Payables: incompatible with the Finance package](images/2.4-14-payables-sod-packages.png)

![Payables: incompatible with the Finance group](images/2.4-15-payables-sod-groups.png)

- **Package vs. package** stops someone who *requested* one from getting the other
- **Package vs. group** stops someone who has the other access **from HR** (birthright) from requesting it. That's the case the test covers

## 5. Getting ready to test

**Licenses have moved.** Priya Raman (Chris's manager) needed an Entra ID P2 license to approve. In the Entra admin center, the user's Licenses page now only links to the M365 admin center. M365 then said I didn't have permission, even with Global Admin active, because it took several minutes to pick up a role activated through PIM. After a fresh sign-in, it worked.

![Entra: license changes only in M365](images/2.4-16-entra-license-redirect.png)

![M365: no permission yet, despite an active GA](images/2.4-17-m365-no-permission.png)

![Priya licensed](images/2.4-18-priya-licensed.png)

**Nobody could request anything at first.** Chris signed in and saw no packages. Newer versions of Entra have a **"Who can request access"** setting (Self, Manager, Admin), and **Self** wasn't ticked, so the policies didn't let anyone ask for themselves. I fixed it on all five packages. Testing as the actual end user caught this. Looking at it from the admin side, everything appeared correct.

## 6. Test 1: Chris requests Radar

![Chris sees only the three program packages](images/2.4-19-chris-sees-program-packages.png)

Chris sees the three program packages and **not** Finance or Payables, because he isn't in either finance group.

![Chris's request, with both answers](images/2.4-20-chris-request-form.png)

![Priya sees his answers before approving](images/2.4-21-priya-approval.png)

![Tom sees stage 1 approved by Priya](images/2.4-22-tom-approval-history.png)

![Chris added to AP-Radar-Program-Data automatically](images/2.4-23-chris-in-radar-group.png)

| Step | Who | Time |
|---|---|---|
| Request submitted | Chris | 2:00 PM |
| Stage 1 approved | Priya (manager) | 2:43 PM |
| Stage 2 approved | Tom (Radar PM) | ~2:45 PM |
| Added to the group | Entitlement management | Within a minute |

Nobody added Chris to the group by hand, and his access **ends in 90 days**.

## 7. Test 2: Maria is blocked

Maria Lopez is an AP clerk, so she's in `GG-Role-AccountsPayable` through HR (Project 1).

![Maria can see both finance packages](images/2.4-24-maria-available.png)

![Finance refused: incompatible group membership GG-Role-AccountsPayable](images/2.4-25-maria-sod-blocked.png)

The request was refused **before it existed**, so there was nothing to approve. The message names the conflicting group, so Maria knows why.

## 8. Findings

| # | Finding | Impact | Fix |
|---|---|---|---|
| 1 | **"Self" wasn't selected as a requester type** | Nobody could request any package | Select Self (and Manager) on every policy. Test as an end user before calling it done |
| 2 | **License assignment only works in M365** | The Entra page can show licenses but not change them | Use the M365 admin center, or group-based licensing |
| 3 | **M365 was slow to pick up a PIM role** | "No permission" despite an active GA | Sign in fresh, and allow a few minutes after activating |
| 4 | **The CUI attestation isn't enforced** | A "No" answer still reaches approvers | Approver training, or a custom extension that auto-denies |
| 5 | **Approvers need licenses and a way to sign in** | Priya needed a license, a password reset in AD, and MFA registration before she could approve | License approvers up front. Password writeback (see 2.3) |

## Test results

| Test | Expected | Result |
|---|---|---|
| Chris sees program packages only | Radar, Satellite, Shipboard. No Finance or Payables | ✅ |
| Chris requests Radar | Goes to his manager | ✅ |
| Stage 1 then stage 2 | Priya, then Tom, each with a reason | ✅ |
| Access granted | Chris added to `AP-Radar-Program-Data` with a 90-day end date | ✅ |
| Maria requests Finance | Refused for incompatible group membership | ✅ |

## What I had at the end of 2.4

- [x] A catalog with five cloud groups
- [x] Three program packages: two-stage approval, CUI attestation, 90-day expiry
- [x] Two finance packages with separation-of-duties rules in both directions, covering birthright groups too
- [x] An end-to-end request and approval, and a refused conflicting request

---

**Next:** 2.5 Access Reviews (coming next) · [← Back to the project overview](../../README.md)
