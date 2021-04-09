module main

import os

struct Context {
	log_path string
mut:
	logger &Logger = 0
	bf BrainfuckContext
}

fn (mut ctx Context) init() {
	ctx.logger = &Logger {
		path: ctx.log_path
		log_debugs: true
		
		print_messages: true
		// if we're visualising, writing to the file every time we want to print
		// is sloooooow, and the tick looks really ugly. doing it this way means that the new data
		// gets printed instantly, as soon as you press enter. however, if you're running something that
		// doesn't terminate then you could lose a few ticks on the ctrl-c.
		use_buffer: true
	}
	ctx.logger.init()
	
	ctx.bf = BrainfuckContext {
		logger: ctx.logger

		visualise: true
		length_to_display: 40
		//pause_time_ms: 0
	}
	ctx.bf.init()
}

fn (mut ctx Context) run() {
	ctx.init()
	
	if os.args.len > 2 {
		ctx.logger.error("Too many arguments!")
	}
	
	if os.args.len == 1 {
		ctx.repl()
	} else {
		ctx.parse_file(os.args[1])
	}
	
	// this will warn but not fail if we're not using a buffer, so it's safe to leave it here
	ctx.logger.flush()
}

fn (mut ctx Context) parse_file(fname string) {
	ctx.logger.info("parsing file $fname")
	file := os.read_file(fname) or { ctx.logger.error("Context.parse_file() failed opening file $fname: $err") panic("")}

	for char in file.split("") {
		if char in [">", "<", "+", "-", ".", ",", "[", "]"] {
			ctx.logger.debug("got command $char")
			ctx.bf.commands << char
		}
	}

	ctx.bf.run()
}

fn (mut ctx Context) repl() {
	ctx.logger.info("repl")
}

fn main() {
	mut ctx := Context {
		log_path: "logs/"
	}
	ctx.run()

}