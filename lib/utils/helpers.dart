import 'package:flutter_3/utils/enums.dart';


String userTypeToString(UserType userType) {
  switch (userType) {
    case UserType.REGULAR:
      return 'Regular';
    case UserType.ADMIN:
      return 'Admin';
    default:
      return '';
  }
}


String statusToString(Status status) {
  switch (status) {
    case Status.AVAILABLE:
      return 'Available';
    case Status.PENDING:
      return 'Pending';
    case Status.ASSIGNED:
      return 'Assigned';
    case Status.INACTIVE:
      return 'Inactive';
    case Status.REJECTED:
      return 'Rejected';
    default:
      return '';
  }

  
}
