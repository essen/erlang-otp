/* ``The contents of this file are subject to the Erlang Public License,
 * Version 1.1, (the "License"); you may not use this file except in
 * compliance with the License. You should have received a copy of the
 * Erlang Public License along with this software. If not, it can be
 * retrieved via the world wide web at http://www.erlang.org/.
 * 
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
 * the License for the specific language governing rights and limitations
 * under the License.
 * 
 * The Initial Developer of the Original Code is Ericsson Utvecklings AB.
 * Portions created by Ericsson are Copyright 1999, Ericsson Utvecklings
 * AB. All Rights Reserved.''
 * 
 *     $Id$
 */

#ifndef __GLOBAL_H__
#define __GLOBAL_H__

#include "sys.h"
#include "erl_vm.h"
#include "hash.h"
#include "index.h"
#include "atom.h"
#include "export.h"
#include "module.h"
#include "register.h"

#include "erl_process.h"
#include "driver.h"

typedef enum {
    LNK_UNDEF = 0,
    LNK_LINK  = 1,  /* normal link */
    LNK_NODE  = 2,  /* node link */
    LNK_OMON  = 3,  /* originating object monitor */
    LNK_TMON  = 4,  /* terminating object monitor */
    LNK_LINK1 = 5,  /* Uni-directional link, for monitor/2 */
#ifdef MONITOR_ENHANCE
    /* All code already written which does monitor/2 on something other
       than a local process is wrapped in this ifdef MONITOR_ENHANCE */
    LNK_NODE1 = 6,  /* node link, for monitor/2 */
#endif
} ErlLinkType;

typedef struct erl_link {
    struct erl_link* next;
    ErlLinkType type;       /* Type of link */
    uint32 item;            /* the linked item */
    uint32 data;            /* data depending on use */
    Ref ref;		    /* for LINK1 and NODE1 links */
} ErlLink;

EXTERN_FUNCTION(ErlLink*, new_link, (ErlLink*,ErlLinkType,uint32,uint32));
EXTERN_FUNCTION(ErlLink*, new_ref_link, (ErlLink*,ErlLinkType,uint32,uint32,uint32));
EXTERN_FUNCTION(void, del_link, (ErlLink**));
EXTERN_FUNCTION(ErlLink**, find_link, (ErlLink**,ErlLinkType,uint32,uint32));
EXTERN_FUNCTION(ErlLink**, find_link_by_ref, (ErlLink**,Ref*));

/* The 9-bit node part of a pid is an index in a table pointing
   to a struct of dist_entry 
   slot 0 is reserved for ourselves allthough we don't hash ourselves to 0 
*/

#define THIS_NODE 0     /* replace the global variable "node" */

#define D_EXITING   1   /* Status field vals  for dist_enntry's */
#define D_REAL_BUSY 4
#define D_RESERVED  8   /* Set-cookie called thing */


#define MAXINDX 255

typedef struct cache {
    Eterm in_arr[MAXINDX];
    Eterm out_arr[MAXINDX];
} ErlCache;

typedef struct dist_entry {
    uint32 sysname;        /* pointer to name@host for efficiency */
    uint32 cid;            /* connection handler (pid or port), NIL == free */
    ErlLink* links;        /* external link/monitors/node links */
    uint32 status;         /* Slot status, like exiting reserved etc */
    Uint flags;            /* Distribution flags, like hidden, 
			      atom cache etc. */
    uint32 in_cookie;      /* cookie expected as input */
    uint32 out_cookie;     /* cookie sent with output */
    ErlCache* cache;       /* The atom cache */
    unsigned long version; /* Protocol version */
} DistEntry;

typedef struct _process_list {
    uint32 pid;			/* Waiting process. */
    struct _process_list* next;	/* Next waiting process. */
} ProcessList;

#define SMALL_IO_QUEUE 5   /* Number of fixed elements */

typedef struct {
    int size;       /* total size in bytes */

    SysIOVec* v_start;
    SysIOVec* v_end;
    SysIOVec* v_head;
    SysIOVec* v_tail;
    SysIOVec  v_small[SMALL_IO_QUEUE];

    DriverBinary** b_start;
    DriverBinary** b_end;
    DriverBinary** b_head;
    DriverBinary** b_tail;
    DriverBinary*  b_small[SMALL_IO_QUEUE];
} ErlIOQueue;

typedef struct line_buf {  /* Buffer used in line oriented I/O */
    int bufsiz;              /* Size of character buffer */
    int ovlen;               /* Length of overflow data */
    int ovsiz;               /* Actual size of overflow buffer */
    char data[1];            /* Starting point of buffer data,
			      data[0] is a flag indicating an unprocess CR,
			      The rest is the overflow buffer. */
} LineBuf;

typedef struct port {
    Eterm id;                   /* The Port id of this port */
    Eterm connected;            /* A connected process */
    Eterm caller;		/* Current caller. */
    uint32 status;   		 /* Status and type flags */
    ErlLink* links;              /* List of links */
    uint32 bytes_in;             /* Number of bytes read */
    uint32 bytes_out;            /* Number of bytes written */
    ErlTimer tm;                 /* Timer entry */
    ErlIOQueue ioq;              /* driver accessible i/o queue */
    int    dslot;                /* Dist slot used in DISTRIBUTION */
    char *name;		         /* String used in the open */
    struct driver_entry* drv_ptr;
    long drv_data;
    ProcessList *suspended;	 /* List of suspended processes. */
    LineBuf *linebuf;            /* Buffer to hold data not ready for
				    process to get (line oriented I/O)*/
    int control_flags;		 /* Flags for port_control()  */
} Port;

/* Driver handle (wrapper for old plain handle) */
#define ERL_DE_OK      0
#define ERL_DE_UNLOAD  1
#define ERL_DE_RELOAD  2

typedef struct {
    void* handle;           /* Handle for DLL or SO (for dynamic drivers). */
    int   ref_count;
    int   status;
    int   (*cb)();
    void** ca[4];           /* max 4 args now */
} DE_Handle;

/*
 * This structure represents a link to the next driver.
 */

typedef struct de_list {
    DriverEntry *drv;		/* Pointer to entry for driver. */
    DE_Handle* de_hndl;	     /* Handle for DLL or SO (for dynamic drivers). */
    struct de_list *next;	/* Pointer to next. */
} DE_List;

extern DE_List *driver_list;

/* Max no. of drivers (linked in and dynamically loaded. Each table
 * entry uses 4 bytes.
 */
#define DRIVER_TAB_SIZE 16

#define port_index(p)	((port_number(p)) % (erl_max_ports))

/*
** Just like the driver binary but with initial flags
** Note that the two structures Binary and DriverBinary HAVE to
** be equal except for extra fields in the beginning of the struct.
** DriverBinary is defined in driver.h.
** When driver_alloc_binary is called, a Binary is allocated, but 
** the pointer returned is to the address of the first element that
** also occurs in the DriverBinary struct (driver.*binary takes care if this).
** The driver need never know about additions to the internal Binary of the
** emulator. One should however NEVER be sloppy when mixing DriverBinary
** and Binary, the macros below can convert one type to the other, as they both
** in reality are equal.
*/
typedef struct binary {
    unsigned flags;
    /* Add fields BEFORE this, otherwise the drivers crash */
    int orig_size;
    int refc;
    char orig_bytes[1]; /* to be continued */
} Binary;

#define Binary2DriverBinary(B) ((DriverBinary *) (&((B)->orig_size)))
#define DriverBinary2Binary(D) ((Binary *) \
				(((char *) (D)) - \
				 ((char *) &(((Binary *) 0)->orig_size))))

/* A "magic" binary flag */
#define BIN_FLAG_MATCH_PROG 1

/*
 * This structure represents one type of a binary in a process.
 */

typedef struct proc_bin {
    Eterm thing_word;		/* Subtag REFC_BINARY_SUBTAG. */
    Uint size;			/* Binary size in bytes. */
    struct proc_bin *next;	/* Pointer to next ProcBin. */
    Binary *val;		/* Pointer to Binary structure. */
    byte *bytes;		/* Pointer to the actual data bytes. */
} ProcBin;

/*
 * ProcBin size in Eterm words.
 */
#define PROC_BIN_SIZE (sizeof(ProcBin)/sizeof(Eterm))

/*
 * This structure represents a 'fun' (lambda). It is stored on
 * process heaps. It has variable size depending on the size
 * of the environment.
 */

typedef struct erl_fun_thing {
    Eterm thing_word;		/* Subtag FUN_SUBTAG. */
    Uint num_free;		/* Number of free variables (in env). */
    struct erl_fun_thing* next;	/* Next fun in mso list. */
    Module* modp;		/* Pointer to module for 'fun'. */
    Uint index;			/* Index into fun table. */
    Uint uniq;			/* Uniq reference for fun. */
    Eterm creator;		/* Pid of creator process (contains node). */
    Eterm env[1];		/* Environment (free variables). */
} ErlFunThing;

/* ERL_FUN_SIZE does _not_ include space for the environment */
#define ERL_FUN_SIZE ((sizeof(ErlFunThing)/sizeof(Eterm))-1)

/* arrays that get malloced at startup */
extern Port* erts_port;
extern DistEntry* dist_addrs;
extern byte*      tmp_buf;

extern uint32 node_cookie;
extern int    tot_bin_allocated;
extern int    this_creation;
extern uint32 this_node;         /* mysyst@myhost    */
extern uint32 context_switches;	/* no of context switches */
extern uint32 bytes_out;        /* No bytes written out */
extern uint32 bytes_in;         /* No bytes sent into the system */
extern uint32 display_items;	/* no of items to display in traces etc */
extern uint32 reductions;	/* total number of reductions */
extern uint32 garbage_cols;	/* no of garbage collections */
extern uint32 reclaimed;	/* no of words reclaimes in GC's */
extern uint32 display_loads;	/* print info about loaded modules */
extern uint32 do_time;		/* set at clock interupt */
extern uint32 last_reds;	/* to calculate no of reds since last call */
extern int    MAXDIST;

#define HS_FIBONACCI 0		/* Fibonacci */
#define HS_FIBONACCI_SLOW 1	/* Fibonacci with slowdown for big heaps */
#define HS_POWER_TWO 2		/* Powers of two */
#define HS_POWER_TWO_MINUS_ONE 3 /* Powers of two minus one word */

extern int heap_series;		/* Series to use for heap size. */
extern int erts_backtrace_depth;
extern Uint16 erts_max_gen_gcs;

extern uint32 bif_gc;           /* gc calls by bif */
extern int bif_reductions;      /* reductions + fcalls (when doing call_bif) */
extern int stackdump_on_exit;

/* For the fix allocator */
extern int process_desc;
extern int table_desc;
extern int atom_desc;
extern int export_desc;
extern int module_desc;
extern int preg_desc;
extern int link_desc;
extern int plist_desc;
extern int mesg_desc;

#ifdef DEBUG
extern uint32 verbose;		/* noisy mode = 1 */
#endif

extern Eterm system_seq_tracer;
#ifdef INSTRUMENT
#define INSTR_SEND_SIZES_MAX 65535
extern uint32 instr_send_sizes[INSTR_SEND_SIZES_MAX];
#endif

/*
 * Here is an implementation of a lightweiht stack.
 *
 * Use it like this:
 *
 * DECLARE_ESTACK(Stack)	(At the start of a block)
 * ...
 * ESTACK_PUSH(Stack, Term)
 * ...
 * if (ESTACK_ISEMPTY(Stack)) {
 *    Stack is empty
 * } else {
 *    Term = ESTACK_POP(Stack);
 *    Process popped Term here
 * }
 * ...
 * DESTROY_ESTACK(Stack)
 */
 
Eterm* erl_grow_stack(Eterm* ptr, size_t new_size);
#define ESTK_CONCAT(a,b) a##b
#define ESTK_SUBSCRIPT(s,i) *((Eterm *)((byte *)ESTK_CONCAT(s,_start) + (i)))
#define DEF_ESTACK_SIZE (16*sizeof(Eterm))

#define DECLARE_ESTACK(s)						\
    Eterm ESTK_CONCAT(s,_default_stack)[DEF_ESTACK_SIZE/sizeof(Eterm)];	\
    Eterm* ESTK_CONCAT(s,_start) = ESTK_CONCAT(s,_default_stack);	\
    size_t ESTK_CONCAT(s,_sp) = 0;					\
    size_t ESTK_CONCAT(s,_size) = DEF_ESTACK_SIZE

#define DESTROY_ESTACK(s)						\
do {									\
    if (ESTK_CONCAT(s,_start) != ESTK_CONCAT(s,_default_stack)) {	\
	sys_free(ESTK_CONCAT(s,_start));				\
    }									\
} while(0)

#define ESTACK_PUSH(s, x)							\
do {										\
    if (ESTK_CONCAT(s,_sp) == ESTK_CONCAT(s,_size)) {				\
	ESTK_CONCAT(s,_size) *= 2;						\
	ESTK_CONCAT(s,_start) =							\
	    erl_grow_stack(ESTK_CONCAT(s,_start), ESTK_CONCAT(s,_size));	\
    }										\
    ESTK_SUBSCRIPT(s,ESTK_CONCAT(s,_sp)) = (x);					\
    ESTK_CONCAT(s,_sp) += sizeof(Eterm);					\
} while(0)

#define ESTACK_ISEMPTY(s) (ESTK_CONCAT(s,_sp) == 0)
#define ESTACK_POP(s)								\
((ESTK_CONCAT(s,_sp) -= sizeof(Eterm)), ESTK_SUBSCRIPT(s,ESTK_CONCAT(s,_sp)))

/* flags  for the port status info*/

#define FREE          0
#define CONNECTED     (1 << 0)
#define EXITING       (1 << 1)
#define DISTRIBUTION  (1 << 2)
#define BINARY_IO     (1 << 3)
#define SOFT_EOF      (1 << 4)
#define PORT_BUSY     (1 << 5)  /* Flow control on ports */
#define CLOSING       (1 << 6)  /* Port is closing (no i/o accepted ) */
#define SEND_CLOSED   (1 << 7)  /* Send a closed message when terminating */
#define LINEBUF_IO    (1 << 8)  /* Line orinted io on port */

/* binary.c */

Eterm new_binary(Process*, byte*, int);
Eterm new_binary_arith(Process*, byte*, int);
Eterm erts_realloc_binary(Eterm bin, size_t size);
void erts_cleanup_mso(ProcBin* pb);

/* bif.c */
EXTERN_FUNCTION(void, queue_monitor_message, (Process *, Ref *, uint32, uint32, uint32));
EXTERN_FUNCTION(void, print_timer_info, (CIO));
EXTERN_FUNCTION(void, erts_init_bif, (void));

/* beam_load.c */
EXTERN_FUNCTION(int, bin_load, (uint32, uint32, byte*, int));
EXTERN_FUNCTION(void, init_load, (_VOID_));
Eterm* find_function_from_pc(uint32* pc);

/* break.c */
EXTERN_FUNCTION(void, init_break_handler, (_VOID_));
EXTERN_FUNCTION(void, process_info, (CIO));
EXTERN_FUNCTION(void, print_process_info, (Process*, CIO));
EXTERN_FUNCTION(void, info, (CIO));
EXTERN_FUNCTION(void, loaded, (CIO));

/* config.c */

void __noreturn erl_exit(int n, char*, ...);
void __noreturn erl_exit0(char *, int, int n, char*, ...);
EXTERN_FUNCTION(void, erl_error, (char*, va_list));

#define ERL_EXIT0(n,f)		erl_exit0(__FILE__, __LINE__, n, f)
#define ERL_EXIT1(n,f,a)	erl_exit0(__FILE__, __LINE__, n, f, a)
#define ERL_EXIT2(n,f,a,b)	erl_exit0(__FILE__, __LINE__, n, f, a, b)
#define ERL_EXIT3(n,f,a,b,c)	erl_exit0(__FILE__, __LINE__, n, f, a, b, c)

/* copy.c */
void init_copy(void);
void copy_object(Eterm, Process*, uint32, Eterm*, Process*);
Uint size_object(Eterm);
Eterm copy_struct(Eterm, uint32, Eterm**, ErlOffHeap*);
Eterm copy_shallow(uint32*, uint32, uint32**, ErlOffHeap*);

/* dist.c */
EXTERN_FUNCTION(void, clear_cache, (int));
EXTERN_FUNCTION(void, create_cache, (int));
EXTERN_FUNCTION(void, delete_cache, (int));
EXTERN_FUNCTION(int, is_node_name, (char*, int));

EXTERN_FUNCTION(int,  do_net_exits, (int));
EXTERN_FUNCTION(void, init_dist, (_VOID_));
EXTERN_FUNCTION(int,  net_mess2, (int, byte*, int, byte*, int));
EXTERN_FUNCTION(int,  remove_from_link_list, (int, uint32, uint32));
EXTERN_FUNCTION(int,  add_to_link_list, (int, uint32, uint32));
EXTERN_FUNCTION(int,  sysname_to_dist_slot, (uint32));
EXTERN_FUNCTION(int,  find_or_insert_dist_slot, (uint32));
EXTERN_FUNCTION(int,  stop_dist, (_VOID_));
EXTERN_FUNCTION(int,  distribution_info, (CIO));

EXTERN_FUNCTION(void, erl_progressf, (char* format, ...));

#ifdef MESS_DEBUG
EXTERN_FUNCTION(void, print_pass_through, (int, byte*, int));
#endif

/* beam_emu.c */
EXTERN_FUNCTION(int, catchlevel, (Process*));
EXTERN_FUNCTION(void, init_emulator, (_VOID_));
EXTERN_FUNCTION(int, process_main, (Process*, int));

/* erl_init.c */
EXTERN_FUNCTION(void, erl_start, (int, char**));

/* external.c */
EXTERN_FUNCTION(int, to_external, (int, uint32, byte**));
Eterm from_external(int, Eterm**, byte**, ErlOffHeap*);
Eterm encode_size_struct(Eterm, unsigned);
EXTERN_FUNCTION(int, decode_size, (byte*, int));

/* fix_alloc.c */
EXTERN_FUNCTION(void, init_alloc, (_VOID_));
EXTERN_FUNCTION(int, init_fix_alloc, (int));
EXTERN_FUNCTION(int, fix_info, (int));
EXTERN_FUNCTION(int, fix_used, (int));
EXTERN_FUNCTION(int, new_fix_size, (int));
EXTERN_FUNCTION(void, fix_free, (int, uint32*));
#ifdef INSTRUMENT
EXTERN_FUNCTION(uint32*, fix_alloc_from, (int, int));
#endif
EXTERN_FUNCTION(uint32*, fix_alloc, (int));


/* ggc.c */
void init_gc(void);
int erts_garbage_collect(Process*, int, Eterm*, int);
int next_heap_size(int, int);
void stack_dump2(Process *, CIO);
Eterm erts_heap_sizes(Process* p);

/* io.c */

EXTERN_FUNCTION(void, wake_process_later, (uint32, Process*));
EXTERN_FUNCTION(int, open_driver, (struct driver_entry*,
				   uint32, char*, struct _SysDriverOpts*));
EXTERN_FUNCTION(void, close_port, (uint32));
EXTERN_FUNCTION(void, init_io, (_VOID_));
EXTERN_FUNCTION(void, cleanup_io, (_VOID_));
EXTERN_FUNCTION(void, do_exit_port, (uint32, uint32, uint32));
void port_command(Eterm, uint32, uint32);
EXTERN_FUNCTION(int, port_control, (Process*, Port*, uint32,
				    uint32, uint32*));
int write_port(Eterm caller_id, int p, Eterm list);
EXTERN_FUNCTION(void, print_port_info, (int, CIO));
EXTERN_FUNCTION(void, dist_port_command, (Port*, byte*, int));
EXTERN_FUNCTION(void, input_ready, (int, int));
EXTERN_FUNCTION(void, output_ready, (int, int));
EXTERN_FUNCTION(int, driver_output, (int, char*, int));
EXTERN_FUNCTION(int, driver_failure, (int, int));
EXTERN_FUNCTION(void, driver_report_exit, (int, int));
EXTERN_FUNCTION(void, set_busy_port, (int, int));
EXTERN_FUNCTION(LineBuf *, allocate_linebuf, (int));

/* time.c */
EXTERN_FUNCTION(void, increment_time, (int));
EXTERN_FUNCTION(void, bump_timer, (_VOID_));
EXTERN_FUNCTION(void, init_time, (_VOID_));
EXTERN_FUNCTION(void, erl_set_timer, (ErlTimer*,ErlTimeoutProc,ErlCancelProc,
				      void*, uint32));
EXTERN_FUNCTION(void, erl_cancel_timer, (ErlTimer*));
EXTERN_FUNCTION(uint32, time_left, (ErlTimer *));
EXTERN_FUNCTION(int, next_time, (_VOID_));

#ifdef DEBUG
EXTERN_FUNCTION(void, p_slpq, (_VOID_));
#endif

/* utils.c */
#define erl_printf sys_printf
#define erl_putc   sys_putc

EXTERN_FUNCTION(void, erl_suspend, (Process*, uint32));
EXTERN_FUNCTION(void, erl_resume, (Process*));

EXTERN_FUNCTION(int, list_length, (uint32));
Export* erts_find_function(Eterm, Eterm, int);
int erts_is_builtin(Eterm, Eterm, int);
EXTERN_FUNCTION(uint32, double_to_integer, (Process*, double));
extern Uint32 make_broken_hash(Eterm, Uint32);
extern Uint32 make_phash(Eterm, Uint32);
extern Uint32 make_hash(Eterm, Uint32);

EXTERN_FUNCTION(int, send_error_to_logger, (Eterm));
#ifdef INSTRUMENT
EXTERN_FUNCTION(void*, safe_alloc_from, (int, unsigned int));
EXTERN_FUNCTION(void*, safe_realloc_from, (int, void*,unsigned int));
EXTERN_FUNCTION(void*, safe_sl_alloc_from, (int, unsigned int));
EXTERN_FUNCTION(void*, safe_sl_realloc_from, (int, void*,unsigned int,unsigned int));
#endif
EXTERN_FUNCTION(void*, safe_alloc, (unsigned int));
EXTERN_FUNCTION(void*, safe_realloc, (void*,unsigned int));
EXTERN_FUNCTION(void*, safe_sl_alloc, (unsigned int));
EXTERN_FUNCTION(void*, safe_sl_realloc, (void*,unsigned int,unsigned int));
EXTERN_FUNCTION(Process*, pid2proc, (uint32));
EXTERN_FUNCTION(void, display, (uint32, CIO));
EXTERN_FUNCTION(void, ldisplay, (uint32, CIO, int));
EXTERN_FUNCTION(void, print_atom, (int, CIO));
EXTERN_FUNCTION(void, erts_init_utils, (void));

extern int eq(Eterm, Eterm);
#define EQ(x,y) (((x) == (y)) || (is_not_both_immed((x),(y)) && eq((x),(y))))

extern int cmp(Eterm, Eterm);
#define cmp_lt(a,b)	(cmp((a),(b)) < 0)
#define cmp_le(a,b)	(cmp((a),(b)) <= 0)
#define cmp_eq(a,b)	(cmp((a),(b)) == 0)
#define cmp_ne(a,b)	(cmp((a),(b)) != 0)
#define cmp_ge(a,b)	(cmp((a),(b)) >= 0)
#define cmp_gt(a,b)	(cmp((a),(b)) > 0)

#define CMP_LT(a,b)	((a) != (b) && cmp_lt((a),(b)))
#define CMP_GE(a,b)	((a) == (b) || cmp_ge((a),(b)))
#define CMP_EQ(a,b)	((a) == (b) || cmp_eq((a),(b)))
#define CMP_NE(a,b)	((a) != (b) && cmp_ne((a),(b)))

int term_to_Uint(Eterm term, Uint *up);

void trace_send(Process*, Eterm, Eterm);
void trace_receive(Process*, Eterm);
Uint32 erts_call_trace(Process *p, Eterm mfa[], Binary *match_spec, Eterm* args, int local);
void erts_trace_return(Process* p, Eterm* fi, Eterm retval);
void erts_trace_return_to(Process *p, Uint *pc);
void trace_sched(Process*, Eterm);
void trace_proc(Process*, Process*, Eterm, Eterm);
void trace_proc_spawn(Process*, Eterm pid, Eterm mod, Eterm func, Eterm args);
void save_calls(Process *p, Export *);
void trace_gc(Process *p, uint32 what);
Uint erts_trace_flag2bit(Eterm flag);
Eterm erts_bif_trace(int bif_index, Process* p, 
		     Eterm arg1, Eterm arg2, Eterm arg3, Uint *I);

EXTERN_FUNCTION(int,  member, (uint32, uint32));
EXTERN_FUNCTION(void, bin_write, (CIO, byte*, int));
EXTERN_FUNCTION(int, intlist_to_buf, (uint32, byte*, int));
EXTERN_FUNCTION(char*, int_to_buf, (int, char*));
EXTERN_FUNCTION(uint32, buf_to_intlist, (uint32**, byte*, int, uint32));
EXTERN_FUNCTION(int, io_list_to_buf, (uint32, char*, int));
EXTERN_FUNCTION(int, io_list_len, (uint32));
EXTERN_FUNCTION(int, is_string, (uint32));
EXTERN_FUNCTION(int, do_load, (uint32, uint32,
			       byte*, int));
EXTERN_FUNCTION(void, erl_at_exit, (FUNCTION(void,(*),(void*)), void*));
EXTERN_FUNCTION(uint32, collect_memory, (Process *));
EXTERN_FUNCTION(void, dump_memory_to_fd, (int));
EXTERN_FUNCTION(int, dump_memory_data, (const char *));

Eterm erts_mixed_plus(Process* p, Eterm arg1, Eterm arg2);
Eterm erts_mixed_minus(Process* p, Eterm arg1, Eterm arg2);
Eterm erts_mixed_times(Process* p, Eterm arg1, Eterm arg2);
Eterm erts_mixed_div(Process* p, Eterm arg1, Eterm arg2);
Eterm erts_int_div(Process* p, Eterm arg1, Eterm arg2);
Eterm erts_int_rem(Process* p, Eterm arg1, Eterm arg2);
Eterm erts_band(Process* p, Eterm arg1, Eterm arg2);
Eterm erts_bor(Process* p, Eterm arg1, Eterm arg2);
Eterm erts_bxor(Process* p, Eterm arg1, Eterm arg2);

Uint erts_current_reductions(Process* current, Process *p);

#ifdef DEBUG
EXTERN_FUNCTION(void, upp, (byte*, int));
EXTERN_FUNCTION(void, pat, (uint32));
EXTERN_FUNCTION(void, pinfo, (_VOID_));
EXTERN_FUNCTION(void, pp, (Process*));
EXTERN_FUNCTION(void, ppi, (uint32));
EXTERN_FUNCTION(void, pba, (Process*, int));
EXTERN_FUNCTION(void, td, (uint32));
EXTERN_FUNCTION(void, ps, (Process*, uint32*));
#endif

#define seq_trace_output(token, msg, type, receiver, process) \
seq_trace_output_generic((token), (msg), (type), (receiver), (process), NIL)
#define seq_trace_output_exit(token, msg, type, receiver, exitfrom) \
seq_trace_output_generic((token), (msg), (type), (receiver), NULL, (exitfrom))
void seq_trace_output_generic(Eterm token, Eterm msg, Uint type, 
			      Eterm receiver, Process *process, Eterm exitfrom);

int seq_trace_update_send(Process *process);

Eterm erts_seq_trace(Process *process, 
		     Eterm atom_type, Eterm atom_true_or_false, 
		     int build_result);

int erts_set_trace_pattern(Eterm* mfa, int specified, Binary* match_prog_set,
			   int on, int is_local);

extern int erts_match_spec_is_on;
extern Binary* erts_default_match_spec;
extern int erts_match_local_functions;

/*
** Call_trace uses this API for the parameter matching functions
*/
    struct erl_heap_fragment* saved_program_buf;

#define MatchSetRef(MPSP) 			\
do {						\
    if ((MPSP) != NULL) {			\
	++((MPSP)->refc);			\
    }						\
} while (0)

#define MatchSetUnref(MPSP)					\
do {								\
    if (((MPSP) != NULL) && (--((MPSP)->refc) <= 0)) {	\
	erts_match_set_free(MPSP);				\
    }								\
} while(0)

#define MatchSetGetSource(MPSP) erts_match_set_get_source(MPSP)

extern Binary *erts_match_set_compile(Process *p, Eterm matchexpr);
Eterm erts_match_set_lint(Process *p, Eterm matchexpr); 
extern Eterm erts_match_set_run(Process *p, Binary *mpsp, 
				Eterm *args, int num_args,
				Uint32 *return_flags);
extern void erts_match_set_free(Binary *mpsp);
extern Eterm erts_match_set_get_source(Binary *mpsp);

#define MATCH_SET_RETURN_TRACE 0x1 /* return trace requested */
#define MATCH_SET_RETURN_TO_TRACE 0x2 /* Misleading name, it is not actually
					 set by the match program, but by the
					 breakpoint functions */

/*
** Flag values when tracing bif
*/
#define BIF_TRACE_AS_LOCAL 0x1

#endif
