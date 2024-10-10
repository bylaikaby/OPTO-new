function [methodinfo,structs,enuminfo]=son32prototypes;
%SON32PROTOTYPES Create structures to define interfaces found in 'Son'.

%This function was generated by loadlibrary.m parser version 1.1.6.13 on Wed Jan 17 10:55:39 2007
%perl options:'Son.i -outfile=son32prototypes.m'
ival={cell(1,0)}; % change 0 to the actual number of functions to preallocate the data.
fcns=struct('name',ival,'calltype',ival,'LHS',ival,'RHS',ival,'alias',ival);
structs=[];enuminfo=[];fcnNum=1;
% void WINAPI SONInitFiles ( void ); 
fcns.name{fcnNum}='SONInitFiles'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}=[];fcnNum=fcnNum+1;
% void WINAPI SONCleanUp ( void ); 
fcns.name{fcnNum}='SONCleanUp'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}=[];fcnNum=fcnNum+1;
% short WINAPI SONOpenOldFile ( TpCStr name , int iOpenMode ); 
fcns.name{fcnNum}='SONOpenOldFile'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'string', 'int32'};fcnNum=fcnNum+1;
% short WINAPI SONOpenNewFile ( TpCStr name , short fMode , WORD extra ); 
fcns.name{fcnNum}='SONOpenNewFile'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'string', 'int16', 'unit16'};fcnNum=fcnNum+1;
% BOOLEAN WINAPI SONCanWrite ( short fh ); 
fcns.name{fcnNum}='SONCanWrite'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% short WINAPI SONCloseFile ( short fh ); 
fcns.name{fcnNum}='SONCloseFile'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% short WINAPI SONEmptyFile ( short fh ); 
fcns.name{fcnNum}='SONEmptyFile'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% short WINAPI SONSetBuffSpace ( short fh ); 
fcns.name{fcnNum}='SONSetBuffSpace'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% short WINAPI SONGetFreeChan ( short fh ); 
fcns.name{fcnNum}='SONGetFreeChan'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% void WINAPI SONSetFileClock ( short fh , WORD usPerTime , WORD timePerADC ); 
fcns.name{fcnNum}='SONSetFileClock'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'uint16', 'unit16'};fcnNum=fcnNum+1;
% short WINAPI SONSetADCChan ( short fh , WORD chan , short sPhyCh , short dvd , long lBufSz , TpCStr szCom , TpCStr szTitle , float fRate , float scl , float offs , TpCStr szUnt ); 
fcns.name{fcnNum}='SONSetADCChan'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'uint16', 'int16', 'int16', 'int32', 'string', 'string', 'single', 'single', 'single', 'string'};fcnNum=fcnNum+1;
% short WINAPI SONSetADCMarkChan ( short fh , WORD chan , short sPhyCh , short dvd , long lBufSz , TpCStr szCom , TpCStr szTitle , float fRate , float scl , float offs , TpCStr szUnt , WORD points , short preTrig ); 
fcns.name{fcnNum}='SONSetADCMarkChan'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'uint16', 'int16', 'int16', 'int32', 'string', 'string', 'single', 'single', 'single', 'string', 'uint16', 'int16'};fcnNum=fcnNum+1;
% short WINAPI SONSetWaveChan ( short fh , WORD chan , short sPhyCh , TSTime dvd , long lBufSz , TpCStr szCom , TpCStr szTitle , float scl , float offs , TpCStr szUnt ); 
fcns.name{fcnNum}='SONSetWaveChan'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'uint16', 'int16', 'int32', 'int32', 'string', 'string', 'single', 'single', 'string'};fcnNum=fcnNum+1;
% short WINAPI SONSetWaveMarkChan ( short fh , WORD chan , short sPhyCh , TSTime dvd , long lBufSz , TpCStr szCom , TpCStr szTitle , float fRate , float scl , float offs , TpCStr szUnt , WORD points , short preTrig , int nTrace ); 
fcns.name{fcnNum}='SONSetWaveMarkChan'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'uint16', 'int16', 'int32', 'int32', 'string', 'string', 'single', 'single', 'single', 'string', 'uint16', 'int16', 'int32'};fcnNum=fcnNum+1;
% short WINAPI SONSetRealMarkChan ( short fh , WORD chan , short sPhyCh , long lBufSz , TpCStr szCom , TpCStr szTitle , float fRate , float min , float max , TpCStr szUnt , WORD points ); 
fcns.name{fcnNum}='SONSetRealMarkChan'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'uint16', 'int16', 'int32', 'string', 'string', 'single', 'single', 'single', 'string', 'uint16'};fcnNum=fcnNum+1;
% short WINAPI SONSetTextMarkChan ( short fh , WORD chan , short sPhyCh , long lBufSz , TpCStr szCom , TpCStr szTitle , float fRate , TpCStr szUnt , WORD points ); 
fcns.name{fcnNum}='SONSetTextMarkChan'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'uint16', 'int16', 'int32', 'string', 'string', 'single', 'string', 'uint16'};fcnNum=fcnNum+1;
% void WINAPI SONSetInitLow ( short fh , WORD chan , BOOLEAN bLow ); 
fcns.name{fcnNum}='SONSetInitLow'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'uint16', 'int16'};fcnNum=fcnNum+1;
% short WINAPI SONSetEventChan ( short fh , WORD chan , short sPhyCh , long lBufSz , TpCStr szCom , TpCStr szTitle , float fRate , TDataKind evtKind ); 
fcns.name{fcnNum}='SONSetEventChan'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'uint16', 'int16', 'int32', '', 'error', 'single', 'TDataKind'};fcnNum=fcnNum+1;
% short WINAPI SONSetBuffering ( short fh , int nChan , int nBytes ); 
fcns.name{fcnNum}='SONSetBuffering'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'int32', 'int32'};fcnNum=fcnNum+1;
% short WINAPI SONUpdateStart ( short fh ); 
fcns.name{fcnNum}='SONUpdateStart'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% void WINAPI SONSetFileComment ( short fh , WORD which , TpCStr szFCom ); 
fcns.name{fcnNum}='SONSetFileComment'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'error', 'error'};fcnNum=fcnNum+1;
% void WINAPI SONGetFileComment ( short fh , WORD which , TpStr pcFCom , short sMax ); 
fcns.name{fcnNum}='SONGetFileComment'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'int16'};fcnNum=fcnNum+1;
% void WINAPI SONSetChanComment ( short fh , WORD chan , TpCStr szCom ); 
fcns.name{fcnNum}='SONSetChanComment'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'error', 'error'};fcnNum=fcnNum+1;
% void WINAPI SONGetChanComment ( short fh , WORD chan , TpStr pcCom , short sMax ); 
fcns.name{fcnNum}='SONGetChanComment'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'int16'};fcnNum=fcnNum+1;
% void WINAPI SONSetChanTitle ( short fh , WORD chan , TpCStr szTitle ); 
fcns.name{fcnNum}='SONSetChanTitle'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'error', 'error'};fcnNum=fcnNum+1;
% void WINAPI SONGetChanTitle ( short fh , WORD chan , TpStr pcTitle ); 
fcns.name{fcnNum}='SONGetChanTitle'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'error', 'error'};fcnNum=fcnNum+1;
% void WINAPI SONGetIdealLimits ( short fh , WORD chan , TpFloat pfRate , TpFloat pfMin , TpFloat pfMax ); 
fcns.name{fcnNum}='SONGetIdealLimits'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'error', 'error'};fcnNum=fcnNum+1;
% WORD WINAPI SONGetusPerTime ( short fh ); 
fcns.name{fcnNum}='SONGetusPerTime'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='error'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% WORD WINAPI SONGetTimePerADC ( short fh ); 
fcns.name{fcnNum}='SONGetTimePerADC'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='error'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% void WINAPI SONSetADCUnits ( short fh , WORD chan , TpCStr szUnt ); 
fcns.name{fcnNum}='SONSetADCUnits'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'error', 'error'};fcnNum=fcnNum+1;
% void WINAPI SONSetADCOffset ( short fh , WORD chan , float offset ); 
fcns.name{fcnNum}='SONSetADCOffset'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'error', 'single'};fcnNum=fcnNum+1;
% void WINAPI SONSetADCScale ( short fh , WORD chan , float scale ); 
fcns.name{fcnNum}='SONSetADCScale'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'error', 'single'};fcnNum=fcnNum+1;
% void WINAPI SONGetADCInfo ( short fh , WORD chan , TpFloat scale , TpFloat offset , TpStr pcUnt , TpWORD points , TpShort preTrig ); 
fcns.name{fcnNum}='SONGetADCInfo'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'error', 'error', 'error', 'voidPtr'};fcnNum=fcnNum+1;
% void WINAPI SONGetExtMarkInfo ( short fh , WORD chan , TpStr pcUnt , TpWORD points , TpShort preTrig ); 
fcns.name{fcnNum}='SONGetExtMarkInfo'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'error', 'voidPtr'};fcnNum=fcnNum+1;
% short WINAPI SONWriteEventBlock ( short fh , WORD chan , TpSTime plBuf , long count ); 
fcns.name{fcnNum}='SONWriteEventBlock'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'int32'};fcnNum=fcnNum+1;
% short WINAPI SONWriteMarkBlock ( short fh , WORD chan , TpMarker pM , long count ); 
fcns.name{fcnNum}='SONWriteMarkBlock'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'int32'};fcnNum=fcnNum+1;
% TSTime WINAPI SONWriteADCBlock ( short fh , WORD chan , TpAdc psBuf , long count , TSTime sTime ); 
fcns.name{fcnNum}='SONWriteADCBlock'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'int32', 'int32'};fcnNum=fcnNum+1;
% short WINAPI SONWriteExtMarkBlock ( short fh , WORD chan , TpMarker pM , long count ); 
fcns.name{fcnNum}='SONWriteExtMarkBlock'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'int32'};fcnNum=fcnNum+1;
% short WINAPI SONSave ( short fh , int nChan , TSTime sTime , BOOLEAN bKeep ); 
fcns.name{fcnNum}='SONSave'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'int32', 'int32', 'error'};fcnNum=fcnNum+1;
% short WINAPI SONSaveRange ( short fh , int nChan , TSTime sTime , TSTime eTime ); 
fcns.name{fcnNum}='SONSaveRange'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'int32', 'int32', 'int32'};fcnNum=fcnNum+1;
% short WINAPI SONKillRange ( short fh , int nChan , TSTime sTime , TSTime eTime ); 
fcns.name{fcnNum}='SONKillRange'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'int32', 'int32', 'int32'};fcnNum=fcnNum+1;
% short WINAPI SONIsSaving ( short fh , int nChan ); 
%fcns.name{fcnNum}='SONIsSaving'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'int32'};fcnNum=fcnNum+1;
% DWORD WINAPI SONFileBytes ( short fh ); 
fcns.name{fcnNum}='SONFileBytes'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% DWORD WINAPI SONChanBytes ( short fh , WORD chan ); 
%fcns.name{fcnNum}='SONChanBytes'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'int16', 'error'};fcnNum=fcnNum+1;
% short WINAPI SONLatestTime ( short fh , WORD chan , TSTime sTime ); 
fcns.name{fcnNum}='SONLatestTime'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'error', 'int32'};fcnNum=fcnNum+1;
% short WINAPI SONCommitIdle ( short fh ); 
fcns.name{fcnNum}='SONCommitIdle'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% short WINAPI SONCommitFile ( short fh , BOOLEAN bDelete ); 
fcns.name{fcnNum}='SONCommitFile'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'error'};fcnNum=fcnNum+1;
% long WINAPI SONGetEventData ( short fh , WORD chan , TpSTime plTimes , long max , TSTime sTime , TSTime eTime , TpBOOL levLowP , TpFilterMask pFiltMask ); 
fcns.name{fcnNum}='SONGetEventData'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'int32', 'int32', 'int32', 'error', 'error'};fcnNum=fcnNum+1;
% long WINAPI SONGetMarkData ( short fh , WORD chan , TpMarker pMark , long max , TSTime sTime , TSTime eTime , TpFilterMask pFiltMask ); 
fcns.name{fcnNum}='SONGetMarkData'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'int32', 'int32', 'int32', 'error'};fcnNum=fcnNum+1;
% long WINAPI SONGetADCData ( short fh , WORD chan , TpAdc adcDataP , long max , TSTime sTime , TSTime eTime , TpSTime pbTime , TpFilterMask pFiltMask ); 
fcns.name{fcnNum}='SONGetADCData'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'int32', 'int32', 'int32', 'error', 'error'};fcnNum=fcnNum+1;
% long WINAPI SONGetExtMarkData ( short fh , WORD chan , TpMarker pMark , long max , TSTime sTime , TSTime eTime , TpFilterMask pFiltMask ); 
fcns.name{fcnNum}='SONGetExtMarkData'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'int32', 'int32', 'int32', 'error'};fcnNum=fcnNum+1;
% long WINAPI SONGetExtraDataSize ( short fh ); 
fcns.name{fcnNum}='SONGetExtraDataSize'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% int WINAPI SONGetVersion ( short fh ); 
fcns.name{fcnNum}='SONGetVersion'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% short WINAPI SONGetExtraData ( short fh , TpVoid buff , WORD bytes , WORD offset , BOOLEAN writeIt ); 
fcns.name{fcnNum}='SONGetExtraData'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'error', 'error'};fcnNum=fcnNum+1;
% short WINAPI SONSetMarker ( short fh , WORD chan , TSTime time , TpMarker pMark , WORD size ); 
fcns.name{fcnNum}='SONSetMarker'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'error', 'int32', 'error', 'error'};fcnNum=fcnNum+1;
% short WINAPI SONChanDelete ( short fh , WORD chan ); 
fcns.name{fcnNum}='SONChanDelete'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'int16', 'error'};fcnNum=fcnNum+1;
% TDataKind WINAPI SONChanKind ( short fh , WORD chan ); 
fcns.name{fcnNum}='SONChanKind'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='TDataKind'; fcns.RHS{fcnNum}={'int16', 'error'};fcnNum=fcnNum+1;
% TSTime WINAPI SONChanDivide ( short fh , WORD chan ); 
fcns.name{fcnNum}='SONChanDivide'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error'};fcnNum=fcnNum+1;
% WORD WINAPI SONItemSize ( short fh , WORD chan ); 
fcns.name{fcnNum}='SONItemSize'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='error'; fcns.RHS{fcnNum}={'int16', 'error'};fcnNum=fcnNum+1;
% TSTime WINAPI SONChanMaxTime ( short fh , WORD chan ); 
fcns.name{fcnNum}='SONChanMaxTime'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error'};fcnNum=fcnNum+1;
% TSTime WINAPI SONMaxTime ( short fh ); 
fcns.name{fcnNum}='SONMaxTime'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% TSTime WINAPI SONLastTime ( short fh , WORD wChan , TSTime sTime , TSTime eTime , TpVoid pvVal , TpMarkBytes pMB , TpBOOL pbMk , TpFilterMask pFiltMask ); 
fcns.name{fcnNum}='SONLastTime'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error', 'int32', 'int32', 'error', 'error', 'error', 'error'};fcnNum=fcnNum+1;
% TSTime WINAPI SONLastPointsTime ( short fh , WORD wChan , TSTime sTime , TSTime eTime , long lPoints , BOOLEAN bAdc , TpFilterMask pFiltMask ); 
fcns.name{fcnNum}='SONLastPointsTime'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error', 'int32', 'int32', 'int32', 'error', 'error'};fcnNum=fcnNum+1;
% long WINAPI SONFileSize ( short fh ); 
fcns.name{fcnNum}='SONFileSize'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% int WINAPI SONMarkerItem ( short fh , WORD wChan , TpMarker pBuff , int n , TpMarker pM , TpVoid pvData , BOOLEAN bSet ); 
fcns.name{fcnNum}='SONMarkerItem'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'int32', 'error', 'error', 'error'};fcnNum=fcnNum+1;
% int WINAPI SONFilter ( TpMarker pM , TpFilterMask pFM ); 
fcns.name{fcnNum}='SONFilter'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'error', 'error'};fcnNum=fcnNum+1;
% int WINAPI SONFControl ( TpFilterMask pFM , int layer , int item , int set ); 
fcns.name{fcnNum}='SONFControl'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'error', 'int32', 'int32', 'int32'};fcnNum=fcnNum+1;
% BOOLEAN WINAPI SONFEqual ( TpFilterMask pFiltMask1 , TpFilterMask pFiltMask2 ); 
fcns.name{fcnNum}='SONFEqual'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='error'; fcns.RHS{fcnNum}={'error', 'error'};fcnNum=fcnNum+1;
% int WINAPI SONFActive ( TpFilterMask pFM ); 
%fcns.name{fcnNum}='SONFActive'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'error'};fcnNum=fcnNum+1;
% long WINAPI SONFMode ( TpFilterMask pFM , long lNew ); 
fcns.name{fcnNum}='SONFMode'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'error', 'int32'};fcnNum=fcnNum+1;
% short WINAPI SONCreateFile ( TpCStr name , int nChannels , WORD extra ); 
fcns.name{fcnNum}='SONCreateFile'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int16'; fcns.RHS{fcnNum}={'error', 'int32', 'error'};fcnNum=fcnNum+1;
% int WINAPI SONMaxChans ( short fh ); 
fcns.name{fcnNum}='SONMaxChans'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16'};fcnNum=fcnNum+1;
% int WINAPI SONPhyChan ( short fh , WORD wChan ); 
fcns.name{fcnNum}='SONPhyChan'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error'};fcnNum=fcnNum+1;
% float WINAPI SONIdealRate ( short fh , WORD wChan , float fIR ); 
fcns.name{fcnNum}='SONIdealRate'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='single'; fcns.RHS{fcnNum}={'int16', 'error', 'single'};fcnNum=fcnNum+1;
% void WINAPI SONYRange ( short fh , WORD chan , TpFloat pfMin , TpFloat pfMax ); 
fcns.name{fcnNum}='SONYRange'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'error'};fcnNum=fcnNum+1;
% int WINAPI SONYRangeSet ( short fh , WORD chan , float fMin , float fMax ); 
fcns.name{fcnNum}='SONYRangeSet'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error', 'single', 'single'};fcnNum=fcnNum+1;
% int WINAPI SONMaxItems ( short fh , WORD chan ); 
fcns.name{fcnNum}='SONMaxItems'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error'};fcnNum=fcnNum+1;
% int WINAPI SONPhySz ( short fh , WORD chan ); 
fcns.name{fcnNum}='SONPhySz'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error'};fcnNum=fcnNum+1;
% int WINAPI SONBlocks ( short fh , WORD chan ); 
fcns.name{fcnNum}='SONBlocks'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error'};fcnNum=fcnNum+1;
% int WINAPI SONDelBlocks ( short fh , WORD chan ); 
fcns.name{fcnNum}='SONDelBlocks'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error'};fcnNum=fcnNum+1;
% int WINAPI SONSetRealChan ( short fh , WORD chan , short sPhyChan , TSTime dvd , long lBufSz , TpCStr szCom , TpCStr szTitle , float scale , float offset , TpCStr szUnt ); 
fcns.name{fcnNum}='SONSetRealChan'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error', 'int16', 'int32', 'int32', 'error', 'error', 'single', 'single', 'error'};fcnNum=fcnNum+1;
% TSTime WINAPI SONWriteRealBlock ( short fh , WORD chan , TpFloat pfBuff , long count , TSTime sTime ); 
fcns.name{fcnNum}='SONWriteRealBlock'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'int32', 'int32'};fcnNum=fcnNum+1;
% long WINAPI SONGetRealData ( short fh , WORD chan , TpFloat pfData , long max , TSTime sTime , TSTime eTime , TpSTime pbTime , TpFilterMask pFiltMask ); 
fcns.name{fcnNum}='SONGetRealData'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error', 'error', 'int32', 'int32', 'int32', 'error', 'error'};fcnNum=fcnNum+1;
% int WINAPI SONTimeDate ( short fh , TSONTimeDate * pTDGet , const TSONTimeDate * pTDSet ); 
fcns.name{fcnNum}='SONTimeDate'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'TSONTimeDatePtr', 'TSONTimeDatePtr'};fcnNum=fcnNum+1;
% double WINAPI SONTimeBase ( short fh , double dTB ); 
fcns.name{fcnNum}='SONTimeBase'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='double'; fcns.RHS{fcnNum}={'int16', 'double'};fcnNum=fcnNum+1;
% int WINAPI SONAppID ( short fh , TSONCreator * pCGet , const TSONCreator * pCSet ); 
fcns.name{fcnNum}='SONAppID'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'TSONCreatorPtr', 'TSONCreatorPtr'};fcnNum=fcnNum+1;
% int WINAPI SONChanInterleave ( short fh , WORD chan ); 
fcns.name{fcnNum}='SONChanInterleave'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'error'};fcnNum=fcnNum+1;
% int WINAPI SONExtMarkAlign ( short fh , int n ); 
%fcns.name{fcnNum}='SONExtMarkAlign'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'int16', 'int32'};fcnNum=fcnNum+1;
structs.TMarker.packing=8;
structs.TMarker.members=struct('mark', 'int32', 'mvals', 'int8#4');
structs.TAdcMark.packing=8;
structs.TAdcMark.members=struct('m', 'TMarker', 'a', 'int16#4096');
structs.TRealMark.packing=8;
structs.TRealMark.members=struct('m', 'TMarker', 'r', 'single#512');
structs.TTextMark.packing=8;
structs.TTextMark.members=struct('m', 'TMarker', 't', 'int8#2048');
structs.TFilterMask.packing=8;
structs.TFilterMask.members=struct('lFlags', 'int32', 'aMask', 'uint8#32#4');
structs.TSONTimeDate.packing=8;
structs.TSONTimeDate.members=struct('ucHun', 'uint8', 'ucSec', 'uint8', 'ucMin', 'uint8', 'ucHour', 'uint8', 'ucDay', 'uint8', 'ucMon', 'uint8', 'wYear', 'error');
structs.TSONCreator.packing=8;
structs.TSONCreator.members=struct('acID', 'int8#8');
enuminfo.TDataKind=struct('ChanOff',0,'Adc',1,'EventFall',2,'EventRise',3,'EventBoth',4,'Marker',5,'AdcMark',6,'RealMark',7,'TextMark',8,'RealWave',9);
methodinfo=fcns;