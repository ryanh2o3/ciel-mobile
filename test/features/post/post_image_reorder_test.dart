import 'package:ciel_mobile/features/post/presentation/post_image_reorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyReorder', () {
    test('moves an item forward, accounting for index shift', () {
      // ReorderableListView emits newIndex *before* removal, so dropping
      // item 0 at "index 3" should land it before what was originally
      // item 3 — i.e. at position 2 after removal.
      expect(applyReorder(['a', 'b', 'c', 'd'], 0, 3), ['b', 'c', 'a', 'd']);
    });

    test('moves an item backward without shifting', () {
      expect(applyReorder(['a', 'b', 'c', 'd'], 3, 1), ['a', 'd', 'b', 'c']);
    });

    test('returns input list when source and destination are the same', () {
      final input = ['a', 'b', 'c'];
      expect(identical(applyReorder(input, 1, 1), input), isTrue);
      expect(identical(applyReorder(input, 1, 2), input), isTrue);
    });

    test('clamps newIndex to the list bounds', () {
      expect(applyReorder(['a', 'b', 'c'], 0, 99), ['b', 'c', 'a']);
    });

    test('returns input list when oldIndex is out of range', () {
      final input = ['a', 'b'];
      expect(identical(applyReorder(input, 5, 0), input), isTrue);
    });
  });
}
