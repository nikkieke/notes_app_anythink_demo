import 'package:flutter/material.dart';

import '../../models/app_user.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 14});

  final AppUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = user.photoUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      foregroundImage: photo != null ? NetworkImage(photo) : null,
      child: Text(
        user.initial,
        style: TextStyle(fontSize: radius, fontWeight: FontWeight.w600),
      ),
    );
  }
}
