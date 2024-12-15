import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Help Center',
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
                  child: Icon(
                    Icons.support_agent,
                    size: 100,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle('How Can We Help?'),
                SizedBox(height: 16),
                _buildContactCard(
                  context,
                  icon: Icons.phone,
                  title: 'Phone Support',
                  subtitle: 'Speak with our support team',
                  onTap: _launchDialer,
                ),
                SizedBox(height: 16),
                _buildContactCard(
                  context,
                  icon: Icons.email_outlined,
                  title: 'Email Support',
                  subtitle: 'Send us a detailed message',
                  onTap: _launchEmail,
                ),
                SizedBox(height: 16),
                SizedBox(height: 24),
                _buildSectionTitle('Additional Resources'),
                SizedBox(height: 16),
                _buildResourceTile(
                  icon: Icons.help_outline,
                  title: 'Frequently Asked Questions',
                  onTap: _openFAQs,
                ),
                _buildResourceTile(
                  icon: Icons.article_outlined,
                  title: 'Support Documentation',
                  onTap: _openSupportDocs,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.deepPurple.shade700,
            size: 30,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildResourceTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple.shade700),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.open_in_new),
      onTap: onTap,
    );
  }

  void _launchDialer() async {
    final Uri phoneUri = Uri.parse('tel:+18007878767');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _launchEmail() async {
    final Uri emailUri = Uri.parse('mailto:support@example.com');
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchLiveChat() async {
    final Uri chatUri = Uri.parse('https://example.com/live-chat');
    if (await canLaunchUrl(chatUri)) {
      await launchUrl(chatUri);
    }
  }

  void _openFAQs() async {
    final Uri faqUri = Uri.parse('https://example.com/faqs');
    if (await canLaunchUrl(faqUri)) {
      await launchUrl(faqUri);
    }
  }

  void _openSupportDocs() async {
    final Uri docsUri = Uri.parse('https://example.com/support-docs');
    if (await canLaunchUrl(docsUri)) {
      await launchUrl(docsUri);
    }
  }
}