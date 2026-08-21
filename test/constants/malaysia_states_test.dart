import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/constants/malaysia_states.dart';

void main() {
  group('MalaysiaStates unit tests', () {
    test('blank and whitespace input does NOT default to Penang', () {
      expect(MalaysiaStates.toCanonical(''), '');
      expect(MalaysiaStates.toCanonical('   '), '');
      expect(MalaysiaStates.toDisplay(''), '');
      expect(MalaysiaStates.toDisplay('   '), '');
    });

    test('maps Penang display and canonical values correctly', () {
      expect(MalaysiaStates.toCanonical('Penang'), 'Pulau Pinang');
      expect(MalaysiaStates.toCanonical('penang'), 'Pulau Pinang');
      expect(MalaysiaStates.toCanonical('Pulau Pinang'), 'Pulau Pinang');
      expect(MalaysiaStates.toCanonical('pulau pinang'), 'Pulau Pinang');

      expect(MalaysiaStates.toDisplay('Pulau Pinang'), 'Penang');
      expect(MalaysiaStates.toDisplay('pulau pinang'), 'Penang');
      expect(MalaysiaStates.toDisplay('Penang'), 'Penang');
    });

    test('maps standard Malaysian states and federal territories correctly',
        () {
      expect(MalaysiaStates.toCanonical('Kuala Lumpur'), 'Kuala Lumpur');
      expect(MalaysiaStates.toDisplay('Kuala Lumpur'), 'Kuala Lumpur');

      expect(MalaysiaStates.toCanonical('Johor'), 'Johor');
      expect(MalaysiaStates.toDisplay('Johor'), 'Johor');

      expect(MalaysiaStates.toCanonical('Sabah'), 'Sabah');
      expect(MalaysiaStates.toDisplay('Sabah'), 'Sabah');
    });

    test('preserves unknown custom raw and display strings cleanly', () {
      expect(MalaysiaStates.toCanonical('Borneo Highland'), 'Borneo Highland');
      expect(MalaysiaStates.toDisplay('Borneo Highland'), 'Borneo Highland');
    });

    test('getDisplayList includes custom existing state without data loss', () {
      final defaultList = MalaysiaStates.getDisplayList();
      expect(defaultList.contains('Penang'), isTrue);
      expect(defaultList.contains('Kuala Lumpur'), isTrue);
      expect(defaultList.contains('Vintage Territory'), isFalse);

      final customList = MalaysiaStates.getDisplayList(
          existingRawOrDisplay: 'Vintage Territory');
      expect(customList.first, 'Vintage Territory');
      expect(customList.contains('Penang'), isTrue);
    });
  });
}
