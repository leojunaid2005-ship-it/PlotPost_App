/// An enquiry a user sends to a seller from the Show Interest screen.
/// Stored in memory for now; the backend will store these later.
class Enquiry {
  const Enquiry({
    required this.postTitle,
    required this.seller,
    required this.name,
    required this.phone,
    required this.message,
    required this.contactMethod,
    required this.sentAt,
    this.email = '',
    this.wantsVisit = false,
  });

  final String postTitle, seller, name, phone, email, message, contactMethod;
  final bool wantsVisit;
  final DateTime sentAt;
}
