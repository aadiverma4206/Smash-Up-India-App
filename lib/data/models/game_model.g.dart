part of 'game_model.dart';

Map<String, dynamic> _$GameRosterPlayerModelToJson(
        GameRosterPlayerModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'name': instance.name,
      'profileImageUrl': instance.profileImageUrl,
      'team': instance.team,
      'position': instance.position,
      'ovr': instance.ovr,
    };

Map<String, dynamic> _$GameModelToJson(GameModel instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'clubId': instance.clubId,
      'clubName': instance.clubName,
      'courtId': instance.courtId,
      'courtName': instance.courtName,
      'matchDate': instance.matchDate,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'status': instance.status,
      'format': instance.format,
      'perPlayerFee': instance.perPlayerFee,
      'maxPlayers': instance.maxPlayers,
      'currentPlayers': instance.currentPlayers,
      'skillRequirement': instance.skillRequirement,
      'privacy': instance.privacy,
      'creatorId': instance.creatorId,
      'creatorRoleName': instance.creatorRoleName,
      'createdByPlayer': instance.createdByPlayer,
      'teamAScore': instance.teamAScore,
      'teamBScore': instance.teamBScore,
      'winnerTeam': instance.winnerTeam,
      'userTeam': instance.userTeam,
      'userPosition': instance.userPosition,
      'description': instance.description,
      'waitlistPosition': instance.waitlistPosition,
      'roster': instance.roster,
      'videoPlaybackUrl': instance.videoPlaybackUrl,
      'entryFee': instance.entryFee,
      'cancellationReason': instance.cancellationReason,
      'cancelledBy': instance.cancelledBy,
      'rejectionReason': instance.rejectionReason,
    };
