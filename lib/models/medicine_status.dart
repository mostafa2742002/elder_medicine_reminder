enum MedicineStatus {
  pending,
  taken,
  missed;

  String toJson() {
    return name;
  }

  static MedicineStatus fromJson(String value) {
    return MedicineStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => MedicineStatus.pending,
    );
  }
}