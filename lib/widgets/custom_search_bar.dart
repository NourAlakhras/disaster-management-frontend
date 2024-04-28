// import 'package:flutter/material.dart';

// /// Flutter code sample for [SearchBar].

// void main() => runApp(const SearchBar());

// class CustomSearchBar extends StatefulWidget {
//   const CustomSearchBar({super.key});

//   @override
//   State<CustomSearchBar> createState() => _CustomSearchBarState();
// }

// class _CustomSearchBarState extends State<CustomSearchBar> {
//   bool isDark = false;

//   @override
//   Widget build(BuildContext context) {

//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: SearchAnchor(
//           builder: (BuildContext context, SearchController controller) {
//         return SearchBar(
//           controller: controller,
//           padding: const MaterialStatePropertyAll<EdgeInsets>(
//               EdgeInsets.symmetric(horizontal: 16.0)),
//           onTap: () {
//             controller.openView();
//           },
//           onChanged: (_) {
//             controller.openView();
//           },
//           leading: const Icon(Icons.search),

//         );
//       }, suggestionsBuilder:
//               (BuildContext context, SearchController controller) {
//         return List<ListTile>.generate(5, (int index) {
//           final String item = 'Robot $index';
//           return ListTile(
//             title: Text(item),
//             onTap: () {
//               setState(() {
//                 controller.closeView(item);
//               });
//             },
//           );
//         });
//       }),
//     );
//   }
// }
//
import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,

  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color.fromARGB(144, 41, 48, 56),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.009),
            spreadRadius: 2,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search, color: Colors.white),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
                labelStyle: TextStyle(color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          
                    IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              // Open the drawer when filter icon is clicked
              Scaffold.of(context).openEndDrawer();})
        ],
      ),
    );
  }
}

// CustomSearchBar(
//   controller: _searchController,
//   onChanged: _filterUsers,
//   onStatusFilterPressed: _showStatusFilterDialog,
//   onTypeFilterPressed: _showTypeFilterDialog,
// )
