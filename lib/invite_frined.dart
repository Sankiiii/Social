import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class InviteFriendsPage extends StatelessWidget {
  const InviteFriendsPage({Key? key}) : super(key: key);

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
                'Invite Friends',
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
                      Colors.purple.shade400,
                      Colors.deepPurple.shade700,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_add,
                        size: 100,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Invite Your Friends',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Earn rewards when friends join!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
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
                _buildInvitationCodeSection(),
                SizedBox(height: 24),
                _buildShareMethodsSection(context),
                SizedBox(height: 24),
                _buildReferralRewardsSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCodeSection() {
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
              'Your Invite Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'FRIEND123',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.copy, color: Colors.purple.shade700),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: 'FRIEND123'));
                    
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareMethodsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share Invite',
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
              _buildShareButton(
                icon: Icons.message,
                color: Colors.green,
                label: 'SMS',
                onTap: () => _shareViaSMS(context),
              ),
              SizedBox(width: 12),
              _buildShareButton(
                icon: Icons.email,
                color: Colors.blue,
                label: 'Email',
                onTap: () => _shareViaEmail(context),
              ),
              SizedBox(width: 12),
              _buildShareButton(
                icon: Icons.share,
                color: Colors.orange,
                label: 'Other Apps',
                onTap: () => _shareViaOtherApps(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralRewardsSection() {
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
              'Referral Rewards',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            _buildRewardItem(
              icon: Icons.card_giftcard,
              title: 'Invite a Friend',
              subtitle: 'Get 20rs credit',
            ),
            SizedBox(height: 8),
            // _buildRewardItem(
            //   icon: Icons.monetization_on,
            //   title: '3 Friends Joined',
            //   subtitle: 'Unlock Premium Features',
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.purple.shade700,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
    );
  }

  void _shareViaSMS(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      'Hey! Join me on this awesome app. Use my invite code: FRIEND123',
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  void _shareViaEmail(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      'Subject: Join me on this awesome app!\n\n'
      'Hey there!\n\n'
      'I\'m using this great app and thought you might like it. '
      'Use my invite code: FRIEND123',
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  void _shareViaOtherApps(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      'Hey! Check out this awesome app. Use my invite code: FRIEND123',
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }
}