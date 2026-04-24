import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/patient.dart';
import '../widgets/page_container.dart';
import '../widgets/home_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/premium_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state_view.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_decorations.dart';
import '../providers/data_providers.dart';
import '../providers/api_providers.dart';
part 'users_admin_screen_state.dart';

class UsersAdminScreen extends ConsumerStatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  ConsumerState<UsersAdminScreen> createState() => UsersAdminScreenState();
}
