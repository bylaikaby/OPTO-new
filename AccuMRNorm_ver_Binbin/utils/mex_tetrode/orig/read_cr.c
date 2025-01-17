/********************************************************************************

PROGRAM: read_cr.c 

DESCRIPTION:

    Load Neuralynx continuous record files into matlab:

USE:

    w = read_cr( filename, varargin )

AUTHOR:

    Thanos Siapas
    Computation and Neural Systems
    Division of Biology, 
    and Division of Engineering and Applied Science
    California Institute of Technology
    Pasadena, CA 91125
    thanos@mit.edu


versions: Original    05/02    Thanos Siapas


********************************************************************************/

#define VERSION "N_1.10"

/*-----------------------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>
#include <math.h>
#include <mex.h>

#include "header.h"
#include "iolib.h"
#include "mxlib.h"

/*-----------------------------------------------------------------------------*/

#define	max(A, B)	((A) > (B) ? (A) : (B))
#define	min(A, B)	((A) < (B) ? (A) : (B))

/*-----------------------------------------------------------------------------*/

#define MAX_SAMPLES 512

#define FP_OPEN 1
#define FP_CLOSE 0

/*-----------------------------------------------------------------------------*/

/* Input Filename */

#define	FNAME   prhs[0]

/* Output Arguments */

#define RESULT   plhs[0]

/*-----------------------------------------------------------------------------*/
/* Structures */

/*-----------------------------------------------------------------------------*/
/* Continuous Record Buffer */

typedef struct CR_rec_type {

  unsigned long long timestamp;              /* timestamp */
  unsigned long channel_number;              /* channel number */
  unsigned long sample_freq;                 /* sampling frequency in Herz */
  unsigned long n_valid_samples;             /* number of valid samples */

  short data[MAX_SAMPLES];                   /* the A-D data samples */
  
} CR_rec;

/*-----------------------------------------------------------------------------*/

typedef struct parameter_type {

  FILE *fp;           /* file to read from */
  int fp_status;

  double *t;
  double *v;

  unsigned long channel_number;              /* channel number */
  double sample_freq, dt;                    /* sampling frequency in Herz */  

  mxArray *cr;

  char filename[200];

  double tstart, tend;
  double tstart0, tend0;
  int header, headersize;


  long nmax;
  long starti, endi, dstarti, dendi;
  long npoints;
  long nrecords;
  int cr_rec_size;

  int verbose;
  int debug;

} Parameters; 

/*-----------------------------------------------------------------------------*/

void Get_String( const mxArray *arg, char *str )
{
  int strlen; int status;
  
  strlen = (mxGetM(arg)*mxGetN(arg)*sizeof(mxChar))+1; 
  status = mxGetString(arg, str, strlen); 
  if (status != 0) mexErrMsgTxt("Could not convert string data.");
  
}

/*-----------------------------------------------------------------------------*/
/* Get File Information */

void Get_File_Info( Parameters *parms )
{

  struct stat fpstat;
  CR_rec cr_rec;
  long cfp;
  long nread;

  /*------------------------------------------------------------------------*/
  /* Find total number of records */
  
  fstat(fileno(parms->fp),&fpstat);
  parms->nmax = (fpstat.st_size - parms->headersize)/parms->cr_rec_size;

  if( parms->verbose ) {
    mexPrintf("Record Size : %ld %ld\n", parms->cr_rec_size, sizeof(cr_rec));
  }
  
  /*------------------------------------------------------------------------*/
  /* Find start and end time, and number of channels */
  
  cfp = ftell( parms->fp );
  fseek( parms->fp, parms->headersize, SEEK_SET );
  
  nread = fread( &cr_rec, parms->cr_rec_size, 1, parms->fp );
  if( nread != 1 ) mexErrMsgTxt("Error reading record." );
  parms->tstart0 = ((double) cr_rec.timestamp)/1000.0;

  parms->channel_number = cr_rec.channel_number;

  nread = fread( &cr_rec, parms->cr_rec_size, 1, parms->fp );
  if( nread != 1 ) mexErrMsgTxt("Error reading record." );
  parms->sample_freq = MAX_SAMPLES*1000.0/(((double) cr_rec.timestamp)/1000.0 - parms->tstart0); 
  parms->dt = 1000.0/parms->sample_freq;
  
  fseek( parms->fp, -parms->cr_rec_size, SEEK_END );

  nread = fread( &cr_rec, parms->cr_rec_size, 1, parms->fp );
  if( nread != 1 ) mexErrMsgTxt("Error reading record." );
  parms->tend0 = ((double) cr_rec.timestamp/1000);

  /* rewind to original position */
  fseek( parms->fp, cfp, SEEK_SET);

  /* mexPrintf( "Sampling Frequency %f %d %f\n", parms->sample_freq, cr_rec.sample_freq, 
     ((parms->nmax - 1 )*MAX_SAMPLES + 1 ) * 1000.0 / (parms->tend0 - parms->tstart0) ); */

  
}

/*-----------------------------------------------------------------------------*/

/* Read Data */

void Read_Data( Parameters *parms )
{

  CR_rec cr_rec;
  int nread, k, j; 
  int kk, dk; 
  long cbuffer, dcbuffer;
  
  fseek( parms->fp, parms->headersize+parms->starti*parms->cr_rec_size, SEEK_SET );
  kk = 0; dk = parms->dstarti;
  cbuffer = parms->starti;
  
  /*----------------------------------------------------------------------------------*/
  /* read record */
  
  while( 1 ) {
    nread = fread( &cr_rec, parms->cr_rec_size, 1, parms->fp );
    if( nread != 1 ) 
      if( feof( parms->fp ) ) {
	if( parms->verbose == 1 ) 
	  mexPrintf( "Reached end of file %s\n", parms->filename);
	parms->fp_status = -1;
	goto L;
      }  else {
	mexErrMsgTxt("Error reading record." );
      }
    
    /*
      if((parms->tstart > 0) && (cr_rec.timestamp < 1000*parms->tstart)) { continue; }
      if((parms->tend > 0) && (cr_rec.timestamp > 1000*parms->tend)) { break; }
    */
    
    if( cr_rec.n_valid_samples != MAX_SAMPLES ) { mexErrMsgTxt("Invalid samples present." ); }
    
    for( j=dk; j<MAX_SAMPLES; j++ ) {
      if( kk >= parms->npoints ) { dcbuffer = j; goto L; }
      parms->v[kk] = (double) cr_rec.data[j];
      parms->t[kk] = ((double) cr_rec.timestamp)/1000.0 + j*1000.0/parms->sample_freq; 
      kk++;
    }
    
    dk = 0; cbuffer++; 
    
    if(parms->verbose){
      if((parms->npoints > 100) && (kk%(parms->npoints/100) == 0)){ 
	mexPrintf(" %3d%%\b\b\b\b\b",(100*kk)/(parms->npoints)); 
      }
    }
  }

 L:
  
  parms->endi = cbuffer; parms->dendi = dcbuffer;
  parms->tstart = parms->t[0];
  parms->tend = parms->t[kk-1];
  
  if( parms->debug == 1 ) mexPrintf( "Endi = %ld  DEndi = %ld npoints %ld %ld\n", 
				     parms->endi, parms->dendi, parms->npoints, kk );
  
  /*----------------------------------------------------------------------------------*/

}


/*-----------------------------------------------------------------------------*/
/* Binary Search for Begining and ending buffers */

void Disect( Parameters *parms, long *il, long *ih, long *di1, long *di2, long *tl, long *th, double t0)
{
  
  long i1,i2,i; 
  unsigned long long timestamp; 
  double t1,t2;
  
  i1 = 0; i2 = parms->nmax; 
  t1 = -1; t2 = -1;
  
  while( 1 ) {
    
    i = (long) ((i1+i2)/2);
    
    fseek(parms->fp, i*parms->cr_rec_size + parms->headersize,SEEK_SET);
    
    if( fread(&timestamp,sizeof(unsigned long long),1,parms->fp) != 1 ) {
      mexErrMsgTxt("Error reading record." );
    }
    
    if( parms->debug ) {
      mexPrintf( "[ %ld  ,  %ld ]  %ld  [%lf %lf]   %lf --> %lf\n", 
		 i1,i2,i, t1, t2, ((double) timestamp)/1000.0 , t0);
    }

    if( timestamp < 1000*t0 ) { i1=i; t1 = ((double) timestamp)/1000.0; 
    } else { i2=i; t2=((double) timestamp)/1000.0; }
    if( abs( i2-i1 ) > 1 ) continue; else break;
    
  }

  *il = i1; *ih = i2; *tl = t1; *th = t2;
  
  if( t1<0 ) { *di1 = 0; *il = 0; } 
  else { *di1 = (long) ((t0-t1)/parms->dt); }
  
  if( t2<0 ) { *di1 = MAX_SAMPLES-1; *il = parms->nmax-1; } 
  else { *di2 = (long) ((t2-t0)/parms->dt); }

  if( parms->debug ) {
    mexPrintf( "t1 = %lf   t0 = %lf   t2 = %lf\n", t1,t0,t2 );
    mexPrintf( "(%lf) i1 = %ld di1 = %ld  (%lf) i2 = %ld di2 = %ld \n", 
	       (t0-t1)/parms->dt, *il, *di1, (t2-t0)/parms->dt, *ih, *di2);
    mexPrintf( "i1 = %ld  di1 = %ld  (%lf) i2 = %ld di2 = %ld (%lf)\n", 
	       i1,*di1, t0-t1,i2,*di2,t2-t0 );
  }
  
  return;
  
}


/*-----------------------------------------------------------------------------*/
/* Compute Number of points and indices */

void Compute_Number_of_Points( Parameters *parms )
{
  
  long i1,i2,di1,di2,i,n,t1,t2,npts; 
  
  if( parms->tstart >0 ) {
    if( parms->tstart > parms->tend0 ) {
      parms->npoints = 0; return;
    }
    if( parms->tstart < parms->tstart0 ) {
      if(( parms->tend > parms->tstart0 ) || 
	 ( parms->tstart+((double) parms->npoints)*parms->dt > parms->tstart0 )) {
	parms->starti = 0; parms->dstarti = 0;
      } else {
	parms->npoints =0; return;
      }
    } else {
      Disect( parms, &i1, &i2, &di1, &di2, &t1, &t2, parms->tstart );
      parms->starti = i1;
      parms->dstarti = di1;
    }
  } else {
    parms->starti = 0; parms->dstarti = 0;
  }

  if(( parms->tend > 0 ) && (parms->tend < parms->tend0 )) {
    if( parms->tend <= parms->tstart0 ) {
      parms->npoints = 0; parms->endi=0; parms->dendi=0; return;
    } else {
      Disect( parms, &i1, &i2, &di1, &di2, &t1, &t2, parms->tend );
      parms->endi = i1; 
      parms->dendi = di1;
    }
  } else {
    parms->endi = parms->nmax-1; parms->dendi = MAX_SAMPLES-1;
  }

  npts = (parms->endi - parms->starti-1)*MAX_SAMPLES + MAX_SAMPLES - parms->dstarti + parms->dendi;

  if( parms->npoints <=0 ) parms->npoints = npts;
  else parms->npoints = min( npts, parms->npoints ); 

  parms->nrecords = (parms->endi - parms->starti)+1;
  
}


/*-----------------------------------------------------------------------------*/

void display_parms( Parameters *parms )
{
  
  if( parms->verbose ) {
    
    mexPrintf( "-------------------------------------------------------------------------------\n" );

    mexPrintf( "Tstart0 : %lf\t Tend0 %lf\n", parms->tstart0, parms->tend0 ); 
    mexPrintf( "Total Number of points : %ld (%ld records)\n", parms->nmax * MAX_SAMPLES, parms->nmax ); 
    mexPrintf( "Tstart : %lf\t Tend %lf\n", parms->tstart, parms->tend ); 
    mexPrintf( "Number of points to be processed : %ld (%ld records)\n", parms->npoints , parms->nrecords); 
    mexPrintf( "starti : %ld (%ld) \t endi %ld (%ld)\n", parms->starti, parms->dstarti, parms->endi, parms->dendi );
    mexPrintf( "sample freq = %lf \t dt = %lf\n", parms->sample_freq, parms->dt );


    mexPrintf( "-------------------------------------------------------------------------------\n" );

  }

}

/*-----------------------------------------------------------------------------*/

void update_parms( Parameters *parms )
{

  CR_rec cr_rec;
  struct stat fpstat;
  
  if( parms->header == 1 ) parms->headersize = 16384; 
  parms->cr_rec_size = sizeof( cr_rec ); 
  
  parms->fp = fopen( parms->filename , "r" );
  if( parms->fp == NULL ) mexErrMsgTxt("Could not open file.");
  parms->fp_status = FP_OPEN;
  
  if( ( parms->cr == NULL ) || mxIsEmpty( parms->cr ) ){
    
    Get_File_Info( parms );
    Compute_Number_of_Points( parms ); 
    
  } else { 
    
    if( parms->verbose ) mexPrintf( "Reusing open file %s\n", parms->filename );
    
    /* 
       parms->fp = (FILE *) (unsigned long) get_scalar_field( parms->cr, "fp" );
       if( fstat(fileno(parms->fp),&fpstat) == -1 ) mexErrMsgTxt("Illegal file."); 

    */
    
    parms->fp_status = get_scalar_field( parms->cr, "fp_status" );
    parms->tstart0 = get_scalar_field( parms->cr, "tstart0" );
    parms->tend0 = get_scalar_field( parms->cr, "tend0" );
    parms->nmax = (long) get_scalar_field( parms->cr, "nmax" );
    parms->sample_freq = get_scalar_field( parms->cr, "sample_freq" );
    parms->dt = get_scalar_field( parms->cr, "dt" );
    parms->channel_number = (unsigned long) get_scalar_field( parms->cr, "channel_number" );
    parms->headersize = (int) get_scalar_field( parms->cr, "headersize" );
    parms->starti = (long) get_scalar_field( parms->cr, "endi" );  
    parms->dstarti = (long) get_scalar_field( parms->cr, "dendi" );
    parms->npoints = (long) get_scalar_field( parms->cr, "npoints" );
    parms->nrecords = (long) get_scalar_field( parms->cr, "nrecords" );
    parms->cr_rec_size = (long) get_scalar_field( parms->cr, "record_size" );
    parms->endi = (long) (parms->starti + floor(parms->npoints/MAX_SAMPLES));    
    parms->dendi = (long) fmod(parms->npoints, MAX_SAMPLES);

    parms->tstart = get_scalar_field( parms->cr, "tend" );
    parms->tend = 2* parms->tstart - get_scalar_field( parms->cr, "tstart"); 
    
    if( parms->starti > parms->nmax-1 ) {
      mexPrintf("End of buffer reached!\n");
      parms->npoints = 0; parms->starti = 0; parms->dstarti = 0;      
    }
    
    if( parms->endi > parms->nmax-1 ) { 
      parms->endi = parms->nmax-1;
      parms->dendi = MAX_SAMPLES-1;
      parms->npoints = (parms->endi - parms->starti-1)*MAX_SAMPLES + MAX_SAMPLES - parms->dstarti + parms->dendi;
    }
  }
  display_parms( parms );
}

/*-----------------------------------------------------------------------------*/

void update_cr( Parameters *parms )
{

  int ndim=2, dims[2] = {1,1};
  int ncr_fields = 19;
  const char *cr_field_names[] = {"filename", "fp", "fp_status", "starti", "dstarti", "endi", "dendi", 
				  "npoints", "nrecords", "record_size", "tstart", "tend", "tstart0", "tend0",
				  "nmax", "sample_freq", "dt", "channel_number", "headersize"};
  
  if(( parms->cr == NULL ) || mxIsEmpty(parms->cr) )  {
    parms->cr = mxCreateStructArray( ndim, dims, ncr_fields, cr_field_names);
  }

  set_string_field( parms->cr, "filename", parms->filename );
  set_field( parms->cr, "fp", (double) (unsigned long) parms->fp );
  set_field( parms->cr, "fp_status", (double) parms->fp_status);
  set_field( parms->cr, "starti", (double) parms->starti );
  set_field( parms->cr, "dstarti", (double) parms->dstarti );
  set_field( parms->cr, "endi", (double) parms->endi );
  set_field( parms->cr, "dendi", (double) parms->dendi );
  set_field( parms->cr, "npoints", (double) parms->npoints );
  set_field( parms->cr, "nrecords", (double) parms->nrecords );
  set_field( parms->cr, "record_size", (double) parms->cr_rec_size );
  set_field( parms->cr, "tstart", (double) parms->tstart );
  set_field( parms->cr, "tend", (double) parms->tend );
  set_field( parms->cr, "tstart0", (double) parms->tstart0 );
  set_field( parms->cr, "tend0", (double) parms->tend0 );
  set_field( parms->cr, "nmax", (double) parms->nmax );
  set_field( parms->cr, "sample_freq", parms->sample_freq );
  set_field( parms->cr, "dt", (double) parms->dt );
  set_field( parms->cr, "channel_number", (double) parms->channel_number );
  set_field( parms->cr, "headersize", (double) parms->headersize );
  
}



/*-----------------------------------------------------------------------------*/
/* GateWay routine for interfacing with Matlab */


void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{

  char ifname[200]; FILE *fpi;
  
  char *str0;
  int narg; char arg[100]; char str[100]; 
  int i,j; int nout;

  double *tmp;
  
  mxArray *field_ptr;
  mxArray *waveforms;
  mxArray *information;
  
  char *parmstr; int len;

  Parameters parms;
  
  int ndim=2, dims[2] = {1,1};
  int number_of_fields = 5;
  const char *field_names[] = {"t", "v",  "tstart", "tend", "sample_freq"};
  mxArray *t_field[1], *v_field[1], *tstart_field[1], *tend_field[1], *sample_freq_field[1];

  int close_flag = 0;


  /*--------------------------------------------------------------------------*/
  
  if(nrhs < 1)
    mexErrMsgTxt("[DATA, CR] = READ_CR ( FILE.TT [VERBOSE TSTART TEND CR NPOINTS NRECORDS CLOSE] )" );
  
  if(mxIsChar(FNAME)==0)
    mexErrMsgTxt("Argument must be a filename.");
  
  Get_String( FNAME, parms.filename );
  
  /*-------------------------------------------------------------------------*/
  /* Assign values to input parameters */
  
  parms.verbose = 0; 
  parms.tstart = -1.0; parms.tend = -1.0; 
  parms.headersize = 0;
  parms.header = 1;
  parms.cr = NULL;
  parms.fp_status = -1;
  parms.debug = 0;

  parms.nrecords = 0; parms.npoints = 0;
  
  narg = 0;
  
  while( ++narg < nrhs ) {
    if( mxIsChar( prhs[narg] ) ) {
      Get_String( prhs[narg], arg );
      if( arg!=NULL ) {
	
	if( strcmp( arg, "verbose" )==0 | strcmp( arg, "v" )==0 ) { parms.verbose=1; continue;  }
	if( strcmp( arg, "header" )==0 ) { parms.header=1; continue;  }
	if( strcmp( arg, "noheader" )==0 ) { parms.header=0; continue;  }
	if( strcmp( arg, "debug" )==0 ) { parms.debug=1; continue;  }

	if(( strcmp( arg, "npoints" )==0 ) || (strcmp( arg, "n" )==0)){ parms.npoints = (long) mxGetScalar( prhs[++narg] ); continue; }
	if( strcmp( arg, "nrecords" )==0 ) { parms.nrecords = (long) mxGetScalar( prhs[++narg] ); continue; }

	if( strcmp( arg, "close" )==0 ) { close_flag = 1; continue; }

	if( strcmp( arg, "tstart" )==0 ) { 
	  if( mxIsNumeric( prhs[narg+1] ) ) { parms.tstart = mxGetScalar( prhs[++narg] );
	  } else {
	    Get_String( prhs[++narg], str );
	    parms.tstart = ((double) ParseTimestamp( str ));
	    parms.tstart = parms.tstart/10;
	  }
	  continue;
	}

	if( strcmp( arg, "cr" )==0 ) { parms.cr = mxDuplicateArray( prhs[++narg] ); continue;  }	

	if( strcmp( arg, "tend" )==0 ) { 
	  if( mxIsNumeric( prhs[narg+1] ) ) { parms.tend = mxGetScalar( prhs[++narg] );
	  } else {
	    Get_String( prhs[++narg], str );
	    parms.tend = ((double) ParseTimestamp( str ));
	    parms.tend = parms.tend/10;
	  }
	  continue;
	}
	mexPrintf( "# : Unknown argument %d type ('%s').\n", narg, arg );
      }
    } else {
      mexPrintf( "# : Argument %d is not a string field.\n", narg );
    }
  }
  
  /*-------------------------------------------------------------------------*/

  if( close_flag ) {
    if(( parms.cr == NULL ) || mxIsEmpty(parms.cr) )  {
      mexErrMsgTxt("File not open." );    
    } else { 
      if( parms.verbose ) mexPrintf("Closing file...");
      parms.fp = (FILE *) (unsigned long) get_scalar_field( parms.cr, "fp" ); 
      fclose( parms.fp );
      if( parms.verbose ) mexPrintf("Done.\n");
      return;
    }
  }

  /*-------------------------------------------------------------------------*/

  if( parms.verbose ) mexPrintf("Loading from  file %s\n", parms.filename );
  update_parms( &parms );

  /*-------------------------------------------------------------------------*/
  /* Create output structure */

  dims[0] = 1;  
  RESULT = mxCreateStructArray( ndim, dims, number_of_fields, field_names);

  t_field[0] = mxCreateDoubleMatrix( parms.npoints, 1, mxREAL); parms.t = mxGetPr( t_field[0] );
  mxSetField( RESULT, 0, "t", t_field[0] ); 
  
  v_field[0] = mxCreateDoubleMatrix( parms.npoints, 1, mxREAL); parms.v = mxGetPr( v_field[0] );
  mxSetField( RESULT, 0, "v", v_field[0] ); 

  /*-------------------------------------------------------------------------*/
  
  if( parms.verbose ) mexPrintf( "Loading data..." );
  if( parms.npoints>0 ) Read_Data( &parms ); 
  if( parms.verbose ) mexPrintf( "done.\n");

  /*-------------------------------------------------------------------------*/

  tstart_field[0] = mxCreateDoubleMatrix(1, 1, mxREAL); 
  tmp = mxGetPr( tstart_field[0] ); tmp[0] = parms.tstart;
  mxSetField( RESULT, 0, "tstart", tstart_field[0] ); 

  tend_field[0] = mxCreateDoubleMatrix(1, 1, mxREAL); 
  tmp = mxGetPr( tend_field[0] ); tmp[0] = parms.tend;
  mxSetField( RESULT, 0, "tend", tend_field[0] ); 

  sample_freq_field[0] = mxCreateDoubleMatrix(1, 1, mxREAL); 
  tmp = mxGetPr( sample_freq_field[0] ); tmp[0] = parms.sample_freq;
  mxSetField( RESULT, 0, "sample_freq", sample_freq_field[0] ); 

  /*-------------------------------------------------------------------------*/

  if( nlhs > 1 ) {

    update_cr( &parms );
    plhs[1] = parms.cr; 
    
  }
  
  /*-------------------------------------------------------------------------*/
  /* Free */

  fclose( parms.fp );
  
}  


