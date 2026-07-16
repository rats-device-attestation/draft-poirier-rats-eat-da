---
title: EAT Profile for Trustworthy Device Assignment
description: RATS WG presentation for draft-poirier-rats-eat-da — IETF 126
theme: Next
paginate: true
footer: EAT DA — RATS WG — IETF 126
autoscale: true
---

# EAT Profile for Trustworthy Device Assignment

**draft-poirier-rats-eat-da-10**

RATS WG — IETF 126

Mathieu Poirier · Henk Birkholz · Thomas Fossati

---

## Context

- Device assignement in confidential computing:
  - A device (e.g., NIC, GPU or disk) is assigned to a confidential VM

- Can we trust the device?
  - Not until the device provides Evidence about its identity and state

---

## What problem are we solving?

**Not:** invent another device attestation protocol

**Yes:** homogenize device evidence around **EAT**

- Buses speak **native** formats (SPDM, CXL, CHI, …)
- RATS Verifiers and RPs speak **EAT**
- **DAT = translation layer** from native artefacts → standardized EAT claims

Parallel work: Linux kernel ABI for retrieving device evidence

<!--
core framing: no new protocol, claims translation / convergence only
analogy: many data links, one convergence layer (like IP)
mention kernel ABI briefly — implementation momentum
-->

---

## Why not wait for native EAT devices?

In the same server you may have:

- a device that could speak EAT natively
- an older SPDM device that cannot
- legacy PCIe hardware with no SPDM at all
- buses whose EAT convergence is unclear


IETF cannot dictate what DMTF, PCI-SIG, or others standardize
We **can** define how their outputs converge into RATS Evidence

<!--
heterogeneity is going to be permanent, not transitional
-->

---

## System model

[.column]

- Confidential **TVM** with assigned device(s) in its **TCB**
- **Lead Attester** inside TVM (measured in platform Evidence)
- Appraised object: **composite Evidence**, not devices in isolation
- External **Verifier / RP** consumes standardized EAT

Lead Attester can be:

1. **Forwarder** — translate native artefacts, pass through
2. **Lightweight internal Verifier** — verify (identity) locally, repackage claims

[.column]

```
      .---------------.
     | Verifier / RP   |
      '---------------'
              ^
  .-----------+------------------------------------.
 |            |                                     |
 |  Attester  |                .-----------------.  |
 |            |              .-+---------------. |  |
 |  .---------+---------.  .-+---------------. | |  |
 |  | TVM     |         |  | Assigned Device | | |  |
 |  |         v         |  |                 | | |  |
 |  | .---------------. |  |                 | | |  |
 |  | | Lead Attester | |  |                 | | |  |
 |  | '---------------' |  |                 | | |  |
 |  |     ^       ^     |  |                 | | |  |
 |  |     |       |     |  |                 | | |  |
 |  |     v       v     |  | .-------------. | | |  |
 |  | .---+-------+---. |  | | Device      | | | |  |
 |  | | Guest Kernel  | |  | | Attester    | | | |  |
 |  | '---------------' |  | '-------------' | +-'  |
 |  |     ^       ^     |  |     ^           +-'    |
 |  '-----|-------|-----'  '-----|-----------'      |
 |        |       |              |                  |
 |  .-----|-------|-----.  .-----|---------------.  |
 |  |     |       |     |  | .---|-------------. |  |
 |  |     v        '---------+--'  Host Kernel | |  |
 |  | .---------------. |  | '-----------------' |  |
 |  | | Platform      | |  |                     |  |
 |  | | Attester      | |  |                     |  |
 |  | '---------------' |  |                     |  |
 |  |                   |  |                     |  |
 |  | Confidential      |  | Untrusted           |  |
 |  | Platform          |  | Platform            |  |
 |  '-------------------'  '---------------------'  |
 |                                                  |
  '------------------------------------------------'
```

<!--
walk Figure 1 verbally
stress composite appraisal and that the lead attester is part of the measured TCB
-->

---

## DAT: an EAT envelope for devices

**Device Assignment Token** = EAT profile for device claims

```
dat = {
  eat_profile  => "tag:linaro.org,2025:device#1.0.0"
  eat_nonce    => bytes
  eat_submods  => { + "namespace:name" => $device-claims-set }
}
```

- Extensible claims-sets: **SPDM** today, **PCIe legacy**, other/future buses (§5)
- `eat_profile` in each submod carries bus/version semantics
- Standalone token or embedded in larger composite Evidence

<!--
this is the envelope, not the bus protocol
the profile claims select semantics when bus versions evolve
-->

---

## Composite Evidence

From draft Appendix B: [Figure 2](https://www.ietf.org/archive/id/draft-poirier-rats-eat-da-10.html#figure-2)

```
                signed-cbor-cmw
               .---------------------.
               |  .---------------.  |
         .------->| Lead Attester |  |
         |     |  | Evidence      |  |
         |     |  '---------------'  |
         |     |                     |
         |     |  .---------------.  |
 nonce --+------->| Platform      |  |
         |     |  | Evidence      |  |  .----------------------------.
         |     |  '---------------'  |  | eat_profile                |
         |     |                     |  | eat_nonce                  |
         |     |  .---------------.  |  | submod {                   |
         '------->| DAT           +- - -+   "spdm:A": { ... }        |
               |  '---------------'  |  |   "legacy-pcie:B": { ... } |
               '---------------------'  |   "spdm:C": { ... }        |
                                        | }                          |
                                        '----------------------------'
```

**One composite message. One appraisal. Many native bus formats underneath.**

<!--
1. challenger nonce goes to lead attester
2. lead attester collects platform + device artefacts (via guest-kernel ABI)
3. lead attester translates native outputs into DAT submods
4. lead attester assembles signed CMW collection
5. verifier gets one EAT-native package

some key points:
- outer eat_nonce = challenger freshness (not bus nonces)
- submod names are the CoRIM binding hook
- reference impl: veraison ratsd
-->

---

## Claims translation framework

| Native world | DAT / EAT world |
|---|---|
| SPDM measurements, certs, challenge, TDISP | registered EAT claims |
| PCIe legacy config space | `pcie-legacy` claims-set |
| Future CXL, CHI, … | new claims-set + naming rules (§5) |

To translate, you must understand what the bus said — but the **Verifier should not have to**

Measurement component types = **syntactic expressiveness**, not new semantics

<!--
framework is the value prop, not just SPDM wrapping
§5 gives extension blueprint
-->

---

## Spare the Verifier

**Most Verifiers need:** device identity + state in EAT form

**Optional for advanced Verifiers:** full bus protocol artefacts (challenge transcripts, VCA, TDISP report, ...)

Result: one appraisal pipeline for platform **and** devices

<!--
reduce complexity on the verifier / RP side
policy stays with Verifier
-->

---

## `submod` naming → CoRIM

Evidence-to-reference-state linkage:

- `spdm:ACME:WIDGET:0123456789` — from leaf certificate SAN

Receiver can derive a **CoRIM environment** from the name,
then look up matching **Reference Values / Endorsements**

<!--
this is prolly the main value beyond syntax conversion
CoRIM profile is separate but anticipated
-->

---

## Hybrid verification

Same DAT framework serves:

- **Evidence** (forwarded, translated artefacts)
- **"raw" Attestation Results** (locally verified claims)

When Lead Attester verifies internally → hybrid output;
not fully EAR-ifiable today

<!--
important to clarify for those who expect clean Evidence/Results separation
(one of Ionut's review points)
CMW `ind` field could refine message type where needed
-->

---

## What is standardized

**Framework:** the outer wrapper + extension rules (§5) - `$device-claims-set`, naming convention, IANA registrations)

**SPDM:** measurements, certificates, challenge, TDISP report, optional VCA

**PCIe legacy:** minimal config-space claims for non-SPDM devices


**Out of scope now:** live migration; on-chip SPDM

Framework evolves with bus technology **and** protocol versions via `eat_profile`

<!--
v1 is framework + two claims-sets, not exhaustive bus coverage
-->

---

## Ecosystem placement

| Piece | Role |
|---|---|
| **EAT** (RFC 9711) | claim model, submods, profiles |
| **DAT** | device evidence translation + aggregation |
| **CMW** (RFC 9999) | composite collection wrapping |
| **CoRIM** (profile TBD) | reference state for named environments |

> DAT = RFC 9334 composite Attesters + RFC 9711 submods, made explicit

<!--
redundancy check: DA is not a parallel architecture
makes concrete use of the RATS toolbox
-->

---

## Quick Recap 

1. Deployments are **heterogeneous** and will remain so
1. DAT cater for device assignment via a stable **EAT-based convergence layer**
1. Explicit `submod` naming rules to enable **CoRIM-linked appraisal**
1. The framework is **extensible** without reopening the core model

---

## :rat: Adopt me? :rat:

---

## Kudos to the reviewers!

Giri, Carl, Ionuț, Yogesh, MCR, Ned
