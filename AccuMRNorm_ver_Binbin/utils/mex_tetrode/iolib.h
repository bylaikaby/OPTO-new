#ifndef  _IOLIB_H_INCLUDED
#define  _IOLIB_H_INCLUDED


extern char 	**ReadHeader();
extern char	*TFstr();
extern void	WriteStandardHeader();
extern void	DisplayHeader();
extern int	sgetargs();
extern char	*iolibversion();
extern char	*iolibrevision();
extern int	VerifyIdentical();
extern int	GetFileTypeTet();
extern int	GetFieldCount();
extern char	*GetFieldString();
extern char	*GetHeaderParameter();
extern int	GetFieldInfoByNumber();
extern int	GetFieldInfoByName();
extern void	ConvertData();

/*
** this is the magic start of header string
*/
#define MAGIC_SOH_STR "%%BEGINHEADER"
/*
** this is the magic end of header string
*/
#define MAGIC_EOH_STR "%%ENDHEADER"
/*
** this is the length of the magic start of header string %%BEGINHEADER
*/
#define MAGIC_SOH_STRSIZE	14
/*
** this is the length of the magic end of header string %%ENDHEADER
*/
#define MAGIC_EOH_STRSIZE	12

#define INVALID_TYPE	-1
#define ASCII	0
#define BINARY	1

typedef struct field_info_type {
    char	*name;	
    int		column;	
    int		type;
    int		size;
    int		count;
} FieldInfo;



#if defined (_WIN32)
#define _UTSNAME_LENGTH 65
#define _UTSNAME_SYSNAME_LENGTH  _UTSNAME_LENGTH
#define _UTSNAME_NODENAME_LENGTH _UTSNAME_LENGTH 
#define _UTSNAME_RELEASE_LENGTH  _UTSNAME_LENGTH 
#define _UTSNAME_VERSION_LENGTH  _UTSNAME_LENGTH 
#define _UTSNAME_MACHINE_LENGTH  _UTSNAME_LENGTH 
#define _UTSNAME_DOMAIN_LENGTH   _UTSNAME_LENGTH 
struct utsname
{
  char sysname[_UTSNAME_SYSNAME_LENGTH];
  char nodename[_UTSNAME_NODENAME_LENGTH];
  char release[_UTSNAME_RELEASE_LENGTH];
  char version[_UTSNAME_VERSION_LENGTH];
  char machine[_UTSNAME_MACHINE_LENGTH];
#ifdef _GNU_SOURCE
  char domainname[_UTSNAME_DOMAIN_LENGTH];
#endif
};

int  uname(struct utsname *__name);
void bcopy(void *s1, void *s2, size_t n);
int  bcmp(char *s1, char *s2, size_t n);
void bzero(void *s, size_t n);

#ifndef _WINDOWS_
typedef unsigned long long UINT64;
#endif

double TimestampToDouble(UINT64 timestamp);

#endif


#endif  // end of _IOLIB_H_INCLUDED
