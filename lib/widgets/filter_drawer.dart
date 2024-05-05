import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FilterDrawerWidget extends StatefulWidget {
  final Function(Map<String, List<dynamic>> selectedCriteria) onFilterApplied;
  final List<FilterCriterion> criteriaList;

  const FilterDrawerWidget({
    Key? key,
    required this.onFilterApplied,
    required this.criteriaList,
    required String title,
  }) : super(key: key);

  @override
  State<FilterDrawerWidget> createState() => _FilterDrawerWidgetState();
}

class _FilterDrawerWidgetState extends State<FilterDrawerWidget> {
  Map<String, List<dynamic>> selectedCriteria = {};

  @override
  void initState() {
    super.initState();

    // Initialize the selectedCriteria map with empty lists for each criterion
    for (var criterion in widget.criteriaList) {
      selectedCriteria[criterion.name] = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color.fromARGB(255, 39, 44, 50),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 65),
              height: 50,
              child: const ListTile(
                title: Text(
                  'Filter Options',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.criteriaList.length,
              itemBuilder: (context, index) {
                final criterion = widget.criteriaList[index];
                return ExpansionTile(
                  title: Text(
                    criterion.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  children: criterion.options
                      .map(
                        (option) => CheckboxListTile(
                          title: Text(
                            option.toString().split('.').last.toLowerCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          value: selectedCriteria[criterion.name]!
                              .contains(option),
                          onChanged: (value) {
                            setState(() {
                              if (value != null && value) {
                                selectedCriteria[criterion.name]!.add(option);
                              } else {
                                selectedCriteria[criterion.name]!
                                    .remove(option);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    widget.onFilterApplied(selectedCriteria);
                    print(selectedCriteria);

                    // Close the drawer
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Clear the selected options for each criterion
                      for (var criterion in widget.criteriaList) {
                        selectedCriteria[criterion.name] = [];
                      }
                      widget.onFilterApplied(selectedCriteria);
                      print(selectedCriteria);

                      // Close the drawer
                      Navigator.pop(context);
                    });
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

class FilterCriterion {
  final String name;
  final List<dynamic> options;

  FilterCriterion({required this.name, required this.options});
}
