import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
      child: Container(
        color: Color.fromARGB(255, 178, 181, 195),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 65),
                height: 100,
                child: const ListTile(
                  title: Text(
                    'Filter Options',
                    style: TextStyle(
                      color: const Color(0xff121417),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
            ExpansionTile(
              title: const Text(
                'User Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff121417),
                ),
              ),
              children: statuses
                  .map(
                    (status) => CheckboxListTile(
                      title: Text(
                        statusToString(status),
                        style: const TextStyle(
                          color: const Color(0xff121417),
                          fontSize: 14,
                        ),
                      ),
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
                    ),
                  )
                  .toList(),
            ),
            ExpansionTile(
              title: const Text(
                'User Type',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xff121417),
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: types
                  .map(
                    (type) => CheckboxListTile(
                      title: Text(
                        userTypeToString(type),
                        style: const TextStyle(
                          fontSize: 14,
                          color: const Color(0xff121417),
                        ),
                      ),
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
                    ),
                  )
                  .toList(),
            ),SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    widget.onFilterApplied(selectedStatuses, selectedTypes);
                    print(selectedStatuses);

                    // Close the drawer
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    widget.onFilterApplied([], []);
                    print(selectedStatuses);

                    // Close the drawer
                    Navigator.pop(context);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Clear Filters'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
