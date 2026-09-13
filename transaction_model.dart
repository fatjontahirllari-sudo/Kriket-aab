class TransactionModel {
  final String id;
  final String userId;
  final String name;
  final String category;
  final DateTime transactionDate;
  final double amount;
  final bool isCredit;
  final String status;
  final String icon;
  final int avatarColor;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.transactionDate,
    required this.amount,
    required this.isCredit,
    required this.status,
    required this.icon,
    required this.avatarColor,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? '',
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      amount: (json['amount'] as num).toDouble(),
      isCredit: json['is_credit'] as bool,
      status: json['status'] as String,
      icon: json['icon'] as String? ?? 'receipt_long_outlined',
      avatarColor: (json['avatar_color'] as num).toInt(),
    );
  }

  Map<String, dynamic> toDisplayMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'date': _formatDate(transactionDate),
      'amount': amount,
      'isCredit': isCredit,
      'status': status,
      'icon': icon,
      'avatarColor': avatarColor,
    };
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'pm' : 'am';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year} at ${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}
