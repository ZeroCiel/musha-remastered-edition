# MgmtStubs.cpp
// Symbol stubs for missing static members/functions in MgmtServer link.
// These provide definitions for things that are declared in headers
// but whose full implementations live in other server components
// (LataleGameServer, etc.) not linked into MgmtServer.

#include "stdafx.h"
#include "CAutoLock.h"

// CAutoLock static member definition (CRITICAL_SECTION CAutoLock::m_cs)
CRITICAL_SECTION CAutoLock::m_cs;
