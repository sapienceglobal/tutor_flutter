import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/batch_service.dart';
import '../../../services/attendance_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/constants.dart';

class TutorAttendanceScreen extends StatefulWidget {
  const TutorAttendanceScreen({super.key});

  @override
  State<TutorAttendanceScreen> createState() => _TutorAttendanceScreenState();
}

class _TutorAttendanceScreenState extends State<TutorAttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // State variables
  List<dynamic> _batches = [];
  bool _isLoadingBatches = true;
  String? _selectedBatchId;
  Map<String, dynamic>? _selectedBatchDetails;
  bool _isLoadingBatchDetails = false;

  // Mark Attendance State
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _attendanceMap = {}; // studentId -> 'Present' / 'Absent' / 'Late' / 'Excused'
  Map<String, TextEditingController> _remarksControllers = {};
  String _searchQuery = '';

  // History State
  List<dynamic> _historyRecords = [];
  bool _isLoadingHistory = false;
  bool _hasLoadedHistory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadBatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _remarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == 1 && !_hasLoadedHistory && _selectedBatchId != null) {
      _loadHistory();
    }
  }

  Future<void> _loadBatches() async {
    setState(() => _isLoadingBatches = true);
    try {
      final res = await BatchService.getAllBatches();
      if (res['success'] == true) {
        setState(() {
          _batches = res['batches'] ?? [];
          if (_batches.isNotEmpty) {
            _selectedBatchId = _batches.first['_id'];
          }
        });
        if (_selectedBatchId != null) {
          await _loadBatchDetails(_selectedBatchId!);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load batches: $e')),
      );
    } finally {
      setState(() => _isLoadingBatches = false);
    }
  }

  Future<void> _loadBatchDetails(String batchId) async {
    setState(() {
      _isLoadingBatchDetails = true;
      _attendanceMap.clear();
      for (var ctrl in _remarksControllers.values) {
        ctrl.dispose();
      }
      _remarksControllers.clear();
    });

    try {
      final res = await BatchService.getBatchById(batchId);
      if (res['success'] == true) {
        setState(() {
          _selectedBatchDetails = res['batch'];
          final students = _selectedBatchDetails?['students'] ?? [];
          for (var s in students) {
            final sId = s['_id'].toString();
            _attendanceMap[sId] = 'Present'; // default
            _remarksControllers[sId] = TextEditingController();
          }
        });
        
        // If history tab is selected, reload history too
        if (_tabController.index == 1) {
          _loadHistory();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load batch students: $e')),
      );
    } finally {
      setState(() => _isLoadingBatchDetails = false);
    }
  }

  Future<void> _loadHistory() async {
    if (_selectedBatchId == null) return;
    final token = await AuthService.getToken();
    if (token == null) return;

    setState(() {
      _isLoadingHistory = true;
      _hasLoadedHistory = true;
    });

    try {
      final res = await AttendanceService.getBatchAttendance(
        token: token,
        batchId: _selectedBatchId!,
      );
      if (res['success'] == true) {
        setState(() {
          _historyRecords = res['records'] ?? [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: $e')),
      );
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _markAll(String status) {
    setState(() {
      for (var key in _attendanceMap.keys) {
        _attendanceMap[key] = status;
      }
    });
  }

  Future<void> _submitAttendance() async {
    if (_selectedBatchId == null) return;
    final token = await AuthService.getToken();
    if (token == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final List<Map<String, dynamic>> recordsList = [];
      _attendanceMap.forEach((studentId, status) {
        recordsList.add({
          'studentId': studentId,
          'status': status,
          'remarks': _remarksControllers[studentId]?.text.trim() ?? '',
        });
      });

      final res = await AttendanceService.markAttendance(
        token: token,
        batchId: _selectedBatchId!,
        date: _selectedDate.toIso8601String(),
        records: recordsList,
      );

      Navigator.pop(context); // dismiss loader

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance sheet saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _hasLoadedHistory = false;
        if (_tabController.index == 1) {
          _loadHistory();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to save attendance')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // dismiss loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving attendance: $e')),
      );
    }
  }

  void _editFromHistory(dynamic historyDoc) {
    final docDate = DateTime.parse(historyDoc['date']);
    final records = historyDoc['records'] as List? ?? [];
    
    setState(() {
      _selectedDate = docDate;
      for (var record in records) {
        final sObj = record['studentId'];
        if (sObj != null) {
          final sId = sObj['_id'].toString();
          _attendanceMap[sId] = record['status'] ?? 'Present';
          if (_remarksControllers.containsKey(sId)) {
            _remarksControllers[sId]?.text = record['remarks'] ?? '';
          } else {
            _remarksControllers[sId] = TextEditingController(text: record['remarks'] ?? '');
          }
        }
      }
      _tabController.animateTo(0);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded attendance for ${DateFormat('dd MMM yyyy').format(docDate)}. Edit and click Save.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance Register', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Batch Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _isLoadingBatches
                    ? const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()))
                    : _batches.isEmpty
                        ? const Text('No active batches found')
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBatchId,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                                items: _batches.map((batch) {
                                  return DropdownMenuItem<String>(
                                    value: batch['_id'],
                                    child: Text(
                                      batch['name'] ?? 'Unnamed Batch',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedBatchId = val;
                                      _hasLoadedHistory = false;
                                    });
                                    _loadBatchDetails(val);
                                  }
                                },
                              ),
                            ),
                          ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Mark Attendance'),
                  Tab(text: 'History Logs'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarkAttendanceTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildMarkAttendanceTab() {
    if (_isLoadingBatchDetails) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_selectedBatchDetails == null) {
      return const Center(child: Text('Please select a batch to start marking attendance'));
    }

    final students = _selectedBatchDetails?['students'] as List? ?? [];
    final filteredStudents = students.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Controls: Date Selector + Mark All
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () => _markAll('Present'),
                        child: const Text('All Present', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () => _markAll('Absent'),
                        child: const Text('All Absent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search Input
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Students List
        Expanded(
          child: filteredStudents.isEmpty
              ? const Center(child: Text('No students found matching your query.'))
              : ListView.builder(
                  itemCount: filteredStudents.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    final sId = student['_id'].toString();
                    final sName = student['name'] ?? 'Student';
                    final sEmail = student['email'] ?? '';
                    final sImg = student['profileImage'] ?? student['avatar'];
                    final currentStatus = _attendanceMap[sId] ?? 'Present';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [AppThemeDesign.cardShadow],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: sImg != null ? NetworkImage(sImg) : null,
                              child: sImg == null ? const Icon(Icons.person) : null,
                            ),
                            title: Text(sName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(sEmail, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ),
                          // Radio Options
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                            child: Row(
                              children: [
                                _buildStatusButton(sId, 'Present', Colors.green, currentStatus),
                                const SizedBox(width: 8),
                                _buildStatusButton(sId, 'Absent', Colors.red, currentStatus),
                                const SizedBox(width: 8),
                                _buildStatusButton(sId, 'Late', Colors.orange, currentStatus),
                                const SizedBox(width: 8),
                                _buildStatusButton(sId, 'Excused', Colors.blue, currentStatus),
                              ],
                            ),
                          ),
                          // Remarks optional input
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                            child: TextField(
                              controller: _remarksControllers[sId],
                              decoration: InputDecoration(
                                hintText: 'Add optional remark...',
                                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Action Button
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _submitAttendance,
              child: const Text('Save Attendance Sheet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton(String studentId, String status, Color color, String currentStatus) {
    final isSelected = currentStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _attendanceMap[studentId] = status;
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: isSelected ? color : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_historyRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No attendance history logs found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _historyRecords.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final record = _historyRecords[index];
        final date = DateTime.parse(record['date']);
        final students = record['records'] as List? ?? [];
        
        final presentCount = students.where((s) => s['status'] == 'Present' || s['status'] == 'Late').length;
        final totalCount = students.length;
        final attendanceRate = totalCount > 0 ? (presentCount / totalCount) * 100 : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ExpansionTile(
            title: Text(
              DateFormat('EEEE, dd MMM yyyy').format(date),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              'Rate: ${attendanceRate.toStringAsFixed(1)}% ($presentCount/$totalCount present)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            childrenPadding: const EdgeInsets.all(16),
            expandedAlignment: Alignment.topLeft,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Students Attendance Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  TextButton.icon(
                    onPressed: () => _editFromHistory(record),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Sheet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(),
              ...students.map((stud) {
                final studentDetails = stud['studentId'];
                final sName = studentDetails != null ? studentDetails['name'] : 'Student';
                final sStatus = stud['status'] ?? 'N/A';
                final sRemark = stud['remarks'] ?? '';

                Color statusColor = Colors.grey;
                if (sStatus == 'Present') statusColor = Colors.green;
                if (sStatus == 'Absent') statusColor = Colors.red;
                if (sStatus == 'Late') statusColor = Colors.orange;
                if (sStatus == 'Excused') statusColor = Colors.blue;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sName, style: const TextStyle(fontSize: 13)),
                            if (sRemark.isNotEmpty)
                              Text('Remark: $sRemark', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          sStatus,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
