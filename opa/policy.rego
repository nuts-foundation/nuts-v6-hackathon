package hackathon_v2024

import rego.v1

default allow := false

allow if {
  token_active

  "hackathon_v2024" in scope

  consent_given

  requestor_part_of_care_team
}

consent_given if requestor_ura in consent_uras

requestor_part_of_care_team if requestor_ura in care_team_uras

scope contains input.introspectionResult.scope

requestor_ura := input.introspectionResult.ura

token_active if {
  input.introspectionResult.active
}

care_team_uras contains org.member.identifier.value if {
  some care_team in fetch_careteam(bsn)
  care_team.resourceType == "CareTeam"

  some org in care_team.participant
  org.member.identifier.system == "$ura"
}

consent_uras contains actor.reference.identifier.value if {
  some consent in fetch_consent(bsn)
  consent.resourceType == "Consent"
    
  some actor in consent.provision.actor
  actor.reference.identifier.system == "$ura"
}

path := urlquery.decode(input.request.uri)
bsn := regex.find_all_string_submatch_n(`^.*identifier=http://fhir.nl/fhir/NamingSystem/bsn\|(\d+)$`, path, -1)[0][1]

fetch_careteam(bsn) := ct if {
  system := "http://fhir.nl/fhir/NamingSystem/bsn%7C"
  res := http.send({
    "method": "get",
    "url": concat("", ["http://fhir:8080/fhir/CareTeam?patient.identifier=", system, bsn]),
    "raise_error": true,
    "force_json_decode": true,
    "headers": {
      "Accept": "application/json",
      "Content-Type": "application/json"
    }
  })

  print("careteam response", res.body)
  res.status_code == 200
  res.body.total > 0
  ct := [ x | x := res.body.entry[_].resource]
}

fetch_consent(bsn) := c if {
  print("test_request")
  system := "http://fhir.nl/fhir/NamingSystem/bsn%7C"

  res := http.send({
    "method": "get",
    "url": concat("", ["http://fhir:8080/fhir/Consent?patient.identifier=", system, bsn, "&status=active&scope=patient-privacy"]),
    "raise_error": false,
    "force_json_decode": true,
    "headers": {
      "Accept": "application/json",
      "Content-Type": "application/json"
    }
  })
  print("consent response", res.body)
  res.status_code == 200
  res.body.total > 0
  c = [ x | x := res.body.entry[_].resource]
}

