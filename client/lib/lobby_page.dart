import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'package:websocket/websocket.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({Key? key}) : super(key: key);

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final TextEditingController _sizeController = TextEditingController(text: '4');

  @override
  void initState() {
    super.initState();
    // Connect to a default local server (modify if needed)
    Provider.of<GameProvider>(context, listen: false).connect('ws://192.168.1.100:3000');
    // Request current room list
    Provider.of<GameProvider>(context, listen: false)._ws?.send('{"type":"requestRoomList","payload":{}}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MYNA Lobby')),
      body: Consumer<GameProvider>(
        builder: (context, gp, child) {
          // For simplicity we store room list in a static variable via broadcast; here we just show a placeholder.
          return Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Room size:'),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _sizeController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final size = int.tryParse(_sizeController.text) ?? 4;
                      gp._ws?.send('{"type":"createRoom","payload":{"desiredSize":$size}}');
                    },
                    child: const Text('Create'),
                  ),
                ],
              ),
              const Divider(height: 30),
              const Text('Available rooms (auto‑updated):'),
              Expanded(
                child: ListView.builder(
                  itemCount: gp.roomList?.length ?? 0,
                  itemBuilder: (context, idx) {
                    final room = gp.roomList![idx];
                    return ListTile(
                      title: Text('Room ${room['roomId'].substring(0, 8)}'),
                      subtitle: Text('Size ${room['desiredSize']}, ${room['playerCount']} players, ${room['status']}'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          gp._ws?.send('{"type":"joinRoom","payload":{"roomId":"${room['roomId']}"}}');
                        },
                        child: const Text('Join'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
