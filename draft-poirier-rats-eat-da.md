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
    fullname: Henk Birkholz
    organization: Fraunhofer SIT
    email: henk.birkholz@ietf.contact
 -
    fullname: Thomas Fossati
    organization: Linaro
    email: thomas.fossati@linaro.org

normative:
  RFC9711: rats-eat
  RFC5280: pkix
  RFC4514: dn-string-rep
  IANA.cwt:
  STD94:
    -: cbor
    =: RFC8949
  RFC8392: cwt
  RFC9781: uccs
  RFC9782: eat-media-types
  RFC9052: cose
  RFC9053: cose-algs
  RFC9334: rats-arch
  I-D.ietf-rats-msg-wrap: cmw
  I-D.ietf-rats-epoch-markers: epoch-markers

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

In confidential computing, device assignment (DA) is the method by which a device (e.g., network adapter, GPU), whether on-chip or behind a PCIe Root Port, is assigned to a Trusted Virtual Machine (TVM).
For the TVM to trust an assigned device, the device must provide the TVM with attestation Evidence confirming its identity and the state of its firmware and configuration.

Since Evidence claims can be processed by 3rd party entities (e.g., Verifiers, Relying Parties) external to the TVM, there is a need to standardize the representation of DA-related information in Evidence to ensure interoperability.
This document defines an attestation Evidence format for DA as an EAT (Entity Attestation Token) profile.

--- middle

# Introduction

In confidential computing, device assignment (DA) is the method by which a device (e.g., network adapter, GPU), whether on-chip or behind a PCIe Root Port, is assigned to a Trusted Virtual Machine (TVM).
Most confidential computing platforms (e.g., Arm CCA, AMD SEV-SNP, Intel TDX) provide DA capabilities.
Such capabilities prevent execution environments or software components that are untrusted by the TVM (including other TVMs and the host hypervisor) from accessing or controlling a device that has been assigned to the TVM.
This includes, for example, protection of device MMIO interfaces and device caches.
From a trust perspective, DA allows a device to be included in the TVM's Trusted Computing Base (TCB).
For the TVM to trust the device, the device must provide the TVM with attestation Evidence confirming its identity and the state of its firmware and configuration.

This document defines an attestation Evidence format for DA as an EAT {{-rats-eat}} profile.
The format is designed to be generic, extensible and architecture-agnostic.
Ongoing work on DA concentrates on PCIe devices that support the SPDM protocol {{-spdm}}.
As such, this document focuses on establishing the overall framework and formalizing an Evidence format for SPDM-compliant devices.
This format is based on the information provided by the SPDM protocol without imposing additional security constraints.
It is incumbent upon other entities to describe, select and enforce those additional security constraints based on operational requirements.

Since other bus architectures and protocols are expected to be supported as the technology gains wider adoption, provisions have been made for the definition of other Evidence formats such as Compute Express Link (CXL) and the Coherent Hub Interface (CHI).
This list is by no means exhaustive and is expected to expand.
{{extend}} outlines the requirements for incorporating new bus technologies into the DAT framework.
Lastly, live migration of a TVM from one host to another is currently not addressed by the SPDM specification and therefore not covered herein.

# Conventions and Definitions

{::boilerplate bcp14-tagged}

# Device Assignment Token (DAT) Claims {#dat-claims}

The Device Assignment Token (DAT) is the encompassing envelope for the individual device claims to be presented.
A DAT can be used as a standalone entity but can also be embedded in a larger, platform-specific attestation token.
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

## SPDM Claims {#spdm-claims}

A SPDM claim instance is expected to be present for each SPDM compatible device to be attested.
Each instance consists of a measurements section, a certificates section, or both.
These can be supplemented with two additional sections: (1) a challenge for Component Mesaurement and Authentication (CMA) scenarios and (2) a device interface report that contains information from the TEE Device Information Security Protocol (TDISP) Device Interface Report.
A challenge needs certificate information from the certificate section and as such, can only be present if certificates are included in the SPDM artifacts.
TDISP messages are embedded in the VENDOR_DEFINED_REQUEST and VENDOR_DEFINED_RESPONSE messages of the SPDM protocol.
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

### SPDM Challenge Claim {#spdm-challenge}

SPDM compliant devices can optionally support the capability to authenticate responders through the challenge-response protocol and sign measurements.
Included in the signature are all the elements needed by a third party entity to reconstruct the original transcript or measurement log signed by the device.
Those elements include M1 for challenge signatures or L1 for measurement signatures (see CDDL below), the combined SPDM prefix, the hash algorithm used to generate a digest of the measurement log and nonces provided by the requester and responder.
The slot number of the leaf certificate used to sign the measurement log is also provided.

~~~ cddl
{::include-fold cddl/spdm-signature.cddl}
~~~

### Certificate Claims {#spdm-certificates}

According to the specification, SPDM compliant devices should support at most 8 slots, with slot 0 populated by default.
Slot 0 SHALL contain a certificate chain that follows the Device certificate model or the Alias certificate model.
Regardless of the certificate model used, a certificate chain comprises one or more DER-encoded X.509 v3 certificates {{-pkix}}.
The certificates MUST be concatenated with no intermediate padding.

~~~ cddl
{::include-fold cddl/spdm-certificates.cddl}
~~~

### TDISP Device Interface Report {#interface-report}

A TDISP Device Interface Report can only be obtained if the device interface has transitioned to the CONFIG_LOCK or RUN state of the TDISP state machine.

It begins with various bitfields indicating the state and characteristics of the PCIe device interface.
Next are 3 register fields pertaining to MSI-X (Message Signalled Interrupts), LNR (Lightweight Notification Requester) and TPH (TLP Processing Hints) capabilities.
MMIO ranges are assigned from PCIe BAR(s) and provide information about the memory areas a device is working with.
More information on the MMIO range bitfields and the ones defined as part of the device interface field (above) can be found in the TDISP section of the PCI Express specification.
The last field is device-specific and optionally included to convey additional configuration information about the device.

~~~ cddl
{::include-fold cddl/tdisp-device-interface-report.cddl}
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

# DAT EAT Profile {#profile}

## Encoding

A DAT is encoded in CBOR {{-cbor}}.
The CBOR representation of a DAT MUST be "valid" according to the definition in {{Section 1.2 of -cbor}}.
Only definite-length strings, arrays, and maps are allowed.
Since a DAT emitter may be found in a constrained environment, it may not be able to emit CBOR preferred serializations ({{Section 4.1 of -cbor}}).
Therefore, the Verifier MUST be a variation-tolerant CBOR decoder.

## Cryptographic Protection

Cryptographic protection can be obtained by wrapping the `dat` claims-set in a COSE Web Token (CWT) {{-cwt}}.
In this case, the signature structure MUST be a tagged (18) COSE_Sign1.
Alternatively, a DAT can be part of a Conceptual Message Wrapper (CMW) {{-cmw}} collection.
In this case, the DAT claims-set can be a UCCS {{-uccs}} and the protection is provided by the signed CMW.

The flexibility provided by the COSE {{-cose}} format should be sufficient to adapt to the level of cryptographic agility required for specific use cases.
It is RECOMMENDED that commonly adopted algorithms, such as those discussed in {{-cose-algs}}, are used.
While receivers are expected to accept a wide range of algorithms, Attesters will produce DAT using only one such algorithm.

## Use with Conceptual Message Wrappers

When used in a CMW, the collector will wrap the serialised COSE_Sign1 or UCCS with the appropriate media type or CoAP Content-Format defined in {{-eat-media-types}}.

## Freshness Model

DAT supports the freshness models for attestation Evidence based on nonces and epoch IDs (see {{Section 10.2 and Section 10.3 of -rats-arch}}) using the `eat_nonce` claim to convey the nonce or epoch ID supplied by the Verifier.
No further assumptions are made about the specific remote attestation protocol.

Note that the use of epoch IDs is subject by the type restrictions imposed by the `eat_nonce` syntax.
For use in DAT, the epoch ID must be encodable as an opaque binary string of between 8 and 64 octets; an Epoclet can be used for this purpose (see {{-epoch-markers}}).

## Synopsis

{{tbl-profile}} presents a concise view of the requirements described in the preceding sections.

| Issue | Profile Definition |
| CBOR/JSON | CBOR MUST be used  |
| CBOR Encoding | Definite length maps and arrays MUST be used |
| CBOR Encoding | Definite length strings MUST be used |
| CBOR Serialization | Variant serialization MAY be used |
| COSE Protection | COSE_Sign1 MUST be used (directly or via CMW) |
| Algorithms | {{-cose-algs}} SHOULD be used |
| Detached EAT Bundle Usage | Detached EAT bundles MUST NOT be sent |
| Verification Key Identification | Any identification method listed in {{Appendix F.1 of -rats-eat}} |
| Freshness | nonce or epoch ID based ({{Section 10.2 and Section 10.3 of -rats-arch}}) |
| Claims | Those defined in {{dat-claims}}. As per general EAT rules, the receiver MUST NOT error out on claims it does not understand. |
{: #tbl-profile title="DAT Profile Synopsis"}

# Extending the DAT Framework {#extend}

An extension to the DAT framework that introduces support for a new bus technology MUST provide the following information in a public document (e.g., an Internet-Draft):

* A precise definition of the new claims-set,
* A naming convention for the `submod` map entry,
* The registration of any new claims with IANA.

## Claims-set Definition

The new claims-set MUST be specified clearly and unambiguously, ideally using CDDL, with a separate prose description of each claim.
The claims-set MUST include a suitable `eat_profile` value.

See {{spdm-claims}} for the blueprint.

## Naming Conventions for the `submod` Key

A new claims-set MUST define a suitable naming convention for the `submod` keys associated with it.
When creating this convention, ensure that it does not clash with any existing ones.

See {{spdm-submod-name}} for the blueprint.

## Claims Registrations

A new claims-set can reuse any number of already registered claims.
If the claims-set needs to define new claims to express the desired semantics, and if these claims have generally applicable semantics, they SHOULD be registered with IANA.

See {{iana-claims-regs}} for the blueprint.

# Collated CDDL

~~~ cddl
{::include-fold cddl/da-token-autogen.cddl}
~~~

# Security Considerations

TODO Security

# IANA Considerations

## New CWT Claims Registrations {#iana-claims-regs}

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

### SPDM Challenge Claim

* Claim Name: spdm-challenge
* Claim Description: SPDM Challenge signature block
* JWT Claim Name: N/A
* Claim Key: 3807
* Claim Value Type(s): map
* Change Controller: IETF
* Specification Document(s): {{spdm-challenge}} of {{&SELF}}

### TDISP Device Interface Report

* Claim Name: tdisp-device-interface-report
* Claim Description: TDISP Device Interface Report
* JWT Claim Name: N/A
* Claim Key: 3808
* Claim Value Type(s): map
* Change Controller: IETF
* Specification Document(s): {{interface-report}} of {{&SELF}}

--- back

# Examples

~~~ cbor-diag
{::include-fold cddl/examples/1.diag}
~~~

# Example Composite Device

{{fig-ratsd}} shows an example of the composite device described in {{Section 3.3 of -rats-arch}} within a confidential computing environment.
In this setup, a Trusted Virtual Machine (TVM) executes on a Confidential Platform, which provides the confidential computing environment.
One or more devices (e.g., a GPU) are assigned to the TVM.

Within the TVM, a Lead Attester agent, e.g., a userland daemon, can collect Evidence from the Confidential Platform, as well as from all the assigned devices, using the relevant ABI offered by the guest OS kernel.

~~~ aasvg
      .---------------.
     | Verifier / RP   |
      '------------+--'
                   |
  .----------------|-------------------------------.
 |                 |                                |
 |                 |           .-----------------.  |
 |                 |         .-+---------------. |  |
 |  .--------------|----.  .-+---------------. | |  |
 |  |  Trusted VM  |    |  | Assigned Device | | |  |
 |  |              |    |  |                 | | |  |
 |  | .------------+--. |  |                 | | |  |
 |  | | Lead          | |  |                 | | |  |
 |  | | Attester      | |  |                 | | |  |
 |  | '---+-------+---' |  |                 | | |  |
 |  |     |       |     |  | .-------------. | | |  |
 |  | .---+-------+---. |  | | Device      | | | |  |
 |  | | Guest Kernel  | |  | | Attester    | | | |  |
 |  | '---+-------+---' |  | '---+---------' | +-'  |
 |  |     |       |     |  |     |           +-'    |
 |  '-----|-------|-----'  '-----|-----------'      |
 |        |       |              |                  |
 |  .-----|-------|-----.  .-----|-----------.      |
 |  |     |       |     |  |     |           |      |
 |  |     |        '------------'            |      |
 |  | .---+-----------. |  |                 |      |
 |  | | Platform      | |  |                 |      |
 |  | | Attester      | |  |                 |      |
 |  | '---------------' |  |                 |      |
 |  |                   |  |                 |      |
 |  |  Confidential     |  | Untrusted       |      |
 |  |  Platform         |  | Platform        |      |
 |  '-------------------'  '-----------------'      |
 |                                                  |
  '------------------------------------------------'
~~~
{: #fig-ratsd title="Confidential VM with Trusted Device(s)" align="center" }

When a challenger (i.e., a Verifier or a Relying Party) requests Evidence from the TVM, the Lead Attester broadcasts the received nonce to all the sub-Attesters, obtains Evidence from each of them and assembles the composite Evidence using a CMW Collection (Section 3.3 of {{-cmw}}).
It then signs the composite Evidence using its key material as shown in {{fig-ratsd-token}}.

The claims obtained by the assigned devices are repackaged into DAT submods, which are then signed as part of the CMW collection using the Lead Attester key.

~~~ aasvg
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
         |     |  .---------------.  |  | submod: {                  |
         '------->| DAT           +- - -+   "spdm:A": { ... }        |
               |  '---------------'  |  |   "legacy-pcie:B": { ... } |
               '---------------------'  |   "spdm:C": { ... }        |
                                        | }                          |
                                        '----------------------------'
~~~
{: #fig-ratsd-token title="Composite Attestation Evidence" align="center" }

The Veraison project's `ratsd` daemon is an example of this behaviour.

# Acknowledgments
{:numbered="false"}

Thank you
Basma El Gaabouri,
James Bottomley,
Jon Lange,
Lukas Wunner,
Roksana Golizadeh Mojarad,
Simon Frost
and
Yousuf Sait
for your comments and suggestions.
