import 'package:flutter/material.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/utils/helpers.dart';

class FilterDrawerWidget extends StatefulWidget {
  final Function(List<Status> selectedStatuses, List<UserType> selectedTypes)
      onFilterApplied;

  const FilterDrawerWidget({Key? key, required this.onFilterApplied})
      : super(key: key);

  @override
  State<FilterDrawerWidget> createState() => _FilterDrawerWidgetState();
}

class _FilterDrawerWidgetState extends State<FilterDrawerWidget> {
  List<Status> selectedStatuses = [];
  List<UserType> selectedTypes = [];

  List<Status> statuses = Status.values.toList();
  List<UserType> types = UserType.values.toList();
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const Text('Filter Options'),
          ExpansionTile(
            title: const Text('Status'),
            children: statuses
                .map((status) => CheckboxListTile(
                      title: Text(statusToString(status)),
                      value: selectedStatuses.contains(status),
                      onChanged: (value) {
                        setState(() {
                          if (value != null && value) {
                            selectedStatuses.add(status);
                          } else {
                            selectedStatuses.remove(status);
                          }
                        });
                      },
                    ))
                .toList(),
          ),
          ExpansionTile(
            title: const Text('User Type'),
            children: types
                .map((type) => CheckboxListTile(
                      title: Text(userTypeToString(type)),
                      value: selectedTypes.contains(type),
                      onChanged: (value) {
                        setState(() {
                          if (value != null && value) {
                            selectedTypes.add(type);
                          } else {
                            selectedTypes.remove(type);
                          }
                        });
                      },
                    ))
                .toList(),
          ),
          ListTile(
            title: const Text('Apply Filter'),
            onTap: () {
              widget.onFilterApplied(selectedStatuses, selectedTypes);

              // Close the drawer
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
