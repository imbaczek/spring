/*
	Copyright (c) 2008 Robin Vobruba <hoijui.quaero@gmail.com>

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "ExternalAI/SkirmishAIData.h"

#include "creg/STL_Map.h"

CR_BIND(SkirmishAIData,);

CR_REG_METADATA(SkirmishAIData, (
	// from TeamController
	CR_MEMBER(name),
	CR_MEMBER(team),
	// from SkirmishAIBase
	CR_MEMBER(hostPlayer),
	CR_ENUM_MEMBER(status),
	// from SkirmishAIData
	CR_MEMBER(shortName),
	CR_MEMBER(version),
	CR_MEMBER(optionKeys),
	CR_MEMBER(options),
	CR_MEMBER(isLuaAI),
//	CR_MEMBER(currentStats),
	CR_RESERVED(32)
));
