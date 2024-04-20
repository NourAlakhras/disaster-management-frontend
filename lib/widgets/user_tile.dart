import 'package:flutter/material.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/utils/enums.dart';

class UserTile extends StatelessWidget {
  final User user;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  const UserTile({
    Key? key,
    required this.user,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(user.username),
      subtitle: Text('Type: ${user.type}'),
      trailing: PopupMenuButton(
        itemBuilder: (BuildContext context) {
          switch (user.status) {
            case Status.PENDING:
              return [
                PopupMenuItem(
                  child: Text('Approve'),
                  onTap: onApprove,
                ),
                PopupMenuItem(
                  child: Text('Reject'),
                  onTap: onReject,
                ),
              ];
            case Status.AVAILABLE:
            case Status.ASSIGNED:
            case Status.INACTIVE:
            case Status.REJECTED:
              return [
                PopupMenuItem(
                  child: Text('Edit'),
                  onTap: onEdit,
                ),
                PopupMenuItem(
                  child: Text('Delete'),
                  onTap: onDelete,
                ),
              ];
            default:
              return []; // Return an empty list for any other status
          }
        },
      ),
      onTap: onViewDetails,
    );
  }
}
