/* Author: Tobi Vollebregt */

/* based on code from GlobalSynced.{cpp,h} */

#include "StdAfx.h"
#include "TeamHandler.h"

#include <cstring>

#include "Game/GameSetup.h"
#include "Lua/LuaGaia.h"
#include "Sim/Misc/GlobalConstants.h"
#include "mmgr.h"
#include "Util.h"
#include "LogOutput.h"
#include "GlobalUnsynced.h"
#include "Platform/errorhandler.h"
//#include "ExternalAI/SkirmishAIData.h"
//#include "ExternalAI/IAILibraryManager.h"

CR_BIND(CTeamHandler, );

CR_REG_METADATA(CTeamHandler, (
	CR_MEMBER(gaiaTeamID),
	CR_MEMBER(gaiaAllyTeamID),
	CR_MEMBER(teams),
	//CR_MEMBER(allyTeams),
	CR_RESERVED(64)
));


CTeamHandler* teamHandler;


CTeamHandler::CTeamHandler():
	gaiaTeamID(-1),
	gaiaAllyTeamID(-1)
{
}


CTeamHandler::~CTeamHandler()
{
}


void CTeamHandler::LoadFromSetup(const CGameSetup* setup)
{
	const bool useLuaGaia = CLuaGaia::SetConfigString(setup->luaGaiaStr);

	assert(setup->teamStartingData.size() <= MAX_TEAMS);
	teams.resize(setup->teamStartingData.size());

	for (size_t i = 0; i < teams.size(); ++i) {
		// TODO: this loop body could use some more refactoring
		CTeam* team = Team(i);
		*team = setup->teamStartingData[i];
		team->teamNum = i;
		SetAllyTeam(i, team->teamAllyteam);
	}

	allyTeams = setup->allyStartingData;
	assert(setup->allyStartingData.size() <= MAX_TEAMS);
	if (useLuaGaia) {
		// Gaia adjustments
		gaiaTeamID = static_cast<int>(teams.size());
		gaiaAllyTeamID = static_cast<int>(allyTeams.size());

		// Setup the gaia team
		CTeam team;
		team.color[0] = 255;
		team.color[1] = 255;
		team.color[2] = 255;
		team.color[3] = 255;
		team.gaia = true;
		team.teamNum = gaiaTeamID;
		team.StartposMessage(float3(0.0, 0.0, 0.0));
		team.teamAllyteam = gaiaAllyTeamID;
		teams.push_back(team);

		for (std::vector< ::AllyTeam >::iterator it = allyTeams.begin(); it != allyTeams.end(); ++it)
		{
			it->allies.push_back(false); // enemy to everyone
		}
		::AllyTeam allyteam;
		allyteam.allies.resize(allyTeams.size()+1,false); // everyones enemy
		allyteam.allies[gaiaTeamID] = true; // peace with itself
		allyTeams.push_back(allyteam);
	}
}

void CTeamHandler::GameFrame(int frameNum)
{
	if (!(frameNum & 31)) {
		for (int a = 0; a < ActiveTeams(); ++a) {
			Team(a)->ResetFrameVariables();
		}
		for (int a = 0; a < ActiveTeams(); ++a) {
			Team(a)->SlowUpdate();
		}
	}
}
