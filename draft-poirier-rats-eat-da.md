---
title: "An EAT Profile for Trustworthy Device Assignment"
abbrev: "EAT DA"
category: info

docname: draft-poirier-rats-eat-da-latest
submissiontype: independent
number:
date:
consensus: false
v: 3
area: "Security"
workgroup: "Remote ATtestation ProcedureS"
keyword:
 - attestation
 - device assignment
 - EAT
venue:
  group: "Remote ATtestation ProcedureS"
  type: "Working Group"
  mail: "rats@ietf.org"
  arch: "https://mailarchive.ietf.org/arch/browse/rats/"
  github: "rats-device-attestation/draft-poirier-rats-eat-da"
  latest: "https://rats-device-attestation.github.io/draft-poirier-rats-eat-da/draft-poirier-rats-eat-da.html"

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
  RFC5280: pkix
  RFC4514: dn-string-rep
  IANA.cwt:

informative:
  SPDM:
    -: spdm
    target: https://www.dmtf.org/sites/default/files/standards/documents/DSP0274_1.3.2.pdf
    author:
    - org: DMTF
    title: "Security Protocol and Data Model (SPDM) Specification Version: 1.3.2"
    date: 2024-08-21

entity:
  SELF: "RFCthis"

--- abstract

In confidential computing, device assignment (DA) is the method by which physical devices (components, such as NICs or GPUs), whether on-chip or behind a PCIe Root Port, are assigned to a Trusted Virtual Machine (TVM).
For the TVM to trust an assigned device, the device must provide the TVM with attestation Evidence confirming its identity, the state of its firmware and configuration -- thereby demonstrating its trustworthiness.

Since Evidence claims can be appraised by 3rd party Verifiers external to the TVM, there is a need to standardize the representation of DA in Evidence to ensure interoperability.
To represent trustworthy DA in Evidence, this document uses the EAT (Entity Attestation Token) framework to define a DA Token and specifies an EAT profile to express technology-specific device claims sets in corresponding sub-modules.

--- middle

# Introduction

In confidential computing, device assignment (DA) is the method by which physical devices (components, such as NICs or GPUs), whether on-chip or behind a PCIe Root Port, are assigned to a Trusted Virtual Machine (TVM).
Most confidential computing platforms (e.g., Arm CCA, AMD SEV-SNP, Intel TDX) provide DA capabilities.
Such capabilities prevent execution environments or software components that are untrusted by the TVM (including other TVMs and the host hypervisor) from accessing or controlling a device that has been assigned to the TVM.
This includes, for example, protection of device MMIO interfaces and device caches.
From a trust perspective, DA allows a device to be included in the TVM's Trusted Computing Base (TCB).
For the TVM to trust the device, the device must provide the TVM with attestation Evidence confirming its identity, the state of its firmware and configuration -- thereby demonstrating its trustworthiness.

To represent trustworthy DA in Evidence, this document uses the EAT framework {{-rats-eat}} to define a DA Token and specifies an EAT profile to express technology-specific device claims sets in corresponding sub-modules.
The EAT framwork is designed to be generic, extensible, and architecture agnostic.
Ongoing work on DA focuses on PCIe devices that support the SPDM protocol {{-spdm}}, but other bus architectures and protocols are expected to be supported as the technology gains wider adoption.
As such, this document focuses on the formalization of a device claims set for SPDM compliant devices while leaving room for the definition of further sub-modules for other DA contexts, such as the Compute Express Link (CXL) or the Coherent Hub Interface (CHI).
The device claims specified in this document are not intended to be exhaustive and expected to expand.


# Conventions and Definitions

{::boilerplate bcp14-tagged}

# Device Assignment Token and Device Claims

The Device Assignment Token (DAT) is an EAT that acts as the encompassing envelope for the individual device claims set to be presented.
A DAT can be used as a standalone entity but can also be embedded in a larger, platform-specific EAT using the `da-token` claim.
A DAT consists of an EAT profile identifier, a nonce and an EAT submodule ({{Section 4.2.18 of -rats-eat}}) that contains any number of individual device claims.
Each individual device claim is the combination of a device name and a standard claims format based on the bus or protocol the device supports.
The syntax of the device name depends on the type of bus or protocol used.
Each name consists of two parts joined by a semicolon: a namespace and a bus-specific name.
See {{spdm-submod-name}} for SPDM devices, and {{pcie-legacy-submod-name}} for legacy PCIe devices.
As previously mentioned, this draft currently defines the claims set for SPDM compliant devices and PCIe legacy devices that do not support the SPDM protocol.
Careful condideration was also given to the overall design in order to leave room for future expansion.

~~~ cddl
{::include-fold cddl/da-token.cddl}
~~~

## SPDM Claims

A SPDM claim instance is expected to be present for each SPDM compatible device to be attested.
Each instance consists of either a measurements section or a certificates section, or both.
Optionally, the Negotiated State preamble (version, capabilities and algorithms) bytes can be included to present the full negotiated state between the SPDM requester and responder.

~~~ cddl
{::include-fold cddl/spdm-claims.cddl}
~~~

### Measurements Claim {#spdm-measurements}

There can be up to 239 measurements per device with the entire measurement log optionally signed by the certificate populated in one of the 8 certificate slots.
It should be noted that measurements formalized herein follow the DMTF measurement specification.

~~~ cddl
{::include-fold cddl/spdm-measurements.cddl}
~~~

#### Measurement

SPDM measurements start with a component type that reflects one of the 10 categories defined by the SPDM specification.
Following is the measurement itself represented by either a raw bitstream or a digest.
The size of the digest value is derived from the measurement hash algorithm conveyed by the SPDM ALGORITHMS message response.

~~~ cddl
{::include-fold cddl/spdm-measurement.cddl}
~~~

#### Measurements Signature

SPDM compliant devices can optionally support the capability to sign measurements.
Included in the measurement claim signature are all the elements needed by a third party entity to reconstruct the original measurement log signed by the device.
Those elements include L1 (see CDDL below), the combined SPDM prefix, the hash algorithm used to generate a digest of the measurement log and nonces provided by the requester and responder.
The slot number of the leaf certificate used to sign the measurement log is also provided.

~~~ cddl
{::include-fold cddl/spdm-measurement-blocks-signature.cddl}
~~~

### Certificate Claims {#spdm-certificates}

According to the specification, SPDM compliant devices should support at most 8 slots, with slot 0 populated by default.
Slot 0 SHALL contain a certificate chain that follows the Device certificate model or the Alias certificate model.
Regardless of the certificate model used, a certificate chain comprises one or more DER-encoded X.509 v3 certificates {{-pkix}}.
The certificates MUST be concatenated with no intermediate padding.

~~~ cddl
{::include-fold cddl/spdm-certificates.cddl}
~~~

### Negotiated State Preamble (Version, Capabilities and Algorithms) {#spdm-vca}

The Negotiated State Preamble (i.e., `vca`) claim contains the concatenation of messages GET_VERSION, VERSION, GET_CAPABILITIES, CAPABILITIES, NEGOTIATE_ALGORITHMS, and ALGORITHMS last exchanged between the SPDM Requester and Responder.

### Submodule Naming {#spdm-submod-name}

The namespace used for SPDM submodules is "spdm".

The name associated with an SPDM submodule is extracted from the leaf certificate of the relevant device.

* If the leaf certificate contains a Subject Alternative Name of type DMTFOtherName, the submodule name is the value contained in `ub-DMTF-device-info`.
For example: "spdm:ACME:WIDGET:0123456789".
* Otherwise, the submod name is the string representation of the certificate Subject, as described in {{-dn-string-rep}}.
For example: "spdm:C=CA,O=ACME,OU=Widget,CN=0123456789".

## PCIe Legacy Device Claims {#pcie-legacy-device}

The definition of a device claims set for PCIe legacy devices that do not implement the extensions needed to attest for their provenance and configuration is provided, making it is possible to keep using current assets as secures ones are being provisioned.
This legacy device claims set simply mirrors the type 0/1 common registers of the PCIe configuration space, mandating only that the vendor and device identification code be provided.
Other fields of the configuration space header may optionally be included should they add value.
A binary format of the PCIe configuration space is made available for processing by existing PCIe configuration space tools.
Implementers may optionally choose to include both text and binary versions should there be a use case to support this representation.

~~~ cddl
{::include-fold cddl/pcie-legacy-claims.cddl}
~~~

### Submodule Naming {#pcie-legacy-submod-name}

The namespace used for legacy PCIe submodules is "legacy-pcie".

The name is any arbitrary string chosen by the implementation.
For example, "legacy-pcie:0000:01:02.0" where "0000" is the domain, "01" the PCI bus id, "02" the device on the bus and "0" the device function.


# Collated CDDL

~~~ cddl
{::include-fold cddl/da-token-autogen.cddl}
~~~

# Security Considerations

TODO Security

# IANA Considerations

## New CWT Claims Registrations

IANA is requested to register the following claims in the "CBOR Web Token (CWT) Claims" registry {{IANA.cwt}}.

### SPDM Measurements Claim

* Claim Name: spdm-measurements
* Claim Description: SPDM Measurements
* JWT Claim Name: N/A
* Claim Key: 3802
* Claim Value Type(s): map
* Change Controller: IETF
* Specification Document(s): {{spdm-measurements}} of {{&SELF}}

### SPDM Certificates Claim

* Claim Name: spdm-certificates
* Claim Description: SPDM Certificates
* JWT Claim Name: N/A
* Claim Key: 3803
* Claim Value Type(s): map
* Change Controller: IETF
* Specification Document(s): {{spdm-certificates}} of {{&SELF}}

### SPDM VCA Claim

* Claim Name: spdm-vca
* Claim Description: SPDM Version, Capabilities and Algorithms
* JWT Claim Name: N/A
* Claim Key: 3804
* Claim Value Type(s): bytes
* Change Controller: IETF
* Specification Document(s): {{spdm-vca}} of {{&SELF}}

### PCIe Legacy Device Text Claim

* Claim Name: pcie-legacy-device-text
* Claim Description: PCIe Legacy Device Textual Representation
* JWT Claim Name: N/A
* Claim Key: 3805
* Claim Value Type(s): map
* Change Controller: IETF
* Specification Document(s): {{pcie-legacy-device}} of {{&SELF}}

### PCIe Legacy Device Binary Claim

* Claim Name: pcie-legacy-device-binary
* Claim Description: PCIe Legacy Device Binary Representation
* JWT Claim Name: N/A
* Claim Key: 3806
* Claim Value Type(s): bytes
* Change Controller: IETF
* Specification Document(s): {{pcie-legacy-device}} of {{&SELF}}

--- back

# Examples

~~~ cbor-diag
{::include-fold cddl/examples/1.diag}
~~~

# Acknowledgments
{:numbered="false"}

Thank you
Basma El Gaabouri,
James Bottomley,
Lukas Wunner,
Simon Frost
and
Yousuf Sait
for your comments and suggestions.
