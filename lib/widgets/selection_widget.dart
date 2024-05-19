import 'package:flutter/material.dart';
import 'package:flutter_3/models/user.dart'; // Import User model
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/utils/enums.dart'; // Import Device model

class SelectionWidget<T> extends StatefulWidget {
  final List<T> items; // List of items (users or devices)
  final Function(List<T>)
      onSelectionChanged; // Callback function for when selection changes
  final List<T>? preselectedItems; // List of preselected items

  const SelectionWidget({
    super.key,
    required this.items,
    required this.onSelectionChanged,
    this.preselectedItems, // Add this parameter
  });

  @override
  _SelectionWidgetState<T> createState() => _SelectionWidgetState<T>();
}

class _SelectionWidgetState<T> extends State<SelectionWidget<T>> {
  late List<T> selectedItems;

  @override
  void initState() {
    print('SelectionWidget preselectedItems');
    if (widget.preselectedItems!.isNotEmpty) {
      for (var item in widget.preselectedItems!) {
        print(item.toString());
      }
    } else {
      print('SelectionWidget no preselectedItems');
    }
    super.initState();
    // Initialize selectedItems with preselectedItems if provided, else empty list
    selectedItems = List.from(widget.preselectedItems ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return _buildItemText(item);
        },
      ),
    );
  }

  Widget _buildItemText(T item) {
    bool isSelected = selectedItems.any((selectedItem) {
      // Check if the IDs of the selected item and the current item match
      if (selectedItem is User && item is User) {
        return (selectedItem as User).id == (item as User).id;
      } else if (selectedItem is Device && item is Device) {
        return (selectedItem as Device).id == (item as Device).id;
      }
      return false;
    });
    bool isBroker = item is Device && (item as Device).type == DeviceType.BROKER;

    return ListTile(
      title: Text(
        item is User ? (item as User).username : (item as Device).name,
      ),
      onTap: () {
        setState(() {
          if (isBroker) {
            // Clear all previous selections before adding the new one
            selectedItems.clear();
          }
          if (isSelected) {
            final indexToRemove = selectedItems.indexWhere((selectedItem) {
              if (selectedItem is User && item is User) {
                return (selectedItem as User).id == (item as User).id;
              } else if (selectedItem is Device && item is Device) {
                return (selectedItem as Device).id == (item as Device).id;
              }
              return false;
            });
            if (indexToRemove != -1) {
              selectedItems.removeAt(indexToRemove);
            }
          } else {
            selectedItems.add(item);
          }
                  widget.onSelectionChanged(selectedItems); 

          print('SelectionWidget');
          for (var s in selectedItems) {
            print(' ${s.toString()}');
          }
        });
      },
      selected: isSelected,
      selectedTileColor: Colors.blue.withOpacity(0.5),
    );
  }
}