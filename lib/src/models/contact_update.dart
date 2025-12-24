import 'package:tindarts_sdk/src/models/topic_subscription.dart';

class ContactUpdateEvent {
  final TopicSubscription contact;
  final String what;

  ContactUpdateEvent(this.what, this.contact);
}
