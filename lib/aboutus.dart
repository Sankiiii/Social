import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'About Us',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade800,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: AssetImage('assets/images/bg_load_img.png'), // Replace with your logo
                        backgroundColor: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Public Pulse',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCompanyStorySection(),
                SizedBox(height: 24),
                _buildMissionSection(),
                SizedBox(height: 24),
                _buildTeamSection(),
                SizedBox(height: 24),
                _buildContactInfoSection(),
                SizedBox(height: 24),
                _buildSocialMediaSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyStorySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Our Story',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
            SizedBox(height: 12),
            Text(
             'Our app enables citizens to easily report civic issues like garbage, potholes, and damaged infrastructure.'
             'It connects them with municipal authorities through a transparent platform for tracking and resolving complaints.'
             'Authorities can prioritize and manage resources efficiently with real-time updates.'
             'Citizens receive timely feedback, building trust and accountability.'
             'Together, we aim to create cleaner, safer, and more livable cities.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Our Mission',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
            SizedBox(height: 12),
            _buildMissionPoint(
              icon: Icons.lightbulb_outline,
              text: 'Foster collaboration and accountability to create cleaner, safer, and more sustainable cities.',
            ),
            SizedBox(height: 8),
            _buildMissionPoint(
              icon: Icons.people_outline,
              text: 'Equip authorities with tools to prioritize complaints, allocate resources effectively, and resolve issues faster.',
            ),
            SizedBox(height: 8),
            _buildMissionPoint(
              icon: Icons.support_outlined,
              text: 'Foster cleaner, safer, and more livable urban spaces through collaboration and accountability.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionPoint({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.deepPurple.shade700,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Our Team',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTeamMember(
                name: 'Shivam Chavan',
                role: 'Frontend Dev',
                imagePath: 'assets/images/john.jpg', // Replace with actual paths
              ),
              SizedBox(width: 16),
              _buildTeamMember(
                name: 'Prashant Ramraje',
                role: 'Designer',
                imagePath: 'assets/images/jane.jpg',

              ),
              SizedBox(width: 16),
              _buildTeamMember(
                name: 'Yadnyesh More',
                role: 'Backend Dev',
                imagePath: 'assets/images/mike.jpg',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMember({
    required String name,
    required String role,
    required String imagePath,
  }) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              imagePath,
              height: 150,
              width: 150,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
            SizedBox(height: 12),
            _buildContactItem(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: 'support@social.com',
              onTap: () => _launchEmail(),
            ),
            SizedBox(height: 8),
            _buildContactItem(
              icon: Icons.phone_outlined,
              title: 'Phone',
              subtitle: '+91 809766758',
              onTap: () => _launchDialer(),
            ),
            SizedBox(height: 8),
            _buildContactItem(
              icon: Icons.location_on_outlined,
              title: 'Address',
              subtitle: '123 Tech Lane, Innovation City, ST 12345',
              onTap: () => _openMaps(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.deepPurple.shade700,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: Colors.deepPurple.shade700),
      onTap: onTap,
    );
  }

  Widget _buildSocialMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Follow Us',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialMediaButton(
              icon: Icons.facebook,
              color: Colors.blue,
              onTap: () => _launchSocialMedia('facebook'),
            ),
            _buildSocialMediaButton(
              icon: FontAwesomeIcons.whatsapp,
              color: Colors.black,
              onTap: () => _launchSocialMedia('tiktok'),
            ),
            _buildSocialMediaButton(
              icon: FontAwesomeIcons.instagram,
              color: Colors.pink,
              onTap: () => _launchSocialMedia('instagram'),
            ),
            _buildSocialMediaButton(
              icon: FontAwesomeIcons.twitter,
              color: Colors.lightBlue,
              onTap: () => _launchSocialMedia('twitter'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialMediaButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 36, color: color),
      onPressed: onTap,
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri.parse('mailto:support@puplicpulse.com');
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchDialer() async {
    final Uri phoneUri = Uri.parse('tel:+8097667158');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _openMaps() async {
    final Uri mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=123+Tech+Lane+Innovation+City');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri);
    }
  }

  void _launchSocialMedia(String platform) async {
    String url = '';
    switch (platform) {
      case 'facebook':
        url = 'https://facebook.com/yourcompany';
        break;
      case 'tiktok':
        url = 'https://tiktok.com/@yourcompany';
        break;
      case 'instagram':
        url = 'https://instagram.com/yourcompany';
        break;
      case 'twitter':
        url = 'https://twitter.com/yourcompany';
        break;
    }

    final Uri socialUri = Uri.parse(url);
    if (await canLaunchUrl(socialUri)) {
      await launchUrl(socialUri);
    }
  }
}