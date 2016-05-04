import Foundation

let headers = [
  "host": "sapnde.sap.norm.local8000",
  "connection": "keep-alive",
  "soapaction": "\\"urnsap-comdocumentsapsoapfunctionsmc-stylez_sap_eCOMMERCE_SERVICE_DEFZDeliveryHistoryRequest\\"",
  "authorization": "Basic aGlzbWF5aWxvdjpBYTE5ODUxOTg1",
  "content-type": "text/xml; charset=\\"UTF-8\\"",
  "accept": "*/*",
  "accept-encoding": "gzip, deflate",
  "accept-language": "en-US,en;q=0.8,az;q=0.6,tr;q=0.4,ru;q=0.2",
  "cache-control": "no-cache",
  "postman-token": "e193c1c9-cb52-9539-f6ae-5eb85dc69a78"
]

let postData = NSData(data: "<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
    <Body>
        <ZDeliveryHistory xmlns="urn:sap-com:document:sap:soap:functions:mc-style">
            <EtDeliveryHistory xmlns="">
                <!-- Optional -->
            </EtDeliveryHistory>
            <IvCustomer xmlns="">0001000001</IvCustomer>
            <IvDate xmlns="">2015-05-01</IvDate>
            <IvDateTo xmlns="">2015-05-30</IvDateTo>
        </ZDeliveryHistory>
    </Body>
</Envelope>".dataUsingEncoding(NSUTF8StringEncoding)!)

var request = NSMutableURLRequest(URL: NSURL(string: "http://sapnde.sap.norm.local:8000/sap/bc/srt/rfc/sap/z_sap_ecommerce_service_def/222/z_serv_delivery/z_bind_serv_delivery")!,
                                        cachePolicy: .UseProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.HTTPMethod = "POST"
request.allHTTPHeaderFields = headers
request.HTTPBody = postData

let session = NSURLSession.sharedSession()
let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
  if (error != nil) {
    println(error)
  } else {
    let httpResponse = response as? NSHTTPURLResponse
    println(httpResponse)
  }
})

dataTask.resume()
