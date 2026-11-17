import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:websocket/websocket.dart';
import 'dart:convert';

class CardModel {
  final String rank; // e.g., 'A', '2' .. 'K' or 'Joker'
  final String? suit; // null for Joker
  final String code; // unique identifier, e.g., 'A♠', 'JK1a'

  CardModel({required this.rank, this.suit, required this.code});

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      rank: json['rank'] as String,
      suit: json['suit'] as String?,
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'suit': suit,
        'code': code,
      };

  @override
  String toString() => code;
}

class GameState {
  final String gameId;
  final Map<String, dynamic> hands; // playerId -> List<CardModel> or int length
  final String currentTurn;
  final CardModel? discardTop;
  final Map<String, int> scores;

  GameState({
    required this.gameId,
    required this.hands,
    required this.currentTurn,
    this.discardTop,
    required this.scores,
  });

  factory GameState.fromJson(Map<String, dynamic> json) {
    CardModel? top;
    if (json['discardTop'] != null) {
      top = CardModel.fromJson(json['discardTop'] as Map<String, dynamic>);
    }
    return GameState(
      gameId: json['gameId'] as String,
      hands: json['hands'] as Map<String, dynamic>,
      currentTurn: json['currentTurn'] as String,
      discardTop: top,
      scores: Map<String, int>.from(json['scores'] as Map),
    );
  }
}

class GameProvider extends ChangeNotifier {
  // WebSocket connection
  WebSocket? _ws;
  String? playerId;
  String? gameId;
  GameState? state;
  List<dynamic>? roomList;
  List<CardModel> myHand = [];
  List<CardModel> myMelds = [];
  List<CardModel> teamMelds = [];

  // WebSocket connection
  WebSocket? _ws;
  String? playerId;
  String? gameId;
  GameState? state;
  List<CardModel> myHand = [];
  List<CardModel> myMelds = [];
  List<CardModel> teamMelds = [];

  void connect(String serverUrl) {
    _ws = WebSocket(serverUrl);
    _ws!.listen(_handleMessage, onDone: () {
      // reconnect logic could be added
    });
  }

  void _handleMessage(dynamic message) {
    final data = message is String ? message : '';
    try {
      final Map<String, dynamic> json = jsonDecode(data);
      final type = json['type'];
      final payload = json['payload'];
      switch (type) {
        case 'welcome':
          playerId = payload['playerId'];
          break;
        case 'roomList':
          // handled by lobby separately via a stream
          break;
        case 'roomList':
          // payload is a list of rooms
          roomList = List<dynamic>.from(payload as List);
          notifyListeners();
          break;
          gameId = payload['gameId'];
          myHand = (payload['hand'] as List)
              .map((c) => CardModel.fromJson(c as Map<String, dynamic>))
              .toList();
          notifyListeners();
          break;
        case 'gameUpdate':
          state = GameState.fromJson(payload as Map<String, dynamic>);
          // update own hand if included
          if (state!.hands.containsKey(playerId)) {
            final handData = state!.hands[playerId!];
            if (handData is List) {
              myHand = handData
                  .map((c) => CardModel.fromJson(c as Map<String, dynamic>))
                  .toList();
            }
          }
          notifyListeners();
          break;
        default:
          break;
      }
    } catch (e) {
      // ignore malformed messages
    }
  }

  void createRoom(int size) {
    final msg = {
      'type': 'createRoom',
      'payload': {'desiredSize': size}
    };
    _ws?.send(jsonEncode(msg));
  }

  void joinRoom(String roomId) {
    final msg = {'type': 'joinRoom', 'payload': {'roomId': roomId}};
    _ws?.send(jsonEncode(msg));
  }

  void startGame() {
    final msg = {'type': 'startGame', 'payload': {}};
    _ws?.send(jsonEncode(msg));
  }

  void playCard(CardModel card) {
    final msg = {
      'type': 'playCard',
      'payload': {'gameId': gameId, 'card': card.code}
    };
    _ws?.send(jsonEncode(msg));
  }

  // Simple meld handling – just send the card to server; server can be extended later.
  void addToMeld(CardModel card) => playCard(card);
}
