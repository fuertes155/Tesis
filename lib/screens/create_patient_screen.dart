import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
part 'create_patient_screen_state.dart';

class CreatePatientScreen extends StatefulWidget {
  const CreatePatientScreen({super.key});

  @override
  State<CreatePatientScreen> createState() => CreatePatientScreenState();
}
