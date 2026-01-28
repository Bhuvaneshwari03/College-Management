import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:college_management/features/auth/presentation/pages/login_page.dart';
import 'package:college_management/features/dashboard/dashboard_card.dart';
import 'package:college_management/features/faculty/presentation/pages/faculty_details_page.dart';
import 'package:college_management/features/students/presentation/pages/add_student_page.dart';
import 'package:college_management/features/timetable/presentation/pages/timetable_page.dart';
import 'package:college_management/features/attendance/attendance_page.dart';
import 'package:college_management/features/mentee_details/mentee_details_page.dart';
import 'package:college_management/features/internals/internals_page.dart';

class FacultyDashboard extends StatelessWidget {
  const FacultyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade900,
              Colors.grey.shade50,
              Colors.grey.shade50,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.logout, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.userChanges(),
                      builder: (context, snapshot) {
                        final displayName =
                            snapshot.data?.displayName ?? 'Faculty';
                        return Text(
                          'Hello $displayName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Grid Section
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      padding: const EdgeInsets.all(24),
                      children: [
                        DashboardCard(
                          title: 'Faculty Details',
                          icon: Icons.person_rounded,
                          color: Colors.blueAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FacultyDetailsPage(),
                            ),
                          ),
                        ),
                        DashboardCard(
                          title: 'Add Student',
                          icon: Icons.person_add_rounded,
                          color: Colors.green,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddStudentPage(),
                            ),
                          ),
                        ),
                        DashboardCard(
                          title: 'Timetable',
                          icon: Icons.schedule_rounded,
                          color: Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TimetablePage(),
                            ),
                          ),
                        ),
                        DashboardCard(
                          title: 'Attendance',
                          icon: Icons.calendar_today_rounded,
                          color: Colors.teal,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AttendancePage(),
                            ),
                          ),
                        ),
                        DashboardCard(
                          title: 'Mentee Details',
                          icon: Icons.folder_special_rounded,
                          color: Colors.indigo,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MenteeDetailsPage(),
                            ),
                          ),
                        ),
                        DashboardCard(
                          title: 'Internal Marks',
                          icon: Icons.grade_rounded,
                          color: Colors.redAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InternalsPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
