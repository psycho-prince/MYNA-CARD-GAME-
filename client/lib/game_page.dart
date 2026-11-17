import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';

class GamePage extends StatelessWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gp = Provider.of<GameProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MYNA Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => gp._ws?.send('{"type":"requestState","payload":{"gameId":"${gp.gameId}"}}'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Opponent info (card counts)
          Expanded(
            flex: 2,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: gp.state?.hands.entries
                      .where((e) => e.key != gp.playerId)
                      .map((e) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                const Icon(Icons.person),
                                Text('Player'),
                                Text('Cards: ${e.value is int ? e.value : (e.value as List).length}'),
                              ],
                            ),
                          ))
                      .toList() ??
                  [],
            ),
          ),
          // Discard pile (top card)
          if (gp.state?.discardTop != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: CardWidget(card: gp.state!.discardTop!),
            ),
          // Team melds (visible to all)
          const Divider(),
          const Text('Team Melds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: gp.teamMelds.length,
              itemBuilder: (ctx, i) => CardWidget(card: gp.teamMelds[i]),
            ),
          ),
          const Divider(),
          // Player meld area (sets/rummy)
          const Text('Your Melds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 80,
            child: DragTarget<CardModel>(
              onAccept: (card) => gp.addToMeld(card),
              builder: (context, candidateData, rejectedData) => Container(
                color: candidateData.isNotEmpty ? Colors.green[200] : Colors.grey[300],
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: gp.myMelds.length,
                  itemBuilder: (ctx, i) => CardWidget(card: gp.myMelds[i]),
                ),
              ),
            ),
          ),
          const Divider(),
          // Player hand (draggable cards)
          const Text('Your Hand', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            flex: 3,
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.7,
              ),
              itemCount: gp.myHand.length,
              itemBuilder: (ctx, i) {
                final card = gp.myHand[i];
                return LongPressDraggable<CardModel>(
                  data: card,
                  feedback: Material(
                    child: CardWidget(card: card, elevation: 8),
                  ),
                  childWhenDragging: Opacity(opacity: 0.3, child: CardWidget(card: card)),
                  child: CardWidget(card: card),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CardWidget extends StatelessWidget {
  final CardModel card;
  final double elevation;
  const CardWidget({Key? key, required this.card, this.elevation = 2}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = card.rank == 'Joker' ? Colors.orangeAccent : Colors.white;
    return Card(
      elevation: elevation,
      color: color,
      child: SizedBox(
        width: 40,
        height: 60,
        child: Center(
          child: Text(
            card.code,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
