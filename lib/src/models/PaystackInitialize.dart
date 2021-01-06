class PaystackInitialize {
  String authUrl;
  String accessCode;
  String reference;

  // PaystackInitialize.fromJson(Map<String, dynamic> json) {
  //   this.authUrl = json["authorization_url"];
  //   this.accessCode = json["access_code"];
  //   this.reference = json["reference"];
  // }

  PaystackInitialize({this.authUrl, this.accessCode, this.reference});

  @override
  String toString() {
    return """
    PaystackInitialize....
    authUrl: $authUrl,
    accessCode: $accessCode,
    reference: $reference
    """;
  }
}
