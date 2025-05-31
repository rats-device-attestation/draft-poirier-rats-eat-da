---
title: "An EAT Profile for Device Attestation"
abbrev: "EAT DA"
category: info

docname: draft-poirier-rats-eat-da-latest
submissiontype: independent
number:
date:
consensus: false
v: 3
area: AREA
workgroup: WG Working Group
keyword:
 - attestation
 - device assignment
 - EAT
venue:
  group: WG
  type: Working Group
  mail: WG@example.com
  arch: https://example.com/WG
  github: USER/REPO
  latest: https://example.com/LATEST

author:
 -
    fullname: Mathieu Poirier
    organization: Linaro
    email: mathieu.poirier@linaro.org
 -
    fullname: Thomas Fossati
    organization: Linaro
    email: thomas.fossati@linaro.org

normative:
  RFC9711: rats-eat

informative:

--- abstract

In confidential computing, device assignment (DA) is the method by which a device (e.g., network adapter, GPU), whether on-chip or behind a PCIe Root Port, is assigned to a Trusted Virtual Machine (TVM).
For the TVM to trust the device, the device must provide the TVM with attestation Evidence confirming its identity and the state of its firmware and configuration.

This document defines an attestation Evidence format for DA as an EAT (Entity Attestation Token) profile.

--- middle

# Introduction

In confidential computing, device assignment (DA) is the method by which a device (e.g., network adapter, GPU), whether on-chip or behind a PCIe Root Port, is assigned to a Trusted Virtual Machine (TVM).
Most confidential computing platforms (e.g., Arm CCA, AMD SEV-SNP, Intel TDX) provide DA capabilities.
Such capabilities prevent agents which are untrusted by the TVM (including other TVMs and the host hypervisor) from accessing or controlling a device that has been assigned to the TVM.
This includes, for example, protection of device MMIO interfaces and device caches.
From a trust perspective, DA allows a device to be included in the TVM's Trusted Computing Base (TCB).
For the TVM to trust the device, the device must provide the TVM with attestation Evidence confirming its identity and the state of its firmware and configuration.

This document defines an attestation Evidence format for DA as an EAT {{-rats-eat}} profile.
The format is designed to be generic, extensible and architecture agnostic.
Ongoing work on DA concentrates on PCIe devices that support the SPDM protocol, but other bus architecture and protocols are expected to be supported as the technology gains wider adoption.
As such we focus on the formalization of an Evidence format for SPDM compliant devices while leaving room for the definition of other Evidence format such as CXL and CHI.
This list is by no means exhaustive and is expected to expand.


# Conventions and Definitions

{::boilerplate bcp14-tagged}

# Device Attestation Claims

The Device Attestation claim is the encompassing envelope for the individual device claims to be presented.
It can be used as a standalone entity but typically enclosed in a wider platform specific attestation token.
The Device attestation claim consists of an EAT profile identifier, a nonce and an EAT submodule ({{Section 4.2.18 of -rats-eat}}) that contains any number of individual device claims.
Each individual device claim is the combination of a device name and a standard claims format based on the bus or protocol the device supports.
As previously mentioned, this draft defines the claims set for SPDM compliant devices while allowing room for future expansion.

~~~ cddl
{::include-fold cddl/da-token.cddl}
~~~

## SPDM Claims

A SPDM claim instance is expected to be present for each SPDM compatible device to be attested.
Each instance consists of measurements and a certificates section.
There can be up to 239 measurements per device with the entire measurement log optionally signed by the certificate populated in one of the 8 certificate slots.
It should be noted that measurements formalized herein follow the DMTF measurement specification.

~~~ cddl
{::include-fold cddl/spdm-claims.cddl}
~~~

### Measurement Claims

~~~ cddl
{::include-fold cddl/spdm-measurement.cddl}
~~~

### Certificate Claims

~~~ cddl
{::include-fold cddl/spdm-certificates.cddl}
~~~

# Collated CDDL

~~~ cddl
{::include-fold cddl/da-token-autogen.cddl}
~~~

# Security Considerations

TODO Security

# IANA Considerations

## New CWT Claims Registrations

TODO IANA CWT allocations

## New CBOR Tags Registrations

TODO IANA CBOR Tag allocations

--- back

# Examples

~~~ cbor-diag
{::include-fold cddl/examples/1.diag}
~~~

# Acknowledgments
{:numbered="false"}

TODO acknowledge.
