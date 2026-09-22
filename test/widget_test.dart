import 'package:flutter_test/flutter_test.dart';
import 'package:credo/core/utils/formatters.dart';

void main() {
  test('CredoFormatters rupees test', () {
    expect(CredoFormatters.rupees(1000), contains('1,000'));
  });
}
