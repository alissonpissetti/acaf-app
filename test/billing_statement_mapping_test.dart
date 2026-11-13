import 'package:flutter_test/flutter_test.dart';

import 'package:acaf/services/connect_api.dart';

void main() {
  test('normaliza status do extrato da assinatura', () {
    expect(ConnectBillingStatementRow.normalizedStatus('paid'), 'paid');
    expect(ConnectBillingStatementRow.normalizedStatus('PENDING'), 'pending');
    expect(ConnectBillingStatementRow.normalizedStatus('failed'), 'failed');
    expect(ConnectBillingStatementRow.normalizedStatus('unknown'), 'pending');
  });
}
