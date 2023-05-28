import strutils
import strformat
import httpclient
import asyncdispatch
import base64
import options
import tables; export tables
import json
import uri

type
  StripeClient* = ref object of RootObj
    secret: string
  
const BASE_URL = "https://api.stripe.com/v1"

var global_stripe_client = none[StripeClient]()

proc newStripeClient*(secret: string): StripeClient =
  doAssert secret.startsWith("sk_")
  new(result)
  result.secret = secret

proc setStripeClient*(client: StripeClient) =
  global_stripe_client = some(client)

proc stripeClient*(): StripeClient =
  if global_stripe_client.isNone:
    raise newException(ValueError, "No stripe client set")
  result = global_stripe_client.get()

proc headers(client: StripeClient): HttpHeaders =
  let auth_value = (&"{client.secret}:").encode()
  newHttpHeaders({
    "Authorization": &"basic {auth_value}",
    "Content-Type": "application/x-www-form-urlencoded",
  })

proc urlencode(data: Table[string, string]): string {.inline.} =
  ## Convert to format suitable for an HTTP
  ## application/x-www-form-urlencoded body
  for k,v in data.pairs:
    result.add &"{k.encodeUrl()}={v.encodeUrl()}&"
  if result.len > 0:
    result.setLen(result.len - 1)

proc get*(client: StripeClient, path: string, params = initTable[string, string]()): Future[JsonNode] {.async.} =
  var hclient = newAsyncHttpClient()
  defer: hclient.close()
  hclient.headers = client.headers
  var url = BASE_URL & path
  if params.len > 0:
    url = url & "?" & params.urlencode()
  let req = await hclient.get(url)
  let body = await req.body
  result = body.parseJson()

proc post*(client: StripeClient, path: string, data = initTable[string, string]()): Future[JsonNode] {.async.} =
  var hclient = newAsyncHttpClient()
  defer: hclient.close()
  hclient.headers = client.headers
  var url = BASE_URL & path
  let req = await hclient.post(url, body = data.urlencode())
  let body = await req.body
  result = body.parseJson()

proc delete*(client: StripeClient, path: string, params = initTable[string, string]()): Future[JsonNode] {.async.} =
  var hclient = newAsyncHttpClient()
  defer: hclient.close()
  hclient.headers = client.headers
  var url = BASE_URL & path
  if params.len > 0:
    url = url & "?" & params.urlencode()
  let req = await hclient.delete(url)
  let body = await req.body
  result = body.parseJson()