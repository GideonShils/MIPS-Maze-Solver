#########################################################
#   $t9 - car location information			#
#   00000000|00000000|0000|0|0|0|0|0000|0|0|0|0		#
#      |	|          | | | |      | | | |  	#
#     row     column       N E S W      F L R B		#
#  		    					#
#   $t8 - movement instruction				#
#  	1 - move forward one block			#
#  	2 - turn left					#
#  	3 - turn right					#
#  	4 - update status				#
#########################################################

.data
	leftHandRow: .space 1000	# Row array
	leftHandCol: .space 1000	# Col array
.text

main:
	addi $t8, $zero, 1		# Move forward into maze
	jal _leftHandRule		# Jump to left hand rule
	
	addi $t8, $zero, 2		# Turn around
	addi $t8, $zero, 2		
	addi $t8, $zero, 1		# Move forward into maze
	
	add $a0, $zero, $v0		# Set argument for traceBack to return value of LHR
	jal _traceBack			# Jump to traceBack
	
	addi $t8, $zero, 2		# Turn around
	addi $t8, $zero, 2
	addi $t8, $zero, 1		# Move forward into maze
	
	addi $a0, $zero, 0		# Set first argument to current row
	addi $a1, $zero, 0		# Set second argument to current column
	addi $a2, $zero, 0		# Set third argument to previous row
	addi $a3, $zero, -1		# Set fourth argument to previous column
	jal _backtracking
	
	addi $v0, $zero, 10		# Terminate program
	syscall
	
# _leftHandRule
#
# Arguments:
#	None
#
# Return values: 
#	$v0 - number of moves
_leftHandRule:
	la $t1, leftHandRow		# Load leftHandRow into $t1
	la $t2, leftHandCol		# Load leftHandColumn into $t2
	add $t3, $zero, $zero		# Array index counter
	j checkLocation

checkLocation:
	andi $t0, $t9, 524288		# Check if bit 19 is 1 (meaning we are in 8th column)
	bne $t0, 0, return		# If it is, then we have reached end of maze
	
	srl $t0, $t9, 24		# Shift $t9 right to see row
	sb $t0, ($t1)			# Save row into row array
	addi $t1, $t1, 4		# Increment array to next location

	srl $t4, $t9, 16		# Shift $t9 right to see column
	andi $t4, $t4, 255		# AND with 128 to force all bits past 8 to be 0
	sb $t4, ($t2)			# Save column into column array
	addi $t2, $t2, 4		# Increment array to next location
	
	addi $t3, $t3, 1		# Increment number of moves
	add $t5, $zero, $zero		# Set index counter to 0 for checkDuplicate
	la $t6, leftHandRow		# Load leftHandRow into $t6
	la $t7, leftHandCol		# Load leftHandCol into $t7
	j duplicateLoop

duplicateLoop:
	beq $t5, $t3, makeMove		# If no duplicates, makeMove
	lb $s1, ($t6)			# Load next byte of leftHandRow into $s1
	lb $s2, ($t7)			# Load next byte of leftHandCol into $s2
	addi $t5, $t5, 1		# Increment index
	addi $t6, $t6, 4		# Move to next byte in row array
	addi $t7, $t7, 4		# Move to next byte in col array
	bne $s1, $t0, duplicateLoop	# Check if current row matches array row. If not, no duplicate loop
	bne $s2, $t4, duplicateLoop	# Check if current col matches array col. If not, no duplicate loop
	j clearArray			# If both row and col match, duplicate so clear array beyond this point
	
clearArray:
	add $t1, $zero, $t6		# Reset address to point just after found duplicate
	add $t2, $zero, $t7		# Reset address to point just after found duplicate
	add $t3, $zero, $t5		# Reset number of moves
	j makeMove			# Branch to makeMove
	
makeMove:
	andi $t0, $t9, 4		# Check if wall to left
	beq $t0, 0, turnLeft		# If no wall, branch to turnLeft
	
	andi $t0, $t9, 8		# Check if wall in front
	beq $t0, 0, moveForward		# If no wall, branch to moveForward
	
	andi $t0, $t9, 2		# Check if wall to right
	beq $t0, 0, turnRight		# If no wall, branch to turnRight
	
	j turnAround			# If cant move left right or forward, turn around

turnLeft:
	addi $t8, $zero, 2		# Turn left
	addi $t8, $zero, 1		# Move forward
	j checkLocation			# Determine next move
	
moveForward:
	addi $t8, $zero, 1		# Move forward
	j checkLocation			# Determine next move
	
turnRight:
	addi $t8, $zero, 3		# Turn right
	addi $t8, $zero, 1		# Move forward
	j checkLocation			# Determine next move

turnAround:
	addi $t8, $zero, 2		# Turn left
	addi $t8, $zero, 2		# Turn left
	addi $t8, $zero, 1		# Move forward
	j checkLocation			# Determine next move
	
return:
	add $v0, $zero, $t3		# Set return value to number of moves
	jr $ra				# Return to main

# _traceBack
#
# Arguments:
#	$a0 - Number of moves
#
# Return values:
#	None
_traceBack:
	add $t0, $zero, $a0		# Set $t0 to number of moves
	addi $t0, $t0, -2		# Subtract 2 from number of moves to account for index 0 and skip final spot
	mul $t0, $t0, 4			# Multiply number of moves by 4 to get offset of last move
	
	la $t1, leftHandRow		# Set $t1 to start of leftHandRow array
	la $t2, leftHandCol		# Set $t2 to start of leftHandCol array
	
	add $t1, $t1, $t0		# Set $t1 to address of last move (row)
	add $t2, $t2, $t0		# Set $t2 to address of last move (col)
	
	j checkLocationBack		# Jump to make move back
	
checkLocationBack:
	beq $t0, -4, lastMove		# If counter equals 0, branch to finish
	
	srl $t3, $t9, 24		# Shift $t9 right to see row

	srl $t4, $t9, 16		# Shift $t9 right to see column
	andi $t4, $t4, 255		# AND with 128 to force all bits past 8 to be 0
	
	lb $t7, ($t1)
	lb $s1, ($t2)
	
	beq $t3, $t7, sameRow		# If next move is in same row, branch to sameRow
	beq $t4, $s1, sameCol		# If next move is in same col, branch to sameCol
	
sameRow:
	slt $t5, $s1, $t4		# Is next col in lower (left) or higher (right) col?
	beq $t5, 1, lowerCol		# If next col is lower, branch to lower col
	j higherCol			# If next col is higher, branch to higher col
	
lowerCol:
	srl $t6, $t9, 8			# Shift right 8 to put direction bits in LSB 4
	andi $t6, $t6, 15		# AND to set $t6 to direction facing
	
	beq $t6, 1, moveBack		# If car is facing east, move forward
	
	addi $t8, $zero, 2		# Otherwise turn 90 degres
	j lowerCol

higherCol:
	srl $t6, $t9, 8			# Shift right 8 to put direction bits in LSB 4
	andi $t6, $t6, 15		# AND to set $t6 to direction facing
	
	beq $t6, 4, moveBack		# If car is facing west, move forward
	
	addi $t8, $zero, 3		# Otherwise turn 90 degrees
	j higherCol

sameCol:
	slt $t5, $t7, $t3		# Is next row in lower (up) or higher (down) col?
	beq $t5, 1, lowerRow		# If next row is lower, branch to lower row
	j higherRow			# If next row is higher, branch to higher row
	
lowerRow:
	srl $t6, $t9, 8			# Shift right 8 to put direction bits in LSB 4
	andi $t6, $t6, 15		# AND to set $t6 to direction facing
	
	beq $t6, 8, moveBack		# If car is facing north, move forward
	
	addi $t8, $zero, 2		# Otherwise turn 90 degres
	j lowerRow
	
higherRow:
	srl $t6, $t9, 8			# Shift right 8 to put direction bits in LSB 4
	andi $t6, $t6, 15		# AND to set $t6 to direction facing
	
	beq $t6, 2, moveBack		# If car is facing south, move forward
	
	addi $t8, $zero, 2		# Otherwise turn 90 degres
	j higherRow
	
moveBack:
	addi $t8, $zero, 1		# Move forward
	
	addi $t1, $t1, -4		# Move to next spot in row array
	addi $t2, $t2, -4		# Move to next spot in col array
	addi $t0, $t0, -4		# Decrement counter
	j checkLocationBack		# Determine next move
	
lastMove:
	srl $t6, $t9, 8			# Check if car facing west
	andi $t6, $t6, 15		
	
	beq $t6, 1, returnBack		# If it is, jump to returnBack
	
	addi $t8, $zero, 2		# Otherwise, turn 90 degrees
	j lastMove			# Loop

returnBack:
	addi $t8, $zero, 1		# Move forward out of maze
	jr $ra				# Return

# _backtracking
#
# Arguments:
#	$a0 - Current row
#	$a1 - Current column
#	$a2 - Previous row
#	$a3 - Previous column
#
# Return values:
#	$v0 - 1 if true (found solution), 2 if false (not found)
_backtracking:
	andi $t0, $t9, 524288		# Check if bit 19 is 1 (meaning we are in 8th column)
	bne $t0, 0, found		# If it is, then we have reached end of maze
	j faceNorth

found:
	addi $v0, $zero, 1		# Set return to 1 (true)
	jr $ra				# Return
	
faceNorth:
	srl $t1, $t9, 8			# Shift right 8 to put direction bits in LSB 4
	andi $t1, $t1, 15		# AND to set $t6 to direction facing
	
	beq $t1, 8, checkNorth		# If car is facing north, move forward
	
	addi $t8, $zero, 2		# Otherwise turn 90 degres
	j faceNorth			# Loop
	
checkNorth:
	andi $t1, $t9, 8		# Check if wall to north
	bne $t1, 8, checkNorthPrevious	# If not, branch to checkNorthPrevious
	j faceWest			# Otherwise branch to faceEast
	
checkNorthPrevious:
	addi $t1, $a0, -1		# Set $t1 to next row
	beq $t1, $a2, faceWest		# If next row and previous row are same, branch to faceEast
	j moveNorth			# Otherwise, move North

moveNorth:
	addi $t8, $zero, 1		# Move forward
	
	addi $sp, $sp, -20		# Save current return & arguments
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	sw $a2, 12($sp)
	sw $a3, 16($sp)
	
	add $a2, $zero, $a0		# Set next row argument to current row
	add $a3, $zero, $a1		# Set next col argument to current col
	add $a0, $zero, $t1		# Set current row to next row
	add $a1, $zero, $a3		# Set current col to next col

	jal _backtracking
	
	lw $a3, 16($sp)			# Reload old arguments
	lw $a2, 12($sp)
	lw $a1, 8($sp)
	lw $a0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 20
	
	beq $v0, 1, found
	
	j faceWest

faceWest:
	srl $t1, $t9, 8			# Shift right 8 to put direction bits in LSB 4
	andi $t1, $t1, 15		# AND to set $t6 to direction facing
	
	beq $t1, 1, checkWest		# If car is facing west, move forward
	
	addi $t8, $zero, 2		# Otherwise turn 90 degres
	j faceWest			# Loop
	
checkWest:
	andi $t1, $t9, 8		# Check if wall to west
	bne $t1, 8, checkWestPrevious	# If not, branch to checkWestPrevious
	j faceSouth			# Otherwise branch to faceSouth
	
checkWestPrevious:
	addi $t1, $a1, -1		# Set $t1 to next col
	beq $t1, $a3, faceSouth		# If next col and previous col are same, branch to returnFalse
	j moveWest			# Otherwise, move West

moveWest:
	addi $t8, $zero, 1		# Move forward
	
	addi $sp, $sp, -20		# Save current return & arguments
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	sw $a2, 12($sp)
	sw $a3, 16($sp)
	
	add $a2, $zero, $a0		# Set next row argument to current row
	add $a3, $zero, $a1		# Set next col argument to current col
	add $a0, $zero, $a2		# Set current row to next row
	add $a1, $zero, $t1		# Set current col to next col

	jal _backtracking
	
	lw $a3, 16($sp)			# Reload old arguments
	lw $a2, 12($sp)
	lw $a1, 8($sp)
	lw $a0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 20
	
	beq $v0, 1, found		# If exit found, mark foundd
	
	j faceSouth			# Otherwise, return to previous location	

faceSouth:
	srl $t1, $t9, 8			# Shift right 8 to put direction bits in LSB 4
	andi $t1, $t1, 15		# AND to set $t6 to direction facing
	
	beq $t1, 2, checkSouth		# If car is facing south, move forward
	
	addi $t8, $zero, 2		# Otherwise turn 90 degres
	j faceSouth			# Loop
	
checkSouth:
	andi $t1, $t9, 8		# Check if wall to south
	bne $t1, 8, checkSouthPrevious	# If not, branch to checkSouthPrevious
	j faceEast			# Otherwise branch to faceWest
	
checkSouthPrevious:
	addi $t1, $a0, 1		# Set $t1 to next row
	beq $t1, $a2, faceEast		# If next col and previous col are same, branch to faceSouth
	j moveSouth			# Otherwise, move East

moveSouth:
	addi $t8, $zero, 1		# Move forward
	
	addi $sp, $sp, -20		# Save current return & arguments
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	sw $a2, 12($sp)
	sw $a3, 16($sp)
	
	add $a2, $zero, $a0		# Set next row argument to current row
	add $a3, $zero, $a1		# Set next col argument to current col
	add $a0, $zero, $t1		# Set current row to next row
	add $a1, $zero, $a3		# Set current col to next col

	jal _backtracking
	
	lw $a3, 16($sp)			# Reload old arguments
	lw $a2, 12($sp)
	lw $a1, 8($sp)
	lw $a0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 20
	
	beq $v0, 1, found
	
	j faceEast
	
faceEast:
	srl $t1, $t9, 8			# Shift right 8 to put direction bits in LSB 4
	andi $t1, $t1, 15		# AND to set $t6 to direction facing
	
	beq $t1, 4, checkEast		# If car is facing east, move forward
	
	addi $t8, $zero, 2		# Otherwise turn 90 degres
	j faceEast			# Loop
	
checkEast:
	andi $t1, $t9, 8		# Check if wall to east
	bne $t1, 8, checkEastPrevious	# If not, branch to checkEastPrevious
	j checkPrevious			# Otherwise branch to checkPrevious
	
checkEastPrevious:
	addi $t1, $a1, 1		# Set $t1 to next col
	beq $t1, $a3, checkPrevious	# If next col and previous col are same, branch to faceSouth
	j moveEast			# Otherwise, move East

moveEast:
	addi $t8, $zero, 1		# Move forward
	
	addi $sp, $sp, -20		# Save current return & arguments
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	sw $a2, 12($sp)
	sw $a3, 16($sp)
	
	add $a2, $zero, $a0		# Set next row argument to current row
	add $a3, $zero, $a1		# Set next col argument to current col
	add $a0, $zero, $a2		# Set current row to next row
	add $a1, $zero, $t1		# Set current col to next col

	jal _backtracking
	
	lw $a3, 16($sp)			# Reload old arguments
	lw $a2, 12($sp)
	lw $a1, 8($sp)
	lw $a0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 20
	
	beq $v0, 1, found
	
	j checkPrevious

checkPrevious:
	beq $a0, $a2, previousCol	# If current row and previous row are the same, branch
	beq $a1, $a3, previousRow
	
previousCol:
	slt $t1, $a1, $a3		# If current col < previous col, set $t1 to 1
	beq $t1, 1, faceBackEast
	j faceBackWest
	
faceBackEast:
	srl $t1, $t9, 8			# Shift right 8 to put direction bits in LSB 4
	andi $t1, $t1, 15		# AND to set $t6 to direction facing
	
	beq $t1, 4, goBack		# If car is facing east, move forward
	
	addi $t8, $zero, 2		# Otherwise turn 90 degres
	j faceBackEast			# Loop
	
faceBackWest:
	srl $t1, $t9, 8			# Shift right 8 to put direction bits in LSB 4
	andi $t1, $t1, 15		# AND to set $t6 to direction facing
	
	beq $t1, 1, goBack		# If car is facing west, move forward
	
	addi $t8, $zero, 2		# Otherwise turn 90 degres
	j faceBackWest			# Loop
	
previousRow:
	slt $t1, $a0, $a2		# If current row < previous row, set $t1 to 1
	beq $t1, 1, faceBackSouth
	j faceBackNorth

faceBackSouth:
	srl $t1, $t9, 8			# Shift right 8 to put direction bits in LSB 4
	andi $t1, $t1, 15		# AND to set $t6 to direction facing
	
	beq $t1, 2, goBack		# If car is facing south, move forward
	
	addi $t8, $zero, 2		# Otherwise turn 90 degres
	j faceBackSouth			# Loop

faceBackNorth:
	srl $t1, $t9, 8			# Shift right 8 to put direction bits in LSB 4
	andi $t1, $t1, 15		# AND to set $t6 to direction facing
	
	beq $t1, 8, goBack		# If car is facing north, move forward
	
	addi $t8, $zero, 2		# Otherwise turn 90 degres
	j faceBackNorth			# Loop

goBack:
	addi $t8, $zero, 1		# Move forward
	
	addi $v0, $zero, 0		# Set return value to 0 (false)
	jr $ra				# Return
