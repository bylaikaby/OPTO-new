/*************************************************************************
 *
 *  NAME
 *    dynio.h
 *
 *  DESCRIPTION
 *    Structure definitions for reading and writing dynamic groups
 *
 *  AUTHOR
 *    DLS
 *    YM  15.Jul.2013  "long" as "int32" to support 64bit *nix/mac system.
 *
 ************************************************************************/

#ifndef _INCLUDE_DYNIO_H
#define _INCLUDE_DYNIO_H

#if defined(_MSC_VER) && (_MSC_VER <= 1500)
typedef __int32  int32_t;
#else
#include <stdint.h>
#endif



#ifdef __cplusplus
extern "C" {
#endif


extern float dynVersion;	/* to keep track of different versions */

#define DG_MAGIC_NUMBER_SIZE 4 
extern char dynMagicNumber[];	/* to uniquely identify this file type */


/***********************************************************************
 *
 *  Structures which are described here and are dumpable/readable:
 *      DG_FILE
 *         DG_INFO
 *         DYN_LIST
 *
 ***********************************************************************/

enum DYN_STRUCT_TYPE {
  DG_TOP_LEVEL,			/* regular data type (e.g. long, float)*/
  DYN_GROUP_STRUCT, 
  DYN_LIST_STRUCT, 
  N_DG_STRUCT_TYPES		/* leave as last struct                */
};

/*
 * The only TAGS which can appear before one of the defined structures
 * are the following.  These contain info about the datafile version and
 * then enter the highest level structure.
 */

enum DG_TOP_LEVEL_TAGS { DG_VERSION_TAG, DG_BEGIN_TAG };
enum DG_TAG { DG_NAME_TAG, DG_NLISTS_TAG, DG_DYNLIST_TAG };
enum DL_TAG { DL_NAME_TAG, DL_INCREMENT_TAG, DL_DATA_TAG,
	    DL_STRING_DATA_TAG, DL_CHAR_DATA_TAG, DL_SHORT_DATA_TAG,
	    DL_INT32_DATA_TAG, DL_FLOAT_DATA_TAG, DL_LIST_DATA_TAG,
	    DL_SUBLIST_TAG, DL_FLAGS_TAG };

// backward compatibility...
#define DL_LONG_DATA_TAG  DL_INT32_DATA_TAG


/***********************************************************************
 *
 *                      DG_FILE_IO Function Prototypes
 *
 ***********************************************************************/

void dgInitBuffer(void);	              /* init a datafile buf   */
void dgResetBuffer(void);                     /* reset and initialize  */
void dgCloseBuffer(void);	              /* free mem assoc. w/buf */
void dgWriteBuffer(char *filename, char format);
int  dgWriteBufferCompressed(char *filename);
unsigned char *dgGetBuffer(void);
int dgGetBufferSize(void);


void dgRecordDynGroup(DYN_GROUP *dg);

void dgRecordMagicNumber(void);

void dgRecordFlag(unsigned char);
void dgRecordChar(unsigned char, unsigned char);
void dgRecordInt32(unsigned char, int32_t);
#define dgRecordLong(a,b)  dgRecordInt32(a,b)
void dgRecordShort(unsigned char, short);
void dgRecordFloat(unsigned char, float);

void dgRecordString(unsigned char, char *);
void dgRecordStringArray(unsigned char, int, char **);
void dgRecordVoidArray(unsigned char, int, int, void *);
void dgRecordInt32Array(unsigned char, int, int32_t *);

void dgRecordShortArray(unsigned char, int, short *);
void dgRecordFloatArray(unsigned char, int, float *);
void dgRecordCharArray(unsigned char, int, char *);
void dgRecordListArray(unsigned char type, int n);
#define dgRecordLongArray(a,b,c)  dgRecordInt32Array(a,b,c)
void dgBeginStruct(unsigned char tag);
void dgEndStruct(void);

void dgPushStruct(int newstruct, char *);
int  dgPopStruct(void);
void dgFreeStructStack(void);
int  dgGetCurrentStruct(void);
char *dgGetCurrentStructName(void);
char *dgGetTagName(int type);
int  dgGetDataType(int type);
int  dgGetStructureType(int type);

int dguFileToStruct(FILE *InFP, DYN_GROUP *dg);
int dguBufferToStruct(unsigned char *vbuf, int n, DYN_GROUP *dg);

void dguFileToAscii(FILE *InFP, FILE *OutFP);

int dguFileToDynGroup(FILE *InFP, DYN_GROUP *dg);
int dguFileToDynList(FILE *InFP, DYN_LIST *dl);
void dguBufferToAscii(unsigned char *vbuf, int bufsize, FILE *OutFP);


#ifdef __cplusplus
}
#endif

#endif  // end of _INCLUDE_DYNIO_H
