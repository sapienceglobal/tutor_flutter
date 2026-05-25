import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../../services/live_class_service.dart';

class LiveMeetingScreen extends StatefulWidget {
  final String classId;
  final Map<String, dynamic> config;

  const LiveMeetingScreen({
    Key? key,
    required this.classId,
    required this.config,
  }) : super(key: key);

  @override
  State<LiveMeetingScreen> createState() => _LiveMeetingScreenState();
}

class _LiveMeetingScreenState extends State<LiveMeetingScreen> {
  final _jitsiMeet = JitsiMeet();
  final _liveClassService = LiveClassService();

  @override
  void initState() {
    super.initState();
    _joinMeeting();
  }

  void _joinMeeting() async {
    try {
      var options = JitsiMeetConferenceOptions(
        room: widget.config['meetingNumber'],
        configOverrides: {
          "startWithAudioMuted": true,
          "startWithVideoMuted": true,
          "prejoinPageEnabled": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: widget.config['userName'],
          email: widget.config['userEmail'],
        ),
      );

      _jitsiMeet.join(
        options,
        JitsiMeetEventListener(
          conferenceJoined: (url) {
            debugPrint("Conference Joined: $url");
            _liveClassService.markAttendance(widget.classId);
          },
          conferenceTerminated: (url, error) {
            debugPrint("Conference Terminated: $url, error: $error");
            if (mounted) Navigator.pop(context);
          },
        ),
      );
    } catch (error) {
      debugPrint("Error joining meeting: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not join meeting: $error")),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              "Joining Live Class...",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
