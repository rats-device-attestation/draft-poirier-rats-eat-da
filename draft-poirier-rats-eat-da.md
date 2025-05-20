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

informative:

--- abstract

TODO Abstract

--- middle

# Introduction

TODO Introduction

# Conventions and Definitions

{::boilerplate bcp14-tagged}

# Device Attestation Claims

~~~ cddl
{::include cddl/da-token.cddl}
~~~

## SPDM Claims

~~~ cddl
{::include cddl/spdm-claims.cddl}
~~~

### Measurement Claims

~~~ cddl
{::include cddl/spdm-measurement.cddl}
~~~

### Certificate Claims

~~~ cddl
{::include cddl/spdm-certificates.cddl}
~~~

# Collated CDDL

~~~ cddl
{::include cddl/da-token-autogen.cddl}
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
{::include cddl/examples/1.diag}
~~~

# Acknowledgments
{:numbered="false"}

TODO acknowledge.
