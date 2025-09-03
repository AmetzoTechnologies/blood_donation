import 'donor.dart';

class BloodDonors {
  num? total;
  num? filteredCount;
  num? page;
  num? totalPages;
  num? limit;
  List<Donor>? donors;

  BloodDonors({
    this.total,
    this.filteredCount,
    this.page,
    this.totalPages,
    this.limit,
    this.donors,
  });

  factory BloodDonors.fromJson(Map<String, dynamic> json) => BloodDonors(
    total: num.tryParse(json['total'].toString()),
    filteredCount: num.tryParse(json['filteredCount'].toString()),
    page: num.tryParse(json['page'].toString()),
    totalPages: num.tryParse(json['totalPages'].toString()),
    limit: num.tryParse(json['limit'].toString()),
    donors: (json['donors'] as List<dynamic>?)
        ?.map((e) => Donor.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    if (total != null) 'total': total,
    if (filteredCount != null) 'filteredCount': filteredCount,
    if (page != null) 'page': page,
    if (totalPages != null) 'totalPages': totalPages,
    if (limit != null) 'limit': limit,
    if (donors != null) 'donors': donors?.map((e) => e.toJson()).toList(),
  };
}
