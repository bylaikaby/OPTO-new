/* compile with: "mex -I/usr/local/include read_conn.c sockfuncs.c user32.lib ws2_32.lib d:\usr\local\lib\wsock32x.lib"
	     with timing checks:
	     or: "mex -DTIMING_CONTROL -I/usr/local/include read_conn.c sockfuncs.c user32.lib ws2_32.lib d:\usr\local\lib\wsock32x.lib winmm.lib"
	     or: "mex -DTIMING_CONTROLII -I/usr/local/include read_conn.c sockfuncs.c user32.lib ws2_32.lib d:\usr\local\lib\wsock32x.lib winmm.lib" */
#include <stdio.h>
#define _WIN32_WINNT 0x0500
#define WINVER 0x0500
#define _WINNT
#include <windows.h>
#include <stdlib.h>
#include <fcntl.h>
#include <io.h>
#include <wsa_xtra.h>
#include <windowsx.h>

#include <winsock.h>
// #include "sockres.h"
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <dos.h>
#include <direct.h>
#include <winsockx.h>

#include <stim.h>

#include <mex.h>

#if defined(TIMING_CONTROL) || defined(TIMING_CONTROLII)
DWORD startTime;
#endif
#ifdef TIMING_CONTROLII
DWORD time_1,time_2,time_3;
#endif

FILE *hf0,*hf1,*hf2;
static DWORD ConnThreadID = -1;
static DWORD Mode;
char *inbuf;
char *outbuf;
fd_set readfdsr;
fd_set writefdsr;
// fd_set exceptfdsr;
struct timeval timeoutr;

extern SOCKET hLstnSock; /* Listening socket */
extern SOCKADDR_IN stLclName;           /* Local address and port number */
extern int  iActiveConns;               /* Number of active connections */
extern long lByteCount;                 /* Total bytes read */
extern int  iTotalConns;                /* Connections closed so far */

typedef struct stConnData {
  SOCKET hSock;                  /* Connection socket */
  SOCKADDR_IN stRmtName;         /* Remote host address & port */
  LONG lStartTime;               /* Time of connect */
  BOOL bReadPending;             /* Deferred read flag */
  int  iBytesRcvd;               /* Data currently buffered */
  int  iBytesSent;               /* Data sent from buffer */
  long lByteCount;               /* Total bytes received */
  char achIOBuf  [INPUT_SIZE];   /* Network I/O data buffer */
  struct stConnData FAR*lpstNext;/* Pointer to next record */
} CONNDATA, *PCONNDATA, FAR *LPCONNDATA;

LPCONNDATA *lpstSockHeadp;     /* Head of the list */

extern BOOL  bReAsync;
char *tcl_rcv, *tcl_rep;

/*------------ function prototypes -----------*/
int InitSocket(HWND hWin, HINSTANCE hInstance);
BOOL InitLstnSock(int iLstnPort, PSOCKADDR_IN pstSockName,
  HWND hWnd, u_int nAsyncMsg);
SOCKET AcceptConn(SOCKET, PSOCKADDR_IN);
int SendData(SOCKET, LPSTR, int);
int RecvData(SOCKET, LPSTR, int);
int CloseConn(SOCKET, LPSTR, int, HWND);
LPCONNDATA NewConn (SOCKET, PSOCKADDR_IN);
LPCONNDATA FindConn (SOCKET);
void RemoveConn (LPCONNDATA);
BOOL doSocketMessage (HWND hWinMain, UINT msg, UINT wParam, LPARAM lParam);
/*--------------------------------------------*/

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  double d;
  int *sock_array;
  int *j;
  int i,retval,allhosts;
  int datalen;
  char hostip[256];
  int blocking=0;
  LPCONNDATA lpstSockTmp;

#if defined(TIMING_CONTROL) || defined(TIMING_CONTROLII)
timeBeginPeriod(1);
startTime=timeGetTime();
#endif
 
  if (nrhs != 3) {
    mexErrMsgTxt("usage: output = read_conn (socket[returned from open_conn],host[or 'all'],blocking_mode[0=non-blocking,1=blocking])");
    return;
  }
  if (nlhs > 1) {
    mexErrMsgTxt("output is exactly one string (empty if no input)");
    return;
  }

  {FILE *fl=fopen("d:/tesa1","w");fprintf(fl,"hier0\n");fclose(fl);}
  d=mxGetScalar(prhs[0]);
  j=&d;
  //printf("%d\n",(int *)*j); return;
  sock_array=*j;
  if(!*j || sock_array[12]) mexErrMsgTxt("Network socket not initialized!");
  hf0=(FILE *)sock_array[0];hf1=(FILE *)sock_array[1];
  inbuf=(char *)sock_array[2];outbuf=(char *)sock_array[3];
  tcl_rcv=(char *)sock_array[4];tcl_rep=(char *)sock_array[5];
  lpstSockHeadp=sock_array[6];
  // sock_array[9]=0; // output to permit closing the socket
  // printf("%d::%d:%d:%d:%d:%d:%d:%d\n",sock_array,hf0,hf1,inbuf,outbuf,tcl_rcv,tcl_rep,lpstSockHeadp);return;
  if(tcl_rcv==NULL) mexErrMsgTxt("Network socket not initialized!");

  datalen = (mxGetM(prhs[1]) * mxGetN(prhs[1])) + 1;
  mxGetString(prhs[1], hostip, datalen);
  if (!strcmp(hostip,"all")) allhosts=1; else allhosts=0;

  if (mxGetScalar(prhs[2]) == 1.) blocking=1; else blocking=0;

  sock_array[13]=0; // output to permit closing the socket
  timeoutr.tv_sec=0; timeoutr.tv_usec=1000;
  datalen=0;

  {FILE *fl=fopen("d:/tesa1","a");fprintf(fl,"hier1\n");fclose(fl);}
  start_over:
  for(;;) {
  {FILE *fl=fopen("d:/tesa1","a");fprintf(fl,"hier2\n");fclose(fl);}
    //if (lpstSockHeadp[0] == -1) /* thread closed */ {sprintf(tcl_rcv,"Error: connection closed\n"); goto _end;}
    if (sock_array[12]) /* thread closed */ {sprintf(tcl_rcv,"Error: connection closed\n"); goto _end;}
    //readfdsr.fd_count=0;readfdsr.fd_array[0]=NULL;i=0;
    FD_ZERO(&readfdsr);
    while (lpstSockHeadp[0] == NULL) /* no clients */ {/*goto check_state;*/ if(blocking&&!sock_array[12]) _sleep(1); else goto _end;}
    lpstSockTmp = lpstSockHeadp[0];
  {FILE *fl=fopen("d:/tesa1","a");fprintf(fl,"hier3\n");fclose(fl);}
    for (;;) {
      if(!allhosts) {
        if(strcmp(hostip,inet_ntoa((lpstSockTmp->stRmtName).sin_addr))) goto _next;
      }
      FD_SET(lpstSockTmp->hSock,&readfdsr);
      //readfdsr.fd_count++; readfdsr.fd_array[i++] = lpstSockTmp->hSock;
      if(!allhosts) {
	// we could simply 'break' and run the select loop, but this isn't necessary for a single host in blocking mode;
        if(!blocking) break;
	i=0; goto singlehost_blocking;
      }
      _next:
      if (!lpstSockTmp->lpstNext) break;
      lpstSockTmp = lpstSockTmp->lpstNext;
    }
#ifdef TIMING_CONTROLII
    if (hf1) fprintf(hf1,"preselect: %d:%d:%d\n",timeGetTime()-startTime,lpstSockHeadp[0],lpstSockHeadp[0]->lpstNext);
#endif
    // now test for input
    if(select(1,&readfdsr,NULL,NULL,&timeoutr) > 0) break;
    check_state:
    if(blocking) {
      // if blocking and host not (yet) connected, we could wait for ever or return immediately ...
      // if (!readfdsr.fd_count) {tcl_rcv[0]=0; goto _end;}
      // _sleep(5) /* the user might poll too fast! */;
      // permit exiting of the loop instead
      //// the Event is autoresetting so let the main loop do the job; check kill_sock instead
      //// if(WaitForSingleObject(sock_array[8],5) == WAIT_OBJECT_0) {
      //// if(WaitForSingleObject(waitHandle,5) == WAIT_OBJECT_0) {
      //// sprintf(tcl_rcv,"Error: cancelled by user\n"); goto _end;
      //// }
      if (sock_array[13] == -1) {sprintf(tcl_rcv,"Error: cancelled by user\n"); goto _end;}
    } else {
      tcl_rcv[0]=0; goto _end;
    }
  }

  {FILE *fl=fopen("d:/tesa1","a");fprintf(fl,"hier4\n");fclose(fl);}
  // now read
  for (i=0;i<readfdsr.fd_count;i++) {
    singlehost_blocking:
  {FILE *fl=fopen("d:/tesa1","a");fprintf(fl,"hier5\n");fclose(fl);}
    // warning: select calls may change the order of readfdsr.fd_array, so set curr_sock here
    sock_array[7] = readfdsr.fd_array[i]; // last read for write_conn
    // report the current socket to the calling thread (to permit killing of blocking call)
    if (sock_array[13] == -1) {sprintf(tcl_rcv,"Error: cancelled by user\n"); goto _end;}
    if (blocking) sock_array[13] = sock_array[7];
#ifdef TIMING_CONTROLII
    if (hf1) fprintf(hf1,"preread: %d\n",timeGetTime()-startTime);
#endif
    retval = doSocketMessage(NULL,0,sock_array[7],FD_READ);
  {FILE *fl=fopen("d:/tesa1","a");fprintf(fl,"hier6\n");fclose(fl);}
    if(retval==-2) { // only case!: the socket is set to non_blocking but no data are available (WSAEWOULDBLOCK)
      if (blocking) goto start_over;
      else continue; // maybe data on the next socket
    }
    if(retval==0) continue; // socket error; maybe try the next one
    if(retval>=0) { // data received (tcl_rcv>0) or socket error (tcl_rcv=0)
#ifdef TIMING_CONTROLII
      if (hf1) fprintf(hf1,"postread: %d\n",timeGetTime()-startTime);
#endif
      if(!tcl_rcv[0]) {
  {FILE *fl=fopen("d:/tesa1","a");fprintf(fl,"hier7\n");fclose(fl);}
        doSocketMessage(NULL,0,sock_array[7],FD_CLOSE);
	if (sock_array[13] == -1) {sprintf(tcl_rcv,"Error: cancelled by user\n"); goto _end;}
	// should we repeat the read in this case when blocking is set?
        if (blocking) goto start_over;
      } else {
  {FILE *fl=fopen("d:/tesa1","a");fprintf(fl,"hier8\n");fclose(fl);}
        if(hf1) fprintf(hf1,"%s",tcl_rcv);
	datalen=strlen(tcl_rcv);
        // exception: "ping xxx" must be (directly) answered with "pong xxx" without user interference
	if (!strncmp(tcl_rcv,"ping ",5)) {
#ifdef TIMING_CONTROLII
	  // no pong if cookie in request; simply ignore the ping
	  if (!strncmp(tcl_rcv+5,"9876",4)) {
	    if (hf1) fprintf(hf1,"cookie: %d\n",timeGetTime()-startTime);
	    time_1 = timeGetTime(); // handshake (ACK) is required!!!, otherwise the conn. hangs for about 100ms; goto start_over;
	  }
          time_3 = atoi(tcl_rcv+5) - 100000000;
	  if ((int)time_3 >= 100000000) { // 200 secs offset, ping-pong
	    if (hf1) fprintf(hf1,"time for handshake (remote,local): %d,%d\n",(time_3-100000000)/1000,timeGetTime()-time_2);
	  } else if ((int)time_3 >= 0) { // 100 secs offset
	    time_2 = timeGetTime();
	    if (hf1) fprintf(hf1,"time for transmit from remote (remote,local):%d,%d\n",time_3/1000,time_2-time_1);
	  }
#endif
 	  if (!blocking) { // check first
  	    FD_ZERO(&writefdsr);
   	    //writefdsr.fd_count=0;writefdsr.fd_array[0]=NULL;i=0;
   	    //FD_SET(readfdsr.fd_array[i],&writefdsr);
   	    writefdsr.fd_count=1; writefdsr.fd_array[0] = sock_array[7];
   	    // now test for output
  	    if(!select(1,NULL,&writefdsr,NULL,&timeoutr)) {
  	      sprintf(tcl_rcv,"Error: stim communication couldn't be established!\n"); goto _end;
  	    }
 	  }
 	  // now send the po(!)ng
          memcpy(tcl_rep,tcl_rcv,datalen+1);
	  tcl_rep[1]='o'; // pong
 	  // already in tcl_rcv: tcl_rep[datalen] = '\n';
 	  // already in tcl_rcv: tcl_rep[datalen+1] = '\0';
 	  datalen=SendData(sock_array[7], tcl_rep, datalen+1);
	  //if (datalen) goto start_over; // inform the requesting process explicitly instead
	  if (datalen) {
	    sprintf(tcl_rcv,"connected to host %s\n",inet_ntoa((lpstSockTmp->stRmtName).sin_addr)); goto _end;
	  } else {
	    sprintf(tcl_rcv,"Error: stim communication couldn't be established!\n"); goto _end;
	  }
	}
	// make sure we get one request after the other
	goto _end;
      }
    }
  }

  _end:
  // just the last? shouldn't make any difference: {char *eol; if (eol = strrchr(tcl_rcv, '\n')) *eol = 0;}
  /* i=strlen(tcl_rcv);*/ if (datalen>0 && tcl_rcv[datalen-1] == '\n') tcl_rcv[--datalen]=0;
  plhs[0] = mxCreateString(tcl_rcv);
  //memset(tcl_rcv,0,SOCK_BUF_SIZE); the following will do:
  tcl_rcv[0]=0;
  sock_array[13]=0; // output to permit closing the socket

#if defined(TIMING_CONTROL) || defined(TIMING_CONTROLII)
timeEndPeriod(1);
if (hf1) fprintf(hf1,"time in call: %d\n",timeGetTime()-startTime);
#endif

}
