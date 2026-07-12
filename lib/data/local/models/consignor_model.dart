class ConsignorModel {
  final int id;
  final int businessId;
  final String name;
  final String? phone;
  final String? notes;
  final DateTime? createdAt;

  ConsignorModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'business_id': businessId,
        'name': name,
        'phone': phone,
        'notes': notes,
        'created_at': createdAt?.toIso8601String(),
      };

  factory ConsignorModel.fromMap(Map<String, dynamic> map) => ConsignorModel(
        id: map['id'] as int,
        businessId: map['business_id'] as int,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        notes: map['notes'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
      );
}
