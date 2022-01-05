class LocationData {
  final int? id;
  final num latitude;
  final num longitude;
  final String address;
  final String name;
  final DateTime dateTime;

  const LocationData({
    this.id,
    required this.dateTime,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.name,
  });

  Map<String, Object?> toJson() => {
        LocationDataFields.id: id,
        LocationDataFields.dateTime: dateTime.toString(),
        LocationDataFields.latitude: latitude,
        LocationDataFields.longitude: longitude,
        LocationDataFields.address: address,
        LocationDataFields.name: name,
      };
}

class LocationDataFields {
  static final List<String> values = [id, dateTime, latitude, longitude, address, name];
  static final String id = '_id';
  static final String dateTime = 'dateTime';
  static final String latitude = 'latitude';
  static final String longitude = 'longitude';
  static final String address = 'addres';
  static final String name = 'name';
}
