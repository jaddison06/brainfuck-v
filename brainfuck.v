module main

import os
import time

struct BrainfuckContext {
	visualise bool
	length_to_display int = 10
	pause_time_ms int = -1

mut:
	ptr int
	logger &Logger
	commands []string
	cells []byte
	cmd_index int
	jump_stack []int
	output string
	tick_count int
}

fn (mut ctx BrainfuckContext) init() {
	ctx.logger.info("Initialising Brainfuck")
	ctx.cells = []byte{len: 30000, init: 0}
	ctx.jump_stack = []int{}
}

fn (mut ctx BrainfuckContext) run() {
	ctx.logger.info("Running Brainfuck")
	
	ctx.logger.debug("Commands: ")
	for i in 0..ctx.commands.len {
		cmd := ctx.commands[i]
		mut msg := "$i: ${ctx.commands[i]}"
		
		if cmd == "[" {
			close := ctx.find_next_close_bracket_index(i, false)
			if close == -1 {
				msg += " (couldn't find close!)"
			} else {
				msg += " (closed @ $close)"
			}
		}

		ctx.logger.debug(msg)

	}
	
	for ctx.cmd_index < ctx.commands.len  {
		if ctx.visualise {
			println("\ncmd $ctx.cmd_index\ntick $ctx.tick_count")
			
			// print cells
			for b in ctx.cells[..ctx.length_to_display] {
				print("| $b ")
			}
			println("|")
			
			// print spaces before pointer
			for b in ctx.cells[..ctx.ptr] {
				for _ in 0..b.str().len {
					print(" ")
				}
				print("   ")
			}
			// print pointer
			println("  ^")
			//println(ctx.ptr.str())
			
			// if we're pausing, pause. else, wait for enter
			if ctx.pause_time_ms < 0 {
				os.get_line()
			} else {
				time.sleep(ctx.pause_time_ms * time.millisecond)
			}
		}

		command := ctx.commands[ctx.cmd_index]
		ctx.logger.info("@$ctx.cmd_index, command is $command")
		match command {
			">" { ctx.pointer_right() }
			"<" { ctx.pointer_left() }
			"+" { ctx.incr_byte() }
			"-" { ctx.decr_byte() }
			"." { ctx.output() }
			"," { ctx.input() }
			"[" { ctx.jump_forward() }
			"]" { ctx.jump_backward() }
			else {} // we've already filtered out other chars
		}
		
		ctx.cmd_index++
		ctx.tick_count++

		// some programs will never exit, so it'll never get flushed and you'll end up w/ an empty logfile
		if ctx.tick_count % 15 == 0 {
			ctx.logger.flush()
		}
	}
	
	if ctx.output != "" {
		ctx.logger.info("Program output: $ctx.output") // it gets cached
	}
	
	//ctx.logger.flush()
}

fn (mut ctx BrainfuckContext) pointer_right() {
	ctx.logger.info("Incrementing bf data pointer")
	ctx.ptr++
	if ctx.ptr >= ctx.cells.len {
		ctx.logger.info("Pointer exceeded current cell size, allocating 1000 new bytes")
		for _ in 0..1000 {
			ctx.cells << 0
		}
	}
}

fn (mut ctx BrainfuckContext) pointer_left() {
	if ctx.ptr > 0 {
		ctx.logger.info("Decrementing bf data pointer")
		ctx.ptr--
	} else {
		ctx.logger.warn("Tried to decrement bf data pointer, but it was already 0")
	}
}

// returns an IMMUTABLE VALUE
fn (mut ctx BrainfuckContext) current_byte() byte {
	ctx.logger.info("Getting current bf byte")
	return ctx.cells[ctx.ptr]
}

fn (mut ctx BrainfuckContext) incr_byte() {
	ctx.logger.info("Incrementing bf byte")
	ctx.cells[ctx.ptr]++
	if ctx.current_byte() == 0 {
		ctx.logger.info("Wrapped bf byte upwards from 255->0")
	}
}

fn (mut ctx BrainfuckContext) decr_byte() {
	ctx.logger.info("Decrementing bf byte")
	ctx.cells[ctx.ptr]--
	if ctx.current_byte() == 255 {
		ctx.logger.info("Wrapped bf byte downwards from 0->255")
	}
}

fn (mut ctx BrainfuckContext) output() {
	output := ctx.current_byte().ascii_str()
	ctx.logger.info("Outputting current bf byte: $output")
	ctx.output += output
}

fn (mut ctx BrainfuckContext) input() {
	ctx.logger.info("Getting current bf byte from stdin")
	mut input := ""
	for input.len != 1 {
		println("Input: ")
		input = os.get_line()
		ctx.logger.info("User inputted $input")
	}
	ctx.logger.info("Input was valid")
	ctx.cells[ctx.ptr] = input.bytes()[0]
}

fn (mut ctx BrainfuckContext) find_next_close_bracket_index(start_index int, log bool) int {
	if log {
		ctx.logger.info("Finding next ] command (at $start_index)")
	}
	remaining_commands := ctx.commands[start_index..]
	mut index := -1
	mut depth := 0
	for i in 0..remaining_commands.len {
		if remaining_commands[i] == "[" {
			depth++
		}
		if remaining_commands[i] == "]" {
			depth--
			if depth == 0 {
				index = i
				break
			}
		}
	}

	// index is as an offset in remaining_commands
	if index != -1 {
		index += start_index
	}
	
	if log {
		ctx.logger.info("Found ] at $index")
	}

	return index
}

fn (mut ctx BrainfuckContext) jump_forward() {
	ctx.logger.info("Conditional forward jump")
	if ctx.current_byte() == 0 {
		ctx.logger.info("Byte is 0 - jumping")

		jump_index := ctx.find_next_close_bracket_index(ctx.cmd_index, true)
		if jump_index == -1 {
			ctx.logger.error("Couldn't find a matching ] for the [ at position $ctx.cmd_index")
		}
		ctx.cmd_index = jump_index
	} else {
		ctx.logger.info("Byte wasn't 0, adding current addr ($ctx.cmd_index) to jump stack")
		ctx.jump_stack << ctx.cmd_index
	}
}

fn (mut ctx BrainfuckContext) jump_backward() {
	ctx.logger.info("Conditional backward jump")
	if ctx.current_byte() != 0 {
		ctx.logger.info("Byte was zero, jumping")

		if ctx.jump_stack.len == 0 {
			// this won't throw if it's non-zero, which is friendly but doesn't really enforce good practice.
			ctx.logger.error("Tried to jump backward, but the jump stack is empty")
		}
		ctx.cmd_index = ctx.jump_stack.last()
		ctx.logger.info("Jumped to $ctx.cmd_index")
	} else {
		ctx.logger.info("Byte wasn't zero, popping jump stack & continuing")
		ctx.jump_stack.delete_last()
	}
}