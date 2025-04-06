class Warehouse {
  final int id;
  final String warehouseName;
  final String warehouseAddress;
  final String type;
  final String? coordinates;
  String telephone;
  List<Map<String, String>> contactPeople;
  List<String> photos;

  Warehouse({
    required this.id,
    required this.warehouseName,
    required this.warehouseAddress,
    required this.type,
    this.telephone = '',
    this.coordinates,
    List<String>? photos,
    List<Map<String, String>>? contactPeople,
  })  : photos = photos ?? [],
        contactPeople = contactPeople ?? [];

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['warehouse_id'],
      warehouseName: json['warehouse_name'],
      warehouseAddress: json['warehouse_address'],
      type: json['type'],
      telephone: json['telephone'] ?? '',
      coordinates: json['coordinates'],
      photos: List<String>.from(json['photos'] ?? []),
      contactPeople:
          List<Map<String, String>>.from(json['contact_people'] ?? []),
    );
  }
}
