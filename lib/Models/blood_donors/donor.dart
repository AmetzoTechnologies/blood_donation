class Donor {
  String? id;
  String? phone;
  String? name;
  String? place;
  DateTime? dateOfBirth;
  String? gender;
  String? bloodGroup;
  bool? isDonor;
  DateTime? lastDonationDate;
  String? profilePic;

  Donor({
    this.id,
    this.phone,
    this.name,
    this.place,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.isDonor,
    this.lastDonationDate,
    this.profilePic,
  });

  factory Donor.fromJson(Map<String, dynamic> json) => Donor(
    id: json['_id']?.toString(),
    phone: json['phone']?.toString(),
    name: json['name']?.toString(),
    place: json['place']?.toString(),
    dateOfBirth: json['dateOfBirth'] == null
        ? null
        : DateTime.tryParse(json['dateOfBirth'].toString()),
    gender: json['gender']?.toString(),
    bloodGroup: json['bloodGroup']?.toString(),
    isDonor: json['isDonor']?.toString().contains("true"),
    lastDonationDate: json['lastDonationDate'] == null
        ? null
        : DateTime.tryParse(json['lastDonationDate'].toString()),
    profilePic: json['profilePic']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    if (phone != null) 'phone': phone,
    if (name != null) 'name': name,
    if (place != null) 'place': place,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth?.toIso8601String(),
    if (gender != null) 'gender': gender,
    if (bloodGroup != null) 'bloodGroup': bloodGroup,
    if (isDonor != null) 'isDonor': isDonor,
    if (lastDonationDate != null)
      'lastDonationDate': lastDonationDate?.toIso8601String(),
    if (profilePic != null) 'profilePic': profilePic,
  };
}
