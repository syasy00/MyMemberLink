import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_member_link/myconfig.dart';
import '../mydrawer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:webview_flutter/webview_flutter.dart';
import '../webview_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  List subscriptionHistory = [];
  List membershipPackages = [];
  bool isLoading = true;
  String? email;

  String toTitleCase(String text) {
    if (text == null || text.isEmpty) return '';
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUserData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData(); // Reload when dependencies change (e.g., returning from another screen)
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      email = prefs.getString('useremail');
    });
    await Future.wait([
      _loadSubscriptionHistory(),
      _loadMembershipPackages(),
    ]);
  }

  Future<void> _loadSubscriptionHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
            "${MyConfig.servername}/memberlink/api/get_user_subscription_details_by_id.php?email=$email"),
      );

      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          subscriptionHistory = data['status'] == 'success' ? data['data'] : [];
          isLoading = false;
        });
      } else {
        print("HTTP Error: ${response.statusCode}");
        setState(() {
          subscriptionHistory = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading subscription history: $e");
      setState(() {
        subscriptionHistory = [];
        isLoading = false;
      });
    }
  }

  Future<void> _loadMembershipPackages() async {
    try {
      final response = await http.get(
        Uri.parse(
            "${MyConfig.servername}/memberlink/api/get_membership_type.php"),
      );

      print("Membership Packages Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          membershipPackages = data['status'] == 'success' ? data['data'] : [];
        });
      } else {
        print("HTTP Error: ${response.statusCode}");
        setState(() {
          membershipPackages = [];
        });
      }
    } catch (e) {
      print("Error loading membership packages: $e");
      print("Stack trace: ${StackTrace.current}");
      setState(() {
        membershipPackages = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Manage Subscription',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 5,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: MyDrawer(activePage: "Subscription"),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics:
                    AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentSubscription(),
                      SizedBox(height: 24),
                      _buildAvailablePackages(),
                      SizedBox(height: 24),
                      _buildSubscriptionHistory(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentSubscription() {
    var currentSubscription = subscriptionHistory.firstWhere(
      (subscription) =>
          subscription['subscription_status']?.toString().toLowerCase() ==
          'active',
      orElse: () => null,
    );

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Subscription',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (currentSubscription != null)
                  TextButton(
                    onPressed: () => _showCancelConfirmation(int.parse(
                        currentSubscription['subscription_id'].toString())),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            if (currentSubscription != null) ...[
              _buildSubscriptionDetail(
                'Plan',
                toTitleCase(
                    currentSubscription['membership_details']['name'] ?? ''),
              ),
              _buildSubscriptionDetail(
                'Status',
                toTitleCase(currentSubscription['subscription_status'] ?? ''),
                isStatus: true,
              ),
              _buildSubscriptionDetail(
                'Expires',
                currentSubscription['subscription_end_date'] ?? '',
              ),
            ] else
              Text(
                'No active subscription',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetail(String label, String value,
      {bool isStatus = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          if (isStatus)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: value.toLowerCase() == 'active'
                    ? Colors.green[50]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: value.toLowerCase() == 'active'
                      ? Colors.green[700]
                      : Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailablePackages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Packages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: membershipPackages.length,
            itemBuilder: (context, index) {
              final package = membershipPackages[index];
              return Container(
                width: MediaQuery.of(context).size.width * 0.8,
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            toTitleCase(package['membership_type_name'] ??
                                'Unknown Package'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'MYR ${package['membership_type_price'] ?? '0.00'}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => _showPackageDetails(package),
                            child: Text(
                              'View More',
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _subscribeToPlan(package),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Subscribe'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscription History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        if (subscriptionHistory.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 16),
                Text(
                  'No subscription history found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: subscriptionHistory.length,
            itemBuilder: (context, index) {
              final subscription = subscriptionHistory[index];
              final membershipDetails =
                  subscription['membership_details'] ?? {};
              final paymentDetails = subscription['payment_details'] ?? {};

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              toTitleCase(
                                  membershipDetails['name']?.toString() ??
                                      'Unknown Package'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (subscription['subscription_status']
                                              ?.toString()
                                              .toLowerCase() ??
                                          '') ==
                                      'active'
                                  ? Colors.green[50]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              toTitleCase(subscription['subscription_status']
                                      ?.toString() ??
                                  'Unknown'),
                              style: TextStyle(
                                color: (subscription['subscription_status']
                                                ?.toString()
                                                .toLowerCase() ??
                                            '') ==
                                        'active'
                                    ? Colors.green[700]
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildHistoryDetail(
                                  'Start',
                                  subscription['subscription_start_date']
                                          ?.toString() ??
                                      'N/A',
                                ),
                              ),
                              Expanded(
                                child: _buildHistoryDetail(
                                  'End',
                                  subscription['subscription_end_date']
                                          ?.toString() ??
                                      'N/A',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: _buildHistoryDetail(
                                  'Amount',
                                  'RM${membershipDetails['price']?.toString() ?? '0.00'}',
                                ),
                              ),
                              if (paymentDetails['payment_date'] != null)
                                Expanded(
                                  child: _buildHistoryDetail(
                                    'Paid',
                                    paymentDetails['payment_date']
                                            ?.toString() ??
                                        'N/A',
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: _buildHistoryDetail(
                                  'Status',
                                  toTitleCase(paymentDetails['payment_status']
                                          ?.toString() ??
                                      'N/A'),
                                ),
                              ),
                              Expanded(
                                  child:
                                      SizedBox()), // Empty space for alignment
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildHistoryDetail(String label, String value) {
    // Intercept and replace status before rendering
    if (label == 'Status' && value.toLowerCase() == 'completed') {
      value = 'Paid';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      String cleanUrl = url.replaceAll(r'\\/', '/').replaceAll(r'\/', '/');

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: cleanUrl,
            title: 'Payment',
          ),
        ),
      );

      setState(() {
        isLoading = true;
      });
      await _loadUserData();
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  Future<void> _subscribeToPlan(Map<String, dynamic> package) async {
    try {
      // Get user email from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? adminEmail = prefs.getString('useremail');

      if (adminEmail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User email not found. Please login again.')),
        );
        return;
      }

      // Safely extract and convert package values
      String membershipTypeId =
          (package['membership_type_id'] ?? '0').toString();
      String membershipDuration =
          (package['membership_type_duration'] ?? '0').toString();
      String membershipPrice =
          (package['membership_type_price'] ?? '0').toString();

      print("Extracted Package Data:");
      print("ID: $membershipTypeId (${membershipTypeId.runtimeType})");
      print(
          "Duration: $membershipDuration (${membershipDuration.runtimeType})");
      print("Price: $membershipPrice (${membershipPrice.runtimeType})");

      // Calculate subscription dates
      DateTime now = DateTime.now();
      String startDate = now.toIso8601String().split('T')[0];
      int duration = int.tryParse(membershipDuration) ?? 0;
      String endDate =
          now.add(Duration(days: duration)).toIso8601String().split('T')[0];

      // Convert price to cents (RM to sen)
      double price = double.tryParse(membershipPrice) ?? 0;
      String amountInCents = (price * 100).round().toString();

      // Prepare request data with explicit String types
      Map<String, String> requestData = {
        'admin_email': adminEmail,
        'membership_type_id': membershipTypeId,
        'subscription_start_date': startDate,
        'subscription_end_date': endDate,
        'subscription_status': 'pending',
        'amount': amountInCents,
      };

      print("\nRequest Data:");
      requestData.forEach((key, value) {
        print("$key: $value (${value.runtimeType})");
      });

      print("\nJSON Encoded Request:");
      print(json.encode(requestData));

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Make API call
      final response = await http.post(
        Uri.parse(
            "${MyConfig.servername}/memberlink/api/add_membership_subscriptions.php"),
        body: json.encode(requestData),
        headers: {'Content-Type': 'application/json'},
      );

      print("\nAPI Response:");
      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");

      // Hide loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final paymentUrl = data['data']['payment_url'];

          try {
            // Clean the URL and create Uri
            String cleanUrl =
                paymentUrl.replaceAll(r'\\/', '/').replaceAll(r'\/', '/');
            print('Attempting to launch URL: $cleanUrl'); // Debug print

            // Navigate to WebView screen
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WebViewScreen(
                  url: cleanUrl,
                  title: 'Payment',
                ),
              ),
            );

            // Check if payment was successful and reload data
            if (result == true) {
              // Reload subscription data
              setState(() {
                isLoading = true;
              });

              // Load all necessary data
              await _loadSubscriptionHistory();
              await _loadMembershipPackages();
              await _loadUserData();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Payment successful! Your subscription has been updated.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            // Hide loading indicator if still showing
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            print('Error launching payment URL: $e');
            // Show error dialog with copy option
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Payment Link'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Unable to open payment page.'),
                    SizedBox(height: 8),
                    Text('Please try again or contact support.'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                ],
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(data['message'] ?? 'Failed to create subscription')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error. Please try again.')),
        );
      }
    } catch (e) {
      print("Error creating subscription: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  Future<void> _showCancelConfirmation(int subscriptionId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.blue[50]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Dialog Title
                Text(
                  'Cancel Subscription',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                SizedBox(height: 12),

                // Dialog Description
                Text(
                  'Are you sure you want to cancel your subscription? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5, // Line height for better readability
                  ),
                ),
                SizedBox(height: 20),

                // Action Buttons (Aligned horizontally)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // No, Keep It Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue[700],
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12), // Adjusted padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.blue[700]!),
                          ),
                        ),
                        child: Text(
                          'No, Keep It',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Slightly smaller font size
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        width: 12), // Slightly reduced space between buttons

                    // Yes, Cancel Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          _cancelSubscription(subscriptionId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.red.withOpacity(0.3),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12), // Adjusted padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Yes, Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Slightly smaller font size
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelSubscription(int subscriptionId) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      // Get user email from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? adminEmail = prefs.getString('useremail');

      if (adminEmail == null) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User email not found. Please login again.')),
        );
        return;
      }

      // Prepare request data
      Map<String, dynamic> requestData = {
        'admin_email': adminEmail,
        'subscription_id': subscriptionId,
      };

      // Make API call
      final response = await http.post(
        Uri.parse(
            "${MyConfig.servername}/memberlink/api/cancel_subscription.php"),
        body: json.encode(requestData),
        headers: {'Content-Type': 'application/json'},
      );

      // Hide loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Reload subscription data
          setState(() {
            isLoading = true;
          });
          await _loadUserData();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Subscription cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to cancel subscription');
        }
      } else {
        throw Exception('Failed to connect to server');
      }
    } catch (e) {
      // Hide loading if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPackageDetails(Map<String, dynamic> package) {
    String name = toTitleCase(
        package['membership_type_name']?.toString() ?? 'Unknown Package');
    String price = package['membership_type_price']?.toString() ?? '0';
    String description = package['membership_type_description']?.toString() ??
        'No description provided.';
    String benefits =
        package['membership_type_benefit']?.toString() ?? 'No benefits listed.';
    String duration = package['membership_type_duration']?.toString() ?? 'N/A';
    String terms =
        package['membership_type_terms']?.toString() ?? 'No terms specified.';

    bool agreeToTerms = false; // Checkbox state

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                      Text(
                        'RM$price',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13, // Smaller font size for description
                      color: Colors.grey[600],
                    ),
                  ),
                  Divider(height: 24, thickness: 1, color: Colors.grey[300]),

                  // Benefits Section
                  Text(
                    'Member Advantages',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 12),
                  ..._buildBenefitsList(benefits, color: Colors.blue[600]),

                  // Duration Section
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Duration:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.blue[800],
                        ),
                      ),
                      Text(
                        "$duration days",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  // Terms Section
                  SizedBox(height: 20),
                  Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    terms,
                    style: TextStyle(
                      fontSize: 12, // Smaller font size for terms
                      color: Colors.grey[700],
                    ),
                  ),

                  // Checkbox for Terms Agreement
                  SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        activeColor: Colors.blue[700],
                        value: agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            agreeToTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'I agree to the terms and conditions.',
                          style: TextStyle(
                            fontSize: 12, // Smaller font size for text
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Buttons Section
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancel Button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          foregroundColor: Colors.red[600],
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14, // Adjusted font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Subscribe Button
                      ElevatedButton(
                        onPressed: agreeToTerms
                            ? () {
                                Navigator.pop(context);
                                _subscribeToPlan(package);
                              }
                            : null, // Disable button if not agreed
                        style: ElevatedButton.styleFrom(
                          backgroundColor: agreeToTerms
                              ? Colors.blue[700]
                              : Colors.grey[400], // Adjust button color
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Subscribe',
                          style: TextStyle(
                            fontSize: 14, // Adjusted font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBenefitsList(String benefits, {Color? color}) {
    List<String> benefitList = benefits.split(',');
    return benefitList
        .map((benefit) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: color ?? Colors.blue[700],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit.trim(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }
}
