import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/user.dart';

class SelectionWidget<T> extends StatefulWidget {
  final List<T> items; // List of items (users or devices)
  final Function(List<T>)
      onSelectionChanged; // Callback function for when selection changes
  final List<T>? preselectedItems; // List of preselected items
  final bool? singleSelection;
  final Widget Function(T item, bool isSelected)
      itemBuilder; // Builder function

  const SelectionWidget({
    super.key,
    required this.items,
    required this.onSelectionChanged,
    required this.itemBuilder,
    this.preselectedItems,
    this.singleSelection,
  });

  @override
  _SelectionWidgetState<T> createState() => _SelectionWidgetState<T>();
}

class _SelectionWidgetState<T> extends State<SelectionWidget<T>> {
  late List<T> selectedItems;

  @override
  void initState() {
    super.initState();
    // Initialize selectedItems with preselectedItems if provided, else empty list
    selectedItems = List.from(widget.preselectedItems ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final isSelected = selectedItems.contains(item);
        return InkWell(
          onTap: () {
            setState(() {
              if (widget.singleSelection == true) {
                // Clear all previous selections before adding the new one
                selectedItems.clear();
              }
              if (isSelected) {
                selectedItems.remove(item);
              } else {
                selectedItems.add(item);
              }
              widget.onSelectionChanged(selectedItems);
            });
          },
          child: widget.itemBuilder(item, isSelected),
        );
      },
    );
  }
}
