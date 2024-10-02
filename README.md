# Nuts version 6 Hackathon files

This repository contains the files for the Nuts version 6 Hackathon.
It includes a docker-compose which start up a test environment and a set of configured API requests for easy testing.
The API request can be used with the free [Bruno API client](https://www.usebruno.com).

## Files and folders:

- bundles: contains the compiled rego policy bundle
- config: contains the configuration files for the several docker containers
- data: contains the data files for the several docker containers
- Hackathon_v2024.10 contains a [Bruno API config](https://www.usebruno.com) for easy API testing
- opa: contains the rego policy files


## How to run

Start the docker containers with the following command:
```bash
$ docker-compose up
```

## Use case

The setup simulates 2 Care Organizations (Org1 and Org2). Org 1 is a General Practitioner, Org 2 is a VVT Organisation.

The GP wants to fetch data from the VVT organization.

Org2 has a FHIR server with a Patient resource. Wich is protected by a Nuts node for authentication and a OPA server for authorization.

Org2 uses a policy which fetches the patients CareTeamm and Consent records. If the GP is in the care Team and has consent, the data is returned.


## Containers
The following services will be available:

- nuts-node1: The nuts node, used for issuer and Org1 and Org2
- fhir: The FHIR server of Org2
- opa: The OPA server of Org2
- pep: A nginx container which protects the FHIR endpoint by questioning the OPA server with the accessToken.
- bundle-server: A simple http server to serve the opa policy bundle


## Building the policy bundle

The policy file located in the opa folder must be compiled after changes. This can be done by running the following command:

It requires you have the OPA CLI installed.

```bash
$ opa build --bundle ./opa --output ./bundles/bundle.tar.gz
```

