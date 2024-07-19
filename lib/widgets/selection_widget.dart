import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/user.dart';

class SelectionWidget<T> extends StatefulWidget {
  final List<T> items;
  final List<T> preselectedItems;
  final bool singleSelection;
  final Function(List<T>) onSelectionChanged;
  final Widget Function(T item, bool isSelected) itemBuilder;

  SelectionWidget({
    required this.items,
    required this.preselectedItems,
    required this.singleSelection,
    required this.onSelectionChanged,
    required this.itemBuilder,
  });

  @override
  _SelectionWidgetState<T> createState() => _SelectionWidgetState<T>();
}

class _SelectionWidgetState<T> extends State<SelectionWidget<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = widget.preselectedItems;
    print('SelectionWidget _selectedItems $_selectedItems');
  }

  void _toggleSelection(T item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        if (widget.singleSelection) {
          _selectedItems = [item];
        } else {
          _selectedItems.add(item);
        }
      }
      widget.onSelectionChanged(_selectedItems);
    });
  }

  @override
  Widget build(BuildContext context) {
    print('widget.items.length ${widget.items.length}');
    return ListView.builder(
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final isSelected = _selectedItems.contains(item);
        return InkWell(
          onTap: () => _toggleSelection(item),
          child: widget.itemBuilder(item, isSelected),
        );
      },
    );
  }
}
