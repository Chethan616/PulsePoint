import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkedInSection extends StatelessWidget {
  final List<Map<String, String>> linkedInProfiles = [
    {
      'name': 'Chethan Krishna Manikonda',
      'url':
          'https://www.linkedin.com/in/chethan-krishna-manikonda-33561628a/?originalSubdomain=in',
    },
    {
      'name': 'Jayashish Muppur',
      'url':
          'https://www.linkedin.com/in/jayashish-muppur?originalSubdomain=in',
    },
    {
      'name': 'Viswendra Choudary Ameneni',
      'url':
          'https://www.linkedin.com/in/viswendra-choudary-ameneni-0a265b330?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app',
    },
    {
      'name': 'Karthikeya Gorre',
      'url':
          'https://www.linkedin.com/in/karthikeya-gorre-53413a290?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app',
    },
    {
      'name': 'Mohith Bodanampati',
      'url':
          'https://www.linkedin.com/in/mohith-bodanampati-35670b277?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LinkedIn Profiles'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[800]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 20),
            _buildLinkedInLinks(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meet Our Team',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Here are the LinkedIn profiles of our amazing team members.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedInLinks() {
    return Column(
      children: linkedInProfiles.map((profile) {
        return InkWell(
          onTap: () async {
            final url = profile['url']!;
            if (await canLaunch(url)) {
              await launch(url);
            } else {
              throw 'Could not launch $url';
            }
          },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[300]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link,
                  size: 30,
                  color: Colors.white,
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    profile['name']!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
