// TODO: move this out of Sim, this is rendering code!

#include "StdAfx.h"
#include "LineDrawer.h"
#if !defined HEADLESS
#include "Game/UI/CommandColors.h"
#endif // !defined HEADLESS
#include "GlobalUnsynced.h"

CLineDrawer lineDrawer;


CLineDrawer::CLineDrawer()
{
	stippleTimer = 0.0f;
}


void CLineDrawer::UpdateLineStipple()
{
#if !defined HEADLESS
	stippleTimer += (gu->lastFrameTime * cmdColors.StippleSpeed());
	stippleTimer = fmod(stippleTimer, (16.0f / 20.0f));
#endif // !defined HEADLESS
}


void CLineDrawer::SetupLineStipple()
{
#if !defined HEADLESS
	const unsigned int stipPat = (0xffff & cmdColors.StipplePattern());
	if ((stipPat != 0x0000) && (stipPat != 0xffff)) {
		lineStipple = true;
	} else {
		lineStipple = false;
		return;
	}
	const unsigned int fullPat = (stipPat << 16) | (stipPat & 0x0000ffff);
	const int shiftBits = 15 - (int(stippleTimer * 20.0f) % 16);
	glLineStipple(cmdColors.StippleFactor(), (fullPat >> shiftBits));
#endif // !defined HEADLESS
}
