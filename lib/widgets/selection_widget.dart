import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/user.dart'; // Import User model
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/utils/enums.dart'; // Import Device model

class SelectionWidget<T> extends StatefulWidget {
  final List<T> items; // List of items (users or devices)
  final Function(List<T>)
      onSelectionChanged; // Callback function for when selection changes
  final List<T>? preselectedItems; // List of preselected items
  final bool? singleSelection;

  const SelectionWidget({
    super.key,
    required this.items,
    required this.onSelectionChanged,
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
    return ListView.builder(
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return _buildItemTile(item);
      },
    );
  }

  Widget _buildItemTile(T item) {
    bool isSelected = selectedItems.any((selectedItem) {
      // Check if the IDs of the selected item and the current item match
      if (selectedItem is User && item is User) {
        return (selectedItem as User).user_id == (item as User).user_id;
      } else if (selectedItem is Device && item is Device) {
        return (selectedItem as Device).device_id == (item as Device).device_id;
      } else if (selectedItem is Mission && item is Mission) {
        return (selectedItem as Mission).id == (item as Mission).id;
      }
      return false;
    });

    return InkWell(
      onTap: () {
        setState(() {
          if (widget.singleSelection == true) {
            // Clear all previous selections before adding the new one
            selectedItems.clear();
          }
          if (isSelected) {
            final indexToRemove = selectedItems.indexWhere((selectedItem) {
              if (selectedItem is User && item is User) {
                return (selectedItem as User).user_id == (item as User).user_id;
              } else if (selectedItem is Device && item is Device) {
                return (selectedItem as Device).device_id ==
                    (item as Device).device_id;
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
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xff293038)),
          ),
        ),
        height: 70,
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                item is User ? item.username : '',
                style: const TextStyle(fontSize: 17, color: Colors.white70),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                item is User
                    ? item.type.toString().split('.').last.toLowerCase()
                    : '',
                style: const TextStyle(fontSize: 17, color: Colors.white70),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                item is User ? item.activeMissionCount.toString() : '',
                style: const TextStyle(fontSize: 17, color: Colors.white70),
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (widget.singleSelection == true) {
                    // Clear all previous selections before adding the new one
                    selectedItems.clear();
                  }
                  if (isSelected) {
                    final indexToRemove =
                        selectedItems.indexWhere((selectedItem) {
                      if (selectedItem is User && item is User) {
                        return (selectedItem as User).user_id ==
                            (item as User).user_id;
                      } else if (selectedItem is Device && item is Device) {
                        return (selectedItem as Device).device_id ==
                            (item as Device).device_id;
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
            ),
          ],
        ),
      ),
    );
  }
}
