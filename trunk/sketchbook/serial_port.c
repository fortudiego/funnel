/*
 * reference
 * http://www.easysw.com/~mike/serial/serial.html
 */

#if defined(__MINGW32__)
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <windows.h>
static char sGetCommState[] = "GetCommState";
static char sSetCommState[] = "SetCommState";
static char sGetCommTimeouts[] = "GetCommTimeouts";
static char sSetCommTimeouts[] = "SetCommTimeouts";
#define FMODE_READABLE  1
#define FMODE_WRITABLE  2
#define FMODE_READWRITE 3
#define FMODE_APPEND   64
#define FMODE_CREATE  128
#define FMODE_BINMODE   4
#define FMODE_SYNC      8
#define FMODE_WBUF     16
#define FMODE_RBUF     32
#define FMODE_WSPLIT  0x200
#define FMODE_WSPLIT_INITIALIZED  0x400
#else
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <termios.h>
#endif

#include <ruby.h>

static VALUE mFunnel;
static VALUE cSerialPort;

struct serial_port
{
#if defined(__MINGW32__)
	FILE *f;
	HANDLE fh;
	int mode;
#endif
	int fd;
	char buffer[128];
};

static void
sp_mark(struct serial_port *sp)
{
	
}

static void
sp_free(struct serial_port *sp)
{
	close(sp->fd);
	free(sp);
}

static VALUE
sp_allocate(VALUE klass)
{
	struct serial_port *sp = malloc(sizeof(*sp));
	sp->fd = -1;
	return Data_Wrap_Struct(klass, sp_mark, sp_free, sp);
}

static VALUE
sp_initialize(VALUE self, VALUE port, VALUE baudrate)
{
#if defined(__MINGW32__)
//  OpenFile *fp;
//  int fd;
//  HANDLE fh;
//  int num_port;
  char *_port;
  // char *ports[] = {
  // "COM1", "COM2", "COM3", "COM4",
  // "COM5", "COM6", "COM7", "COM8"
  // };
  DCB dcb;

	struct serial_port *sp;

	  COMMTIMEOUTS ctout;

	Data_Get_Struct(self, struct serial_port, sp);

//  NEWOBJ(sp, struct RFile);
//  rb_secure(4);
//  OBJSETUP(sp, self, T_FILE);
//  MakeOpenFile(sp, fp);

  Check_SafeStr(port);
  _port = RSTRING(port)->ptr;

  sp->fd = open(_port, O_BINARY | O_RDWR);
  if (sp->fd == -1)
    rb_sys_fail(_port);
  sp->fh = (HANDLE) _get_osfhandle(sp->fd);
  if (SetupComm(sp->fh, 1024, 1024) == 0) {
    close(sp->fd);
    rb_raise(rb_eArgError, "not a serial port");
  }

  dcb.DCBlength = sizeof(dcb);
  if (GetCommState(sp->fh, &dcb) == 0) {
    close(sp->fd);
    rb_sys_fail(sGetCommState);
  }
  dcb.fBinary = TRUE;
  dcb.fParity = FALSE;
  dcb.fOutxDsrFlow = FALSE;
//  dcb.fDtrControl = DTR_CONTROL_ENABLE;
  dcb.fDtrControl = DTR_CONTROL_DISABLE;
  dcb.fDsrSensitivity = FALSE;
//  dcb.fDsrSensitivity = TRUE;
  dcb.fTXContinueOnXoff = FALSE;
  dcb.fErrorChar = FALSE;
  dcb.fNull = FALSE;
  dcb.fAbortOnError = FALSE;
  dcb.XonChar = 17;
  dcb.XoffChar = 19;

	//modem parameters
  dcb.BaudRate = FIX2INT(baudrate);
  dcb.ByteSize = 8;
  dcb.StopBits = ONESTOPBIT;
  dcb.Parity = NOPARITY;

  if (SetCommState(sp->fh, &dcb) == 0) {
    close(sp->fd);
    rb_sys_fail(sSetCommState);
  }

  sp->f = (FILE *)rb_fdopen(sp->fd, "rb+");
  sp->mode = FMODE_READWRITE | FMODE_BINMODE | FMODE_SYNC;
//  return (VALUE) sp;

  if (GetCommTimeouts(sp->fh, &ctout) == 0)
    rb_sys_fail(sGetCommTimeouts);

    ctout.ReadIntervalTimeout = MAXDWORD;
    ctout.ReadTotalTimeoutMultiplier = MAXDWORD;
    ctout.ReadTotalTimeoutConstant = MAXDWORD - 1;

  if (SetCommTimeouts(sp->fh, &ctout) == 0)
    rb_sys_fail(sSetCommTimeouts);

	return self;
#else
	struct termios options;
	int _baudrate;
	struct serial_port *sp;

	Data_Get_Struct(self, struct serial_port, sp);

	sp->fd = open(RSTRING(port)->ptr, O_RDWR | O_NOCTTY | O_NDELAY);
	if (sp->fd == -1) {
		rb_sys_fail(RSTRING(port)->ptr);
	}

	if (tcgetattr(sp->fd, &options) == -1) {
		rb_sys_fail("tcgetattr");
	}

	switch (FIX2INT(baudrate)) {
		case 9600: _baudrate = B9600; break;
		case 19200: _baudrate = B19200; break;
		case 38400: _baudrate = B38400; break;
		case 57600: _baudrate = B57600; break;
//		case 76800: _baudrate = B76800; break;
		case 115200: _baudrate = B115200; break;
		case 230400: _baudrate = B230400; break;
		default:
			rb_raise(rb_eArgError, "unsupported baud rate"); break;
	}

	// set basic parameters
	options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
	options.c_cflag |= (CLOCAL | CREAD);

	// set baud rate
	cfsetispeed(&options, _baudrate);
	cfsetospeed(&options, _baudrate);

	// set data bits to 8 bit
	options.c_cflag &= ~CSIZE;
	options.c_cflag |= CS8;

	// set stop bits to 1 bit
	options.c_cflag &= ~CSTOPB;

	// set parity to none
	options.c_cflag &= ~PARENB;

#ifdef CNEW_RTSCTS
	// disable hardware flow control
	options.c_cflag &= ~CNEW_RTSCTS;
#endif

	if (tcsetattr(sp->fd, TCSANOW, &options) == -1) {
		rb_sys_fail("tcsetattr");
	}

	return self;
#endif
}

static VALUE
sp_write(VALUE self, VALUE data)
{
	int written_bytes;
	struct serial_port *sp;

	Data_Get_Struct(self, struct serial_port, sp);
	written_bytes = write(sp->fd, RSTRING(data)->ptr, RSTRING(data)->len);
	return INT2FIX(written_bytes);
}

static VALUE
sp_read(VALUE self, VALUE bytes)
{
	int read_bytes;
	struct serial_port *sp;

	Data_Get_Struct(self, struct serial_port, sp);
	read_bytes = read(sp->fd, sp->buffer, FIX2INT(bytes));
	return rb_str_new(sp->buffer, read_bytes);
}

static VALUE
sp_bytes_available(VALUE self)
{
#if defined(__MINGW32__)
	// DUMMY IMPLEMENTATION!!!
	int bytes = 1;
	struct serial_port *sp;
	DWORD errors;
	COMSTAT stat;
	
	Data_Get_Struct(self, struct serial_port, sp);

	if (!ClearCommError(sp->fh, &errors, &stat)) {
		rb_sys_fail("ClearCommError");
		return 0;
	}

	return INT2FIX(stat.cbInQue);
#else
	int bytes;
	struct serial_port *sp;

	Data_Get_Struct(self, struct serial_port, sp);
	ioctl(sp->fd, FIONREAD, &bytes);
	return INT2FIX(bytes);
#endif
}

void Init_serial_port()
{
	mFunnel = rb_define_module("Funnel");
	cSerialPort = rb_define_class_under(mFunnel, "SerialPort", rb_cObject);

	rb_define_alloc_func(cSerialPort, sp_allocate);
	rb_define_method(cSerialPort, "initialize", sp_initialize, 2);
	rb_define_method(cSerialPort, "write", sp_write, 1);
	rb_define_method(cSerialPort, "read", sp_read, 1);
	rb_define_method(cSerialPort, "bytes_available", sp_bytes_available, 0);
}