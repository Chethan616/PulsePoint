import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulsepoint_v2/models/activity_record.dart';
import 'package:pulsepoint_v2/models/blood_donation_record.dart';
import 'package:pulsepoint_v2/providers/activity_service.dart';
import 'package:pulsepoint_v2/providers/donation_service.dart';
import 'package:pulsepoint_v2/providers/theme_provider.dart';
import 'package:pulsepoint_v2/debug_firestore.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late ActivityService _activityService;
  late DonationService _donationService;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _activityService = ActivityService();
    _donationService = DonationService();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // This forces a rebuild when tab changes to update icon colors
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    // Debug Firestore collections
    FirestoreDebugger.checkCollections();
    FirestoreDebugger.findSimilarCollections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = isDark ? Color(0xFFBB86FC) : Color(0xFF6200EE);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          indicatorWeight: 3.0,
          labelColor: primaryColor,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          tabs: [
            Tab(
              text: "Activities",
              icon: Icon(
                Icons.history,
                color: _tabController.index == 0 ? primaryColor : null,
                size: 26,
              ),
            ),
            Tab(
              text: "Donations",
              icon: Icon(
                Icons.favorite,
                color: _tabController.index == 1 ? primaryColor : null,
                size: 26,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivitiesTab(isDark),
          _buildDonationsTab(isDark),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab(bool isDark) {
    return StreamBuilder<List<ActivityRecord>>(
      stream: _activityService.getUserActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading activities: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'No activity yet',
            subtitle: 'Your activities will appear here',
            isDark: isDark,
          );
        }

        return _buildActivityList(activities, context);
      },
    );
  }

  Widget _buildDonationsTab(bool isDark) {
    print('Building Donations Tab... isDark: $isDark');
    return StreamBuilder<List<BloodDonationRecord>>(
      // This stream uses Firebase indexed query:
      // - donorId (Ascending) + requestDate (Descending)
      // - recipientId (Ascending) + requestDate (Descending)
      // See firestore_indexes.md for setup instructions
      stream: _donationService.getUserDonations(),
      builder: (context, snapshot) {
        print('Donations StreamBuilder state: ${snapshot.connectionState}');
        if (snapshot.hasError) {
          print('Donations StreamBuilder ERROR: ${snapshot.error}');
          print('Donations StreamBuilder ERROR STACK: ${snapshot.stackTrace}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Donations StreamBuilder is waiting...');
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading donations: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final donations = snapshot.data ?? [];
        print('Found ${donations.length} donations for the current user');

        if (donations.isNotEmpty) {
          print('Sample donation data:');
          print('ID: ${donations[0].id}');
          print('Blood Type: ${donations[0].bloodType}');
          print('Status: ${donations[0].status}');
          print('Donor: ${donations[0].donorName} (${donations[0].donorId})');
          print(
              'Recipient: ${donations[0].recipientName} (${donations[0].recipientId})');
        }

        if (donations.isEmpty) {
          print('No donations found for the current user');
          return _buildEmptyState(
            icon: Icons.favorite,
            title: 'No donation history',
            subtitle: 'Your blood donation history will appear here',
            isDark: isDark,
          );
        }

        return _buildDonationList(donations, context, isDark);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: isDark ? Color(0xFFBB86FC) : Theme.of(context).primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white30 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _createTestDonation() async {
    // First run troubleshooting
    try {
      final troubleshootResult = await _donationService.troubleshootDonations();
      print('=== TROUBLESHOOTING RESULTS ===');
      troubleshootResult.forEach((key, value) {
        print('$key: $value');
      });
      print('==============================');

      // If the collection doesn't exist or we have index errors, show a warning
      if (troubleshootResult['collectionExists'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('⚠️ Collection blood_donations does not exist!')));
        return;
      }

      if (troubleshootResult['indexedQueryWorking'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('⚠️ Index issues detected. Check console logs.')));
      }

      // Proceed with test donation creation
      print('Creating a test donation record...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No authenticated user found');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: No authenticated user')));
        return;
      }

      // Create a test donation with the current user as both donor and recipient
      final String? donationId = await _donationService.createDonationRequest(
        donorId: currentUser.uid,
        donorName: currentUser.displayName ?? 'Test Donor',
        recipientName: 'Test Recipient',
        donorPhone: '555-0123',
        recipientPhone: '555-4567',
        bloodType: 'O+',
        location: 'Test Location',
        hospitalName: 'Test Hospital',
        notes: 'This is a test donation created for debugging',
      );

      if (donationId != null) {
        print('Successfully created test donation: $donationId');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Test donation created: $donationId')));
      } else {
        print('Failed to create test donation');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Failed to create test donation')));
      }
    } catch (e) {
      print('Error in debug process: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildDonationList(
      List<BloodDonationRecord> donations, BuildContext context, bool isDark) {
    print('Building donation list with ${donations.length} donations');

    // Group donations by month
    Map<String, List<BloodDonationRecord>> groupedDonations = {};

    for (var donation in donations) {
      final date = DateFormat('yyyy-MM').format(donation.requestDate);
      print('Donation ID: ${donation.id}, Month: $date');
      if (!groupedDonations.containsKey(date)) {
        groupedDonations[date] = [];
      }
      groupedDonations[date]!.add(donation);
    }

    final sortedMonths = groupedDonations.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    print('Grouped into ${sortedMonths.length} months');
    for (var month in sortedMonths) {
      print('Month: $month, Count: ${groupedDonations[month]!.length}');
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: sortedMonths.length,
      itemBuilder: (context, index) {
        final month = sortedMonths[index];
        final monthDonations = groupedDonations[month]!;
        print(
            'Building month section: $month with ${monthDonations.length} donations');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthHeader(month, context),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: monthDonations.length,
              itemBuilder: (context, idx) {
                print('Building donation item $idx in month $month');
                return _buildDonationItem(monthDonations[idx], context, isDark);
              },
            ),
            if (index < sortedMonths.length - 1) Divider(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildMonthHeader(String monthStr, BuildContext context) {
    final date = DateTime.parse('$monthStr-01');
    final displayDate = DateFormat('MMMM yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        displayDate,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildDonationItem(
      BloodDonationRecord donation, BuildContext context, bool isDark) {
    final isRecipient =
        FirebaseAuth.instance.currentUser?.uid == donation.recipientId;
    final date = DateFormat('MMM d, yyyy').format(donation.requestDate);
    final otherPersonName =
        isRecipient ? donation.donorName : donation.recipientName;

    final statusColor = _getDonationStatusColor(donation.status, context);

    // Highlight completed donations with a special border
    final bool isCompleted = donation.status == DonationStatus.completed;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCompleted
            ? BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black12,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.4),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isCompleted
                ? Icons.favorite
                : (isRecipient ? Icons.arrow_downward : Icons.arrow_upward),
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isRecipient
                    ? "Received from $otherPersonName"
                    : "Donated to $otherPersonName",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isCompleted)
              Tooltip(
                message: 'Life saved through donation',
                child: Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 18,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    donation.bloodType,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                SizedBox(width: 8),
                Chip(
                  label: Text(
                    donation.statusDisplayName,
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor:
                      _getDonationStatusColor(donation.status, context),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            SizedBox(height: 4),
            Text("Hospital: ${donation.hospitalName}"),
            SizedBox(height: 4),
            Row(
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                if (donation.completionDate != null) ...[
                  Text(
                    " • Completed: ",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(donation.completionDate!),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          _showDonationDetailsDialog(donation, isRecipient, context);
        },
      ),
    );
  }

  void _showDonationDetailsDialog(
      BloodDonationRecord donation, bool isRecipient, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final otherPersonName =
        isRecipient ? donation.donorName : donation.recipientName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Donation Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Status', donation.statusDisplayName, isDark),
              _buildDetailItem('Blood Type', donation.bloodType, isDark),
              _buildDetailItem(
                  isRecipient ? 'Donor' : 'Recipient', otherPersonName, isDark),
              _buildDetailItem('Hospital', donation.hospitalName, isDark),
              _buildDetailItem('Location', donation.location, isDark),
              _buildDetailItem(
                  'Request Date',
                  DateFormat('MMM d, yyyy').format(donation.requestDate),
                  isDark),
              if (donation.completionDate != null)
                _buildDetailItem(
                    'Completion Date',
                    DateFormat('MMM d, yyyy').format(donation.completionDate!),
                    isDark),
              if (donation.notes != null && donation.notes!.isNotEmpty)
                _buildDetailItem('Notes', donation.notes!, isDark),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (donation.status == DonationStatus.requested && !isRecipient)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _donationService.acceptDonationRequest(donation.id);
              },
              child: Text('Accept Request'),
            ),
          if (donation.status == DonationStatus.accepted)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _donationService.completeDonation(donation.id);
              },
              child: Text('Mark Completed'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDonationStatusColor(DonationStatus status, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (status) {
      case DonationStatus.requested:
        return isDark ? Color(0xFFFFD54F) : Colors.amber;
      case DonationStatus.accepted:
        return isDark ? Color(0xFF64B5F6) : Colors.blue;
      case DonationStatus.completed:
        return isDark ? Color(0xFF81C784) : Colors.green;
      case DonationStatus.declined:
        return isDark ? Color(0xFFE57373) : Colors.red;
      case DonationStatus.cancelled:
        return isDark ? Color(0xFFBDBDBD) : Colors.grey;
    }
  }

  Widget _buildActivityList(
      List<ActivityRecord> activities, BuildContext context) {
    // Group activities by date
    Map<String, List<ActivityRecord>> groupedActivities = {};

    for (var activity in activities) {
      final date = DateFormat('yyyy-MM-dd').format(activity.timestamp);
      if (!groupedActivities.containsKey(date)) {
        groupedActivities[date] = [];
      }
      groupedActivities[date]!.add(activity);
    }

    final sortedDates = groupedActivities.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dateActivities = groupedActivities[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(date, context),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: dateActivities.length,
              itemBuilder: (context, idx) =>
                  _buildActivityItem(dateActivities[idx], context),
            ),
            if (index < sortedDates.length - 1) Divider(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String dateStr, BuildContext context) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    String displayDate;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      displayDate = 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      displayDate = 'Yesterday';
    } else {
      displayDate = DateFormat('MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        displayDate,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildActivityItem(ActivityRecord activity, BuildContext context) {
    final time = DateFormat('h:mm a').format(activity.timestamp);

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                _buildActivityTypeIndicator(activity.type, context),
              ],
            ),
            SizedBox(height: 8),
            Text(
              activity.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              activity.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTypeIndicator(ActivityType type, BuildContext context) {
    IconData icon;
    String label;

    switch (type) {
      case ActivityType.bloodDonation:
        icon = Icons.volunteer_activism;
        label = 'Donation';
        break;
      case ActivityType.bloodRequest:
        icon = Icons.bloodtype;
        label = 'Request';
        break;
      case ActivityType.hospitalVisit:
        icon = Icons.local_hospital;
        label = 'Hospital';
        break;
    }

    Color iconColor = _getActivityColor(type, context);
    Color bgColor = Theme.of(context).brightness == Brightness.dark
        ? iconColor.withOpacity(0.3)
        : iconColor.withOpacity(0.2);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: iconColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(ActivityType type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case ActivityType.bloodDonation:
        return isDark ? Color(0xFFFF8FAB) : Color(0xFFFF3D71);
      case ActivityType.bloodRequest:
        return isDark ? Color(0xFFD0BCFF) : Color(0xFF9C27B0);
      case ActivityType.hospitalVisit:
        return isDark ? Color(0xFF8CEFE0) : Color(0xFF03DAC5);
    }
  }
}
