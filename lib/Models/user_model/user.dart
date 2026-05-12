class User {
  String? id;
  String? phone;
  String? name;
  String? address;
  String? place;
  DateTime? dateOfBirth;
  String? gender;
  String? bloodGroup;
  bool? isDonor;
  bool? isProfileComplete;
  DateTime? lastDonationDate;
  String? profilePic;
  DateTime? lastLogin;

  User({
    this.id,
    this.phone,
    this.name,
    this.address,
    this.place,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.isDonor,
    this.isProfileComplete,
    this.lastDonationDate,
    this.profilePic,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['_id']?.toString(),
    phone: json['phone']?.toString(),
    name: json['name']?.toString(),
    address: (json['address'] ?? json['location'] ?? json['fullAddress'])
        ?.toString(),
    place: (json['place'] ?? json['city'])?.toString(),
    dateOfBirth: json['dateOfBirth'] == null
        ? null
        : DateTime.tryParse(json['dateOfBirth'].toString()),
    gender: json['gender']?.toString(),
    bloodGroup: json['bloodGroup']?.toString(),
    isDonor: json['isDonor']?.toString().contains("true"),
    isProfileComplete: json['isProfileComplete'] is bool
        ? json['isProfileComplete']
        : json['isProfileComplete']?.toString().contains("true"),
    lastDonationDate: (json['lastDonationDate'] ?? json['lastDonatedDate']) ==
            null
        ? null
        : DateTime.tryParse(
            (json['lastDonationDate'] ?? json['lastDonatedDate']).toString(),
          ),
    profilePic: json['profilePic']?.toString(),
    lastLogin: json['lastLogin'] == null
        ? null
        : DateTime.tryParse(json['lastLogin'].toString()),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    if (phone != null) 'phone': phone,
    if (name != null) 'name': name,
    if (address != null) 'address': address,
    if (place != null) 'place': place,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth?.toIso8601String(),
    if (gender != null) 'gender': gender,
    if (bloodGroup != null) 'bloodGroup': bloodGroup,
    if (isDonor != null) 'isDonor': isDonor,
    if (isProfileComplete != null) 'isProfileComplete': isProfileComplete,
    if (lastDonationDate != null)
      'lastDonationDate': lastDonationDate?.toIso8601String(),
    if (profilePic != null) 'profilePic': profilePic,
    if (lastLogin != null) 'lastLogin': lastLogin?.toIso8601String(),
  };
}
