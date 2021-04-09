module main

import time
import os

struct Logger {
	path string
	use_buffer bool
	
	print_messages bool
	log_debugs bool
	
mut:
	fname string
	buf []string
}

// os.open_append seems to append stuff to the beginning instead of the end??
fn append_to_file(fname string, msg string) {
	current := os.read_file(fname) or { panic("append_to_file() failed to read file at $fname: $err") }
	os.write_file(fname, current + msg) or { panic("append_to_file() failed to write file at $fname: $err") }
}

fn (mut l Logger) init() {
	l.fname = (l.path + time.now().str() + ".log").replace(" ", "_").replace(":", "-")
	if l.use_buffer {
		l.buf = []string{}
	}
	
	if !os.exists(l.path) {
		os.mkdir_all(l.path) or { panic("Logger.init() failed creating dir tree for $l.path: $err") }
	}
	os.create(l.fname) or { panic("Logger.init() failed to create file at $l.fname: $err") }

}

// todo (jaddison): calling .write() on this File appends to the _start_??
fn (mut l Logger) get_fh() os.File {
	return os.open_append(l.fname) or { panic("Logger.get_fh() failed getting file handle for $l.fname: $err") }
}

fn (mut l Logger) append_msg(msg string) {
	append_to_file(l.fname, msg)
}

fn (mut l Logger) flush() {
	if !l.use_buffer {
		l.warn("Tried to flush buffer, but we're not using one")
		return
	}
	
	/*mut fh := l.get_fh()
	for line in l.buf {
		fh.write_str(line) or { panic("Logger.flush() failed writing log line $line to file $l.fname: $err") }
	}*/
	for line in l.buf {
		l.append_msg(line)
	}

	l.buf.clear()
}

fn (mut l Logger) msg(level string, msg string) {
	output := "$level (${time.now().str()}) - $msg\n"
	
	if  l.print_messages {
		print(output) // the newline is already there
	}
	
	if l.use_buffer {
		l.buf << output
	} else {
		//l.get_fh().write_str(output) or { panic("Logger.msg() failed writing log message $output to file $l.fname: $err") }
		l.append_msg(output)
	}
}

fn (mut l Logger) debug(msg string) {
	// debug messages will probably be spammy & overly verbose, so we can disable them
	if l.log_debugs {
		l.msg("DEBUG", msg)
	}
}

fn (mut l Logger) info(msg string) {
	l.msg("INFO", msg)
}

fn (mut l Logger) warn(msg string) {
	l.msg("WARN", msg)
}

fn (mut l Logger) error(msg string) {
	l.msg("ERROR", msg)
	l.flush()
	panic("Error - " + msg)
}