#
# FILE:         conways.asm
# AUTHOR:       Arun Philip (axp4487)
#
# DESCRIPTION:
#        An implementation of the cellular automaton algorithm by
#        John Conway, known as Conways Game of Life.
#        This implementation is written in MIPS assembly though it could
#        be easily ported over to other languages by following similar
#        procedures.
#
# ARGUMENTS:
#        None
#
# INPUT:
#        Board size, # of generations, # of initial living cells,
#        locations of initial live=ing cells.
#
# OUTPUT:
#        Iterations of the board over the number of generations
#


#
# DATA AREA
#
    .data

newline:                .asciiz   "\n"
title_msg:
                        .ascii    "\n*************************************\n"
                        .ascii    "****    Game of Life with Age    ****\n"
                        .asciiz   "*************************************\n"
enter_board_msg:        .asciiz   "\nEnter board size: "
enter_gen_msg:          .asciiz   "\nEnter number of generations to run: "
enter_cell_msg:         .asciiz   "\nEnter number of live cells: "
enter_loc_msg:          .asciiz   "\nStart entering locations\n"
gen_msg1:               .asciiz   "\n====    GENERATION "
gen_msg2:               .asciiz   "    ====\n"
err_board_msg:          .asciiz   "\nWARNING: illegal board size, try again: "
err_gen_msg:
    .asciiz   "\nWARNING: illegal number of generations, try again: "
err_cell_msg:
    .asciiz   "\nWARNING: illegal number of live cells, try again: "
err_loc_msg:            .asciiz   "\nERROR: illegal point location"
cell_states:            .ascii    "A"
symbols:                .ascii    " +-|"

                        # Since board uses characters, each cell is 1 byte
pop1:                   .space     930    # max board size =   30x30 cells
                                          #                  + 30     NULs
pop2:                   .space     930    # secondary board (same properties)


#
# CODE AREA
#
    .text
    .globl    main

#
# Description:  This routine performs the main execution of Life with Age.
# Arguments:    (nothing)
# Returns:      (nothing)
#
main:                                   # Executes the Life with Age program.
        addi  $sp, $sp, -4
        sw    $ra, 0($sp)               # store return address
        la    $a0, title_msg            # grab the title message
        jal   print_string
        j     board_prompt_msg

board_invalid:                          # Board Size
        la    $a0, err_board_msg
        jal   print_string
        j     board_prompt
board_prompt_msg:
        la    $a0, enter_board_msg      # grab enter board message
        jal   print_string
board_prompt:
        jal   read_int

        slti  $t0, $v0, 4               # validate board input
        bne   $t0, $zero, board_invalid
        slti  $t0, $v0, 31
        beq   $t0, $zero, board_invalid
board_valid:
        add   $s0, $v0, $zero           # s0 = size of the board
        j     gen_count_prompt_msg

gen_count_invalid:                      # Generation Count Limit
        la    $a0, err_gen_msg
        jal   print_string
        j     gen_count_prompt
gen_count_prompt_msg:
        la    $a0, enter_gen_msg
        jal   print_string
gen_count_prompt:
        jal   read_int
        slti  $t0, $v0, 0
        bne   $t0, $zero, gen_count_invalid
        slti  $t0, $v0, 21
        beq   $t0, $zero, gen_count_invalid
gen_count_valid:
        add   $s1, $v0, $zero           # s1 = number of generations
        j     live_cell_prompt_msg

live_cell_invalid:                      # Live Cell Count
        la    $a0, err_cell_msg
        jal   print_string
        j     live_cell_prompt
live_cell_prompt_msg:
        la    $a0, enter_cell_msg
        jal   print_string
live_cell_prompt:
        jal   read_int
        slti  $t0, $v0, 0
        bne   $t0, $zero, live_cell_invalid

        mult  $s0, $s0
        mflo  $t1
        slt   $t0, $v0, $t1
        beq   $t0, $zero, live_cell_invalid
live_cell_valid:
        add   $s2, $v0, $zero           # s2 = number of alive cells
        j     location_prompt


location_prompt:
        la    $a0, pop1                 # get pointer of population 1
        jal   clear_pop                 # initializing population board

        la    $a0, pop2                 # get pointer of population 2
        jal   clear_pop                 # initializing population board

        la    $a0, enter_loc_msg
        jal   print_string

        la    $a0, pop1
        add   $s3, $zero, $zero         # initialize loop counter for location
                                        #     input.
loc_loop:
        beq   $s2, $s3, start_life
        jal   read_int                  # read row value
        add   $a1, $v0, $zero
        jal   read_int                  # read col value
        add   $a2, $v0, $zero
        jal   valid_cell
        beq   $v0, $zero, loc_invalid
        la    $t0, cell_states
        lb    $a3, 0($t0)
        jal   set_cell
        addi  $s3, $s3, 1
        j     loc_loop
loc_invalid:
        la    $a0, err_loc_msg
        jal   print_string
        jal   print_newline
        j     done



start_life:
        add   $s3, $zero, $zero         # initialize loop counter for
                                        #     generations.
        add   $a0, $s3, $zero
        jal   print_gen_header
        la    $a0, pop1
        jal   print_pop

life_loop:
        beq   $s1, $s3, done
        add   $s5, $zero, $zero         # s5 = current row index
        add   $s6, $zero, $zero         # s6 = current column index
        addi  $s3, $s3, 1
        addi  $t0, $zero, 2
        div   $s3, $t0
        mfhi  $t0
        beq   $t0, $zero, even_board
odd_board:
        la    $t0, pop1
        la    $t1, pop2
        addi  $sp, $sp, -8
        sw    $t0, 0($sp)
        sw    $t1, 4($sp)
        j     gen_row_loop
even_board:
	la    $t0, pop2
        la    $t1, pop1
        addi  $sp, $sp, -8
        sw    $t0, 0($sp)
        sw    $t1, 4($sp)
gen_row_loop:
        beq   $s5, $s0, gen_done
        add   $a1, $s5, $zero
gen_col_loop:
        beq   $s6, $s0, gen_row_incr
        lw    $a0, 0($sp)
        add   $a2, $s6, $zero
        jal   count_neighbors

        lw    $a0, 0($sp)
        add   $s4, $v0, $zero           # s4 = neighbor count
        jal   is_alive
        bne   $v0, $zero, gen_col_alive
gen_col_dead:
        addi  $t0, $zero, 3
        beq   $s4, $t0, gen_col_dead_revive
        j     gen_col_done
gen_col_dead_revive:                    # If 3 surrounding cells,
                                        #     cell becomes alive.
        la    $t1, cell_states
        lb    $a3, 0($t1)
        lw    $a0, 4($sp)
        jal   set_cell
        j     gen_col_done
gen_col_alive:
        slti  $t0, $s4, 2               # If < 2 surrounding cells, cell dies
        addi  $t1, $zero, 3
        slt   $t1, $t1, $s4             # If 4+ surrounding cells, cell dies
        or    $t2, $t0, $t1
        bne   $t2, $zero, gen_col_alive_kill
                                        # If 2 or 3 surrounding cells,
                                        #     current cell stays alive and
                                        #     increments age.
        jal   get_cell
        addi  $a3, $v0, 1

        lw    $a0, 4($sp)
        jal   set_cell
        j     gen_col_done
gen_col_alive_kill:                     # kill off the current cell
        la    $t1, symbols
        lb    $a3, 0($t1)
        lw    $a0, 4($sp)
        jal   set_cell
        j     gen_col_done
gen_col_done:
        addi  $s6, $s6, 1               # column counter increments
        j     gen_col_loop
gen_row_incr:
        addi  $s5, $s5, 1               # row counter increments
        add   $s6, $zero, $zero         # reset the column index
        j     gen_row_loop
gen_done:
        add   $a0, $s3, $zero
        jal   print_gen_header
        lw    $a0, 4($sp)
        jal   print_pop
        lw    $a0, 0($sp)
        jal   clear_pop

        addi  $sp, $sp, 8
        j     life_loop
done:
        lw    $ra, 0($sp)
        addi  $sp, $sp, 4
        jr    $ra

#
# Description:  This routines reads a number to print from a0,
#                   then prints it out.
# Arguments:    a0:  the number to print
# Returns:      (nothing)
#
print_int:
        add   $sp, $sp, -4
        sw    $v0, 0($sp)
        li    $v0, 1
        syscall                         # print out the number in a0
        lw    $v0, 0($sp)
        add   $sp, $sp, 4
        jr    $ra

#
# Description:  This routine prints out a string pointed to by a0.
# Arguments:    a0:  a pointer to the string to print
# Returns:      (nothing)
#
print_string:
        li    $v0, 4
        syscall                         # print string
        jr    $ra

#
# Description:  This routine prints out a character pointed to by a0.
# Arguments:    a0:  a pointer to the char to print
# Returns:      (nothing)
#
print_char:
        li    $v0, 11
        syscall                         # print string
        jr    $ra

#
# Description:  This  routine reads in a number and stores it's value into v0.
# Arguments:    (nothing)
# Returns:      v0:  integer that is read in
#
read_int:
        li    $v0, 5                    # set $v0 to READ_INT constant
        syscall
        jr    $ra

#
# Description:  This routine prints out a newline.
# Arguments:    (nothing)
# Returns:      (nothing)
#
print_newline:
        addi  $sp, $sp, -4
        sw    $a0, 0($sp)

        la    $a0, newline
        li    $v0, 4
        syscall                         # print newline

        lw    $a0, 0($sp)
        addi  $sp, $sp, 4
        jr    $ra

#
# Description:  This routine prints out the header for a cell population's
#                   generation.
# Arguments:    a0:  Generation Number
# Returns:      (nothing)
#
print_gen_header:
        addi  $sp, $sp, -4
        sw    $ra, 0($sp)

        add   $t0, $a0, $zero
        la    $a0, gen_msg1
        jal   print_string

        add   $a0, $t0, $zero
        jal   print_int

        la    $a0, gen_msg2
        jal   print_string

        lw    $ra, 0($sp)
        addi  $sp, $sp, 4
        jr    $ra

#
# Description:  This subroutine pritns out a cell population border.
# Example:      +-----+ for a 5^2 cell population
# Arguments:    s0:  the number of elements per row/column
# Returns:      (nothing)
#
print_pop_border:
        addi  $sp, $sp, -8
        sw    $ra, 0($sp)
        sw    $a0, 4($sp)
        la    $t0, symbols
        lb    $t1, 1($t0)               # t1 = '+' character
        lb    $t2, 2($t0)               # t2 = '-' character

        add   $a0, $t1, $zero
        jal   print_char

        add   $t3, $zero, $zero         # t3 = loop index
        add   $a0, $t2, $zero
print_pop_border_loop:
        beq   $t3, $s0, print_pop_border_done
        jal   print_char
        addi  $t3, $t3, 1               # column counter increments
        j     print_pop_border_loop
print_pop_border_done:
        add   $a0, $t1, $zero
        jal   print_char
        jal   print_newline
        lw    $a0, 4($sp)
        lw    $ra, 0($sp)
        addi  $sp, $sp, 8
        jr    $ra

#
# Description:  Prints out a cell population.
# Arguments:    a0:  memory address of cell population
#               s0:  the number of elements per row/column
# Returns:      (nothing)
#
print_pop:
        addi  $sp, $sp, -12
        sw    $ra, 0($sp)
        sw    $a0, 4($sp)
        sw    $s7, 8($sp)
        la    $t2, symbols
        lb    $s7, 3($t2)

        jal   print_pop_border
        add   $t0, $a0, $zero
        add   $t1, $zero, $zero
print_pop_loop:
        beq   $t1, $s0, print_pop_done

        add   $a0, $s7, $zero
        jal   print_char

        add   $a0, $t0, $zero
        jal   print_string

        add   $a0, $s7, $zero
        jal   print_char

        jal   print_newline
        addi  $t1, $t1, 1
        add   $t0, $t0, $s0
        add   $t0, $t0, 1
        j     print_pop_loop
print_pop_done:
        jal   print_pop_border
        lw    $s7, 8($sp)
        lw    $a0, 4($sp)
        lw    $ra, 0($sp)
        addi  $sp, $sp, 12
        jr    $ra

#
# Description:  This routine makes arrays of c-strings containing only spaces
#                   for an initial breeding ground for the game of life.
# Arguments:    a0:  the memory address of the population to "clear"
#               s0:  the number of elements per row/column
# Returns:      (nothing)
#
clear_pop:
        addi  $sp, $sp, -8
        sw    $ra, 0($sp)
        sw    $a0, 4($sp)
        add   $t0, $zero, $zero         # t0 = counter of row
        add   $t1, $zero, $zero         # t1 = counter of columns
        la    $t2, symbols
clear_pop_col_loop:
        beq   $t0, $s0, clear_pop_done
clear_pop_row_loop:
        beq   $t1, $s0, clear_pop_col_incr
        lb    $t3, 0($t2)
        sb    $t3, 0($a0)
        addi  $t1, $t1, 1               # column counter increments
        addi  $a0, $a0, 1               # mem offest increments
        j     clear_pop_row_loop
clear_pop_col_incr:
        sb    $zero, 0($a0)
        addi  $a0, $a0, 1               # mem offest increments
        addi  $t0, $t0, 1               # row counter increments
        add   $t1, $zero, $zero         # reset the column index
        j     clear_pop_col_loop
clear_pop_done:
        lw    $a0, 4($sp)
        lw    $ra, 0($sp)
        addi  $sp, $sp, 8
        jr    $ra

#
# Description:  This routine checks if an index is within bounds.
# Arguments:    a0:  value to check
#               s0:  the number of elements per row/column
# Returns:      v0:  0 if not valid
#                    1 if valid cell
#
valid_index:
        slti  $t0, $a0, 0               # check if row value is within bounds
        bne   $t0, $zero, valid_index_bad
        slt   $t0, $a0, $s0
        beq   $t0, $zero, valid_index_bad
        addi  $v0, $zero, 1
        jr    $ra
valid_index_bad:
        add   $v0, $zero, $zero
        jr    $ra

#
# Description:  This routine checks if a cell is within bounds.
# Arguments:    a0:  the memory address of the population
#               a1:  row index
#               a2:  column index
#               s0:  the number of elements per row/column
# Returns:      v0:  0 if not valid
#                    1 if valid cell
#
valid_cell:
        addi  $sp, $sp, -16
        sw    $ra, 0($sp)
        sw    $a0, 4($sp)
        sw    $a1, 8($sp)
        sw    $a2, 12($sp)
        add   $a0, $a1, $zero
        jal   valid_index
        beq   $v0, $zero, valid_cell_bad
        add   $a0, $a2, $zero
        jal   valid_index
        beq   $v0, $zero, valid_cell_bad
        lw    $a0, 4($sp)
        jal   is_alive
        bne   $v0, $zero, valid_cell_bad
        addi  $v0, $zero, 1
        j     valid_cell_done
valid_cell_bad:
        add   $v0, $zero, $zero
valid_cell_done:
        lw    $a2, 12($sp)
        lw    $a1, 8($sp)
        lw    $a0, 4($sp)
        lw    $ra, 0($sp)
        addi  $sp, $sp, 16
        jr    $ra

#
# Description:  Sets specific cell to specific value
# Arguments:    a0:  the memory address of the population
#               a1:  row index
#               a2:  column index
#               a3:  value to change cell to
#               s0:  number of rows/columns
# Returns:      (nothing)
#
set_cell:
        addi  $t2, $s0, 1               # needs to include one byte for null
        mult  $a1, $t2                  # row * length of each string (in bytes)
        mflo  $t1
        add   $t2, $a2, $t1             # get the total offset
        add   $t0, $a0, $t2             # add offset to initial pointer mem loc
        sb    $a3, 0($t0)
        jr    $ra

#
# Description:  Sets specific cell to specific value
# Arguments:    a0:  the memory address of the population
#               a1:  row index
#               a2:  column index
#               s0:  number of rows/columns
# Returns:      v0:  value of cell
#
get_cell:
        addi  $t2, $s0, 1               # needs to include one byte for null
        mult  $a1, $t2                  # row * length of each string (in bytes)
        mflo  $t1
        add   $t2, $a2, $t1             # get the total offset
        add   $t0, $a0, $t2             # add offset to initial pointer mem loc
        lb    $v0, 0($t0)
        jr    $ra

#
# Description:  Checks if cell index does not have living cell in it
# Arguments:    a0:  memory address of cell population
#               a1:  row index
#               a2:  column index
#               s0:  the number of elements per row/column
# Returns:      v0:  0 if cell is not empty
#                    1 if cell is empty
#
is_alive:
        addi  $sp, $sp, -8
        sw    $ra, 0($sp)
        sw    $s7, 4($sp)
        jal   get_cell
        la    $t0, symbols
        lb    $s7, 0($t0)
        add   $t0, $v0, $zero
        beq   $s7, $t0, is_alive_bad
        addi  $v0, $zero, 1
        j     is_alive_done
is_alive_bad:
        add   $v0, $zero, $zero
is_alive_done:
        lw    $s7, 4($sp)
        lw    $ra, 0($sp)
        addi  $sp, $sp, 8
        jr    $ra


#
# Description:  This routine counts the neighbors surrounding a specific cell.
# Arguments:    a0:  memory address of cell population
#               a1:  row index
#               a2:  column index
#               s0:  the number of elements per row/column
# Returns:      v0:  number of neighbors surrounding a specific cell
#
count_neighbors:
        addi  $sp, $sp, -44
        sw    $ra, 0($sp)
        sw    $a0, 4($sp)
        sw    $a1, 8($sp)
        sw    $a2, 12($sp)
        sw    $s1, 16($sp)               # s1 = upper row
        sw    $s2, 20($sp)              # s2 = lower row
        sw    $s3, 24($sp)              # s3 = leftmost column
        sw    $s4, 28($sp)              # s4 = rightmost column
        sw    $s5, 32($sp)              # s5 = neighbor counter
        sw    $s6, 36($sp)              # s6 = temporary row index
        sw    $s7, 40($sp)              # s7 = temporary column index
count_upper_row:                        # get the upper row index value
        addi  $a0, $a1, -1
        jal   valid_index
        beq   $v0, $zero, count_upper_row_fix
        add   $s1, $a0, $zero
        j     count_lower_row
count_upper_row_fix:                    # if the row is outside the population,
                                        #     loop the index back around.
        add   $s1, $s0, -1
count_lower_row:                        # repeat with other row and columns
        addi  $a0, $a1, 1
        jal   valid_index
        beq   $v0, $zero, count_lower_row_fix
        add   $s2, $a0, $zero
        j     count_left_col
count_lower_row_fix:
        add   $s2, $zero, $zero
count_left_col:
        addi  $a0, $a2, -1
        jal   valid_index
        beq   $v0, $zero, count_left_col_fix
        add   $s3, $a0, $zero
        j     count_right_col
count_left_col_fix:
        addi  $s3, $s0, -1
count_right_col:
        addi  $a0, $a2, 1
        jal   valid_index
        beq   $v0, $zero, count_right_col_fix
        add   $s4, $a0, $zero
        j     count_stuff
count_right_col_fix:
        add   $s4, $zero, $zero
count_stuff:                            # get count of surrounding neighbors
        add   $s6, $a1, $zero
        add   $s7, $a2, $zero
        lw    $a0, 4($sp)               # reload population

        add   $a1, $s1, $zero           # top left
        add   $a2, $s3, $zero
        jal   is_alive
        add   $s5, $v0, $zero           # increment neighbor counter
                                        #     if neighbor exists
                                        # repeat for all other cases

        add   $a1, $s1, $zero           # top middle
        add   $a2, $s7, $zero
        jal   is_alive
        add   $s5, $s5, $v0

        add   $a1, $s1, $zero           # top right
        add   $a2, $s4, $zero
        jal   is_alive
        add   $s5, $s5, $v0

        add   $a1, $s6, $zero           # middle left
        add   $a2, $s3, $zero
        jal   is_alive
        add   $s5, $s5, $v0

        add   $a1, $s6, $zero           # middle right
        add   $a2, $s4, $zero
        jal   is_alive
        add   $s5, $s5, $v0

        add   $a1, $s2, $zero           # bottom left
        add   $a2, $s3, $zero
        jal   is_alive
        add   $s5, $s5, $v0

        add   $a1, $s2, $zero           # bottom middle
        add   $a2, $s7, $zero
        jal   is_alive
        add   $s5, $s5, $v0

        add   $a1, $s2, $zero           # bottom right
        add   $a2, $s4, $zero
        jal   is_alive
        add   $s5, $s5, $v0

        add   $v0, $s5, $zero           # move neighbor counter to v0 register

        lw    $s7, 40($sp)              # retrieve old values of the registers
        lw    $s6, 36($sp)
        lw    $s5, 32($sp)
        lw    $s4, 28($sp)
        lw    $s3, 24($sp)
        lw    $s2, 20($sp)
        lw    $s1, 16($sp)
        lw    $a2, 12($sp)
        lw    $a1, 8($sp)
        lw    $a0, 4($sp)
        lw    $ra, 0($sp)
        addi  $sp, $sp, 44
        jr    $ra
