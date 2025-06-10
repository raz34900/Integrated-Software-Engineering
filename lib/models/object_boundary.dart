class ObjectBoundary {
  final String? systemID;
  final String? objectId;
  final String? type;
  final String? name;
  final Map<String, dynamic>? objectDetails;
  final String? createdBy;
  final String? creationTimestamp;

  ObjectBoundary({
    this.systemID,
    this.objectId,
    this.type,
    this.name,
    this.objectDetails,
    this.createdBy,
    this.creationTimestamp,
  });

  factory ObjectBoundary.fromJson(Map<String, dynamic> json) {
    return ObjectBoundary(
      systemID: json['systemID'] as String?,
      objectId: json['objectId'] as String?,
      type: json['type'] as String?,
      name: json['name'] as String?,
      objectDetails:
          json['objectDetails'] != null
              ? Map<String, dynamic>.from(json['objectDetails'])
              : null,
      createdBy: json['createdBy'] as String?,
      creationTimestamp: json['creationTimestamp'] as String?,
    );
  }
}
