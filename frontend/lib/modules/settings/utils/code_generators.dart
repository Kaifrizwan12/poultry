String generatedCustomerCode() {
  final suffix = (DateTime.now().millisecondsSinceEpoch % 9000) + 1000;
  return 'CUST-$suffix';
}

String generatedSalesmanCode() {
  final suffix = (DateTime.now().millisecondsSinceEpoch % 900) + 100;
  return 'SM-$suffix';
}

String generatedFlockNo() {
  final now = DateTime.now();
  final datePart = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final seq = (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
  return 'FK-$datePart-$seq';
}

String generatedInvoiceNo() {
  final now = DateTime.now();
  final datePart = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final seq = (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
  return 'CI-$datePart-$seq';
}
