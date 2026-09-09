import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/location_model.dart';

void main() {
  group('LocationModel', () {
    test('supports value equality', () {
      const loc1 = LocationModel(
        id: '1',
        displayName: 'A',
        address: 'B',
      );
      const loc2 = LocationModel(
        id: '1',
        displayName: 'A',
        address: 'B',
      );
      const loc3 = LocationModel(
        id: '2',
        displayName: 'A',
        address: 'B',
      );

      expect(loc1, loc2);
      expect(loc1.hashCode, loc2.hashCode);
      expect(loc1, isNot(loc3));
    });

    test('copyWith creates a new instance with updated values', () {
      const loc = LocationModel(
        id: '1',
        displayName: 'A',
        address: 'B',
      );

      final updated = loc.copyWith(displayName: 'C', latitude: 10.0);

      expect(updated.id, '1');
      expect(updated.displayName, 'C');
      expect(updated.address, 'B');
      expect(updated.latitude, 10.0);
    });
  });
}
