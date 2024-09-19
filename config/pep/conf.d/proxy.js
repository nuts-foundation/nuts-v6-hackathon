async function authz(req) {
  var opa_data = {
    input: {
      request: {
        headers: req.headersIn,
        uri: req.variables.request_uri,
        method: req.method,
      },
    },
  };

  var accessToken = req.variables.http_authorization.split(" ")[1];

  req.log("Access token: " + accessToken);

  try {
    var introspectResponse = await req.subrequest(
      "/introspect",
      "token=" + accessToken,
    );

    var introspectBody = JSON.parse(introspectResponse.responseText);
    req.log("Introspect response: " + JSON.stringify(introspectBody));

    if (!introspectBody.active) {
      req.warn("Access token is not active");
      req.return(401);
      return;
    }

    opa_data.input.introspectionResult = introspectBody;
  } catch (e) {
    req.error("Failed to parse introspect response: " + e);
    req.return(500);
    return;
  }

  req.log("OPA Input: " + JSON.stringify(opa_data));

  var opts = {
    method: "POST",
    body: JSON.stringify(opa_data),
  };

  try {
    var opa = await req.subrequest("/_opa", opts);
    req.log("OPA response: ", opa);
    req.log("OPA response: " + opa.responseText);
    var body = JSON.parse(opa.responseText);
    if (!body.result) {
      req.warn("OPA did not return a result");
      req.return(403);
      return;
    }

    if (!body.result.allow) {
      req.warn("OPA denied the request");
      req.return(403);
      return;
    }
  } catch (e) {
    req.error("Failed to parse OPA response: " + e);
    req.return(500);
    return;
  }

  req.return(200);
}

async function fetchConsent(r) {
  var opts = {
    method: "GET",
  };

  try {
    var response = await r.subrequest("/_fhir/", opts);
  } catch (e) {
    r.error("Failed to fetch consent: " + e);
    r.return(500);
    return;
  }
}

export default { authz };
