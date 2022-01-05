class StepsData {
  final int? id;
  final num steps;
  final DateTime dateTime;

  const StepsData({
    this.id,
    required this.dateTime,
    required this.steps,
  });

  Map<String, Object?> toJson() => {
        StepsDataFields.id: id,
        StepsDataFields.dateTime: dateTime.toString(),
        StepsDataFields.steps: steps,
      };
}

class StepsDataFields {
  static final List<String> values = [id, dateTime, steps];
  static final String id = '_id';
  static final String dateTime = 'dateTime';
  static final String steps = 'steps';
}
