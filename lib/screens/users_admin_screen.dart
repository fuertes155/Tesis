import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/patient.dart';
import '../widgets/page_container.dart';
import '../widgets/home_header.dart';
import '../widgets/stat_card.dart';
import '../core/theme/app_theme.dart';
part 'users_admin_screen_state.dart';

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => UsersAdminScreenState();
}
