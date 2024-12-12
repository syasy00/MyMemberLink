class MyEvent {
  String? eventId;
  String? eventTitle;
  String? eventDescription;
  String? eventStartdate;
  String? eventEnddate;
  String? eventType;
  String? eventLocation;
  String? eventFilename;
  String? eventDate;

  MyEvent(
      {this.eventId,
      this.eventTitle,
      this.eventDescription,
      this.eventStartdate,
      this.eventEnddate,
      this.eventType,
      this.eventLocation,
      this.eventFilename,
      this.eventDate});

  MyEvent.fromJson(Map<String, dynamic> json) {
    eventId = json['event_id'];
    eventTitle = json['event_title'];
    eventDescription = json['event_description'];
    eventStartdate = json['event_startdate'];
    eventEnddate = json['event_enddate'];
    eventType = json['event_type'];
    eventLocation = json['event_location'];
    eventFilename = json['event_filename'];
    eventDate = json['event_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['event_id'] = eventId;
    data['event_title'] = eventTitle;
    data['event_description'] = eventDescription;
    data['event_startdate'] = eventStartdate;
    data['event_enddate'] = eventEnddate;
    data['event_type'] = eventType;
    data['event_location'] = eventLocation;
    data['event_filename'] = eventFilename;
    data['event_date'] = eventDate;
    return data;
  }
}