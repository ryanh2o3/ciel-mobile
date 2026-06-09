/// Applies a single drag-reorder to [items], using the index semantics
/// `ReorderableListView` emits (where [newIndex] is the destination index
/// *before* removal of the moved item).
///
/// Returns a new list. Returns the input list unchanged if the indices
/// are out of range or describe a no-op move.
List<T> applyReorder<T>(List<T> items, int oldIndex, int newIndex) {
  if (oldIndex < 0 || oldIndex >= items.length) return items;
  var target = newIndex.clamp(0, items.length);
  if (target > oldIndex) target -= 1;
  if (target == oldIndex) return items;
  final out = List<T>.of(items);
  final moved = out.removeAt(oldIndex);
  out.insert(target, moved);
  return out;
}
