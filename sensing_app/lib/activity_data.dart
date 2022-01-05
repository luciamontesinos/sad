class ActivityData {
  final int? id;
  final num certainty;
  final String activity;
  final DateTime dateTime;

  const ActivityData({
    this.id,
    required this.dateTime,
    required this.certainty,
    required this.activity,
  });

  Map<String, Object?> toJson() => {
        ActivityDataFields.id: id,
        ActivityDataFields.dateTime: dateTime.toString(),
        ActivityDataFields.certainty: certainty,
        ActivityDataFields.activity: activity,
      };
}

class ActivityDataFields {
  static final List<String> values = [id, dateTime, activity, certainty];
  static final String id = '_id';
  static final String dateTime = 'dateTime';
  static final String certainty = 'certainty';
  static final String activity = 'activity';
}
