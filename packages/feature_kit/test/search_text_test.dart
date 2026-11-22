import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Vietnamese names match without their marks', () {
    expect(SearchText.fold('Nguyễn Thị Ánh'), 'nguyen thi anh');
    expect(SearchText.fold('Đặng Văn Hùng'), 'dang van hung');
    expect(SearchText.fold('Phạm Ngọc Ước'), 'pham ngoc uoc');
  });

  test('other Latin accents fold too', () {
    expect(SearchText.fold('José Müller Straße'), 'jose muller strasse');
  });

  test('every word of the query must be found, in any field', () {
    expect(SearchText.matches('nguyen anh', ['Nguyễn Thị Ánh']), isTrue);
    expect(SearchText.matches('anh nguyen', ['Nguyễn Thị Ánh']), isTrue);
    expect(SearchText.matches('nguyen bao', ['Nguyễn Thị Ánh']), isFalse);
    expect(SearchText.matches('0901', ['Mẹ', '+84 901 234 567']), isFalse);
    expect(SearchText.matches('Mẹ', ['me', 'x']), isTrue);
    expect(SearchText.matches('  ', ['anything']), isTrue);
  });

  test('a typed accent still finds the plain spelling', () {
    expect(SearchText.matches('Nguyễn', ['Nguyen Van A']), isTrue);
  });
}
