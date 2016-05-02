#Luke Kruas
#lek81@pitt.edu
#See readme file for details on program

.data

string1: .asciiz "\nThe Game Score Is "
string2: .asciiz " : "
eventqueue: .space 400 # reserves a block of 100 words
blaster: .space 2 #reserves the space so that we know the information at all times of the blaster
.text
###
####
####
#$5 can be used for bug_hits
#$t6 can be used for phaser firings 



poll2: 
la $v0,0xffff0000 # address for reading key press status
lw $t0,0($v0) # read the key press status
andi $t0,$t0,1
beq $t0,$0,poll2 # no key pressed
lw $t0,4($v0)

bkey2: 
addi $v0,$t0,-66 # check for center key press
bne $v0,$0,poll2 # invalid key, ignore it
j main#start main execution if the center key is pressed


main:
la $fp, eventqueue #set the function pointer to the eventqueue 

#this will allow us to use this register throughout the program to move the pointer based on where
#we want to view the events present in the queue 




#set the display with the orange destroyer at the bottom and saves its info to the blaster section of memory
li $a0, 32
li $a1, 63
li $a2, 2
li $s1, 32
jal _setLED

li $v0, 30
syscall
move $t7, $a0 #$t7 will contain the time step
#draw the first 3 bugs
jal drawBug
jal drawBug
jal drawBug
#this is the value of the resgister that controls how often a bug is added
li $s3, 10

poll:#begin looking at the keyboard 
bge $v1, 120, quit#2 minutes have elapsed
li $s5, 0
#creates the time step and moves it to $t7
la $v0,0xffff0000 # address for reading key press status
lw $t0,0($v0) # read the key press status
andi $t0,$t0,1
beq $t0,$0,continue # no key pressed
lw $t0,4($v0)

lkey: 
#s1 contains the offset 
addi $v0,$t0,-226 # check for left key press
bne $v0,$0,rkey # wasn't left key, so try right key
beq $s1, 0, poll
move $a0, $s1
li $a1, 63
li $a2, 0
jal _setLED
addi $a0, $a0, -1
li $a2, 2
jal _setLED
move $s1, $a0
j poll

rkey:

addi $v0,$t0,-227 # check for right key press
bne $v0,$0,upkey # wasn't right key, so check for center
beq $s1, 63, poll
move $a0, $s1
li $a1, 63
li $a2, 0
jal _setLED
addi $a0, $a0, 1
li $a2, 2
jal _setLED
move $s1, $a0
j poll

upkey: 
addi $v0,$t0,-224 # check for up key press
bne $v0,$0, downkey # wasn't up key, so try b key
addi $t6, $t6, 1
jal initial_pulse
j poll

downkey: 
#kill game and print out score
addi $v0,$t0,-225 # check for up key press
bne $v0,$0, bkey # wasn't up key, so try b key
li $v0, 4
la $a0, string1
syscall
#here print out the number of bug hits
li $v0, 1
move $a0, $t5
syscall
li $v0, 4
la $a0, string2
syscall
#here print out the phaser firing
li $v0, 1
move $a0, $t6
syscall
li $v0, 10
syscall

bkey: 
addi $v0,$t0,-66 # check for center key press
bne $v0,$0,continue # invalid key, ignore it
li $v0, 4
la $a0, string1
syscall
#here print out the number of bug hits
li $v0, 1
move $a0, $t5
syscall
li $v0, 4
la $a0, string2
syscall
#here print out the phaser firing
li $v0, 1
move $a0, $t6
syscall
li $v0, 10
syscall

continue:
#checks the time step to see if it should continue or not
li $v0, 30
syscall
sub $s4, $a0, $t7 #a1 needs to be >= 100 to process events in the queue 
bge $s4, 1000, process
j poll


process: 
#if a second has elapsed than process the events
bge  $s5, $k1, finish
addi $s5, $s5, 1
jal _remove_q
beq $a0, 1,pulse_move
beq $a0, 2, wave_choice
beq $a0, 3, bug_move
beq $a0, 4, game_over


#wave move 1 is different becuase it is the first occurance of a wave so it doesnt need to be shut off but the other waves do 
wave_choice:
bgt $a3, 1, wave_move
ble $a3, 1, wave_move_one

finish:
#check to see if we need to add a bug and if we do add them by going to jumper other wise check the keyboard again
addi $v1, $v1, 1#add 1 to the overall game counter
addi $t9, $t9, 1#add one to the step (we only add bugs every 3 steps)
li $v0, 30
syscall
move $t7, $a0
bge $t9, $s3, jumper
li $s5, 0
j poll 

jumper:
#jump to draw the 3 bugs 
li $t9, 0
beq $s3, 0, reset
subi $s3, $s3, 1
jal drawBug
jal drawBug
jal drawBug
j poll

reset:
#reset the counter for the adding of bugs
li $s3, 5
jal drawBug
jal drawBug
jal drawBug
j poll



drawBug:
#adds the bug to the display and then saves them onto the queue
move $s0, $ra
bge $t8, 65, poll
addi $t8, $t8, 1
li $a0, 0#set bounds for random num
li $a1, 63#set bounds for random num
li $v0, 42#random number syscall
syscall
li $a1, 0
li $a2, 3
jal _setLED
move $a2, $a1
move $a1, $a0
li $a0, 3
li $a3,0
jal _insert_q
jr $s0

_setLED:
	# byte offset into display = y * 16 bytes + (x / 4)
	sll	$t0,$a1,4      # y * 16 bytes
	srl	$t1,$a0,2      # x / 4
	add	$t0,$t0,$t1    # byte offset into display
	li	$t2,0xffff0008 # base address of LED display
	add	$t0,$t2,$t0    # address of byte with the LED
	# now, compute led position in the byte and the mask for it
	andi	$t1,$a0,0x3    # remainder is led position in byte
	neg	$t1,$t1        # negate position for subtraction
	addi	$t1,$t1,3      # bit positions in reverse order
	sll	$t1,$t1,1      # led is 2 bits
	# compute two masks: one to clear field, one to set new color
	li	$t2,3		
	sllv	$t2,$t2,$t1
	not	$t2,$t2        # bit mask for clearing current color
	sllv	$t1,$a2,$t1    # bit mask for setting color
	# get current LED value, set the new field, store it back to LED
	lbu	$t3,0($t0)     # read current LED value	
	and	$t3,$t3,$t2    # clear the field for the color
	or	$t3,$t3,$t1    # set color field
	sb	$t3,0($t0)     # update display
	jr	$ra
	
	
# int _getLED(int x, int y)
	#   returns the value of the LED at position (x,y)
	#
	#  arguments: $a0 holds x, $a1 holds y
	#  trashes:   $t0-$t2
	#  returns:   $v0 holds the value of the LED (0, 1, 2 or 3)
	#
_getLED:
	# byte offset into display = y * 16 bytes + (x / 4)
	sll  $t0,$a1,4      # y * 16 bytes
	srl  $t1,$a0,2      # x / 4
	add  $t0,$t0,$t1    # byte offset into display
	la   $t2,0xffff0008
	add  $t0,$t2,$t0    # address of byte with the LED
	# now, compute bit position in the byte and the mask for it
	andi $t1,$a0,0x3    # remainder is bit position in byte
	neg  $t1,$t1        # negate position for subtraction
	addi $t1,$t1,3      # bit positions in reverse order
    	sll  $t1,$t1,1      # led is 2 bits
	# load LED value, get the desired bit in the loaded byte
	lbu  $t2,0($t0)
	srlv $t2,$t2,$t1    # shift LED value to lsb position
	andi $v0,$t2,0x3    # mask off any remaining upper bits
	jr   $ra

#the main data structure for the program is a circular buffer eventqueue 
#there are 5 different parts of the queue that are as followed in order:
#first byte is the event type
	#1 pulse move
	#2 wave move
	#3 bug move
	#4 game over
#second byte is the x coordinate
#third byte is y coordinate
#fourth byte is radius
#fifth byte is the time start

_insert_q:
#insert event at the end of the queue
#there are 5 parameters to adding something to the queue which are stated above. They corrospond to the 
#following registers

#$a0 = event type 
#$a1 = x coordinate
#$a2 = y coordinate
#$a3 = radius
#$k0 = time start
#$k1 = the number of events on the queue (queue size)


sb $a0, ($fp)
sb $a1, 4($fp)
sb $a2, 8($fp)
sb $a3, 12($fp)
sb $k0, 16($fp)
addi $fp, $fp, 20
addi $k1, $k1, 1
jr $ra


_remove_q:
#remove event from the queue
li $t2, 20

mul $t2, $t2, $t4
la $t1, eventqueue 
add $t1, $t1, $t2
lb $a0, ($t1)
addi $t1, $t1, 4
lb $a1, ($t1)
addi $t1, $t1, 4
lb $a2, ($t1)
addi $t1, $t1, 4
lb $a3, ($t1)
addi $t1, $t1, 4
lb $k0, ($t1)
subi $k1, $k1, 1
addi $t4, $t4, 1#t4 will keep track of the location of the stack
jr $ra




_size_q:
#returns the size of the queue 
#for this function we will just return the value of the register that contains the size that we have 
#been keeping track of for each addition 
move $a0, $k1
li $v0, 1
syscall
move $v0, $k1
jr $ra

pulse_move:
#for pulse move we will take the values that were just returned from the queue and move the pulse up
#to do this we will take the value of the x and y coordinates and shut it off at that point and 
#move it up one every time it is called. After it is finished being moved we have to re add it to the queue
#after the call the following registers are as follows
#$a0 = function call (going to change this to the color of the pulse)
#$a1 = x coordinate (this will stay tthe same)
#$a2 = y coordinate (this will be subtracted by 1 to update the location
#$a3 = radius (not used)
#$k0 = time step 
move $a0, $a1
move $a1, $a2
li $a2, 0
jal _setLED
beq $a1, 1, erase_pulse
subi $a1, $a1, 1
ble $a0, 0, PM1
bge $a0, 63, PM1
ble $a1, 0, PM1
bge $a1, 63, PM1
li $a2, 1
jal _setLED
PM1:
li $a2, 1
move $a2, $a1
move $a1, $a0
li $a0, 1
jal _insert_q


j process


bug_hit:
#if a bug is hit than create the box around it and save it to the queue
addi $t5, $t5, 1
li $a2,0
jal _setLED#shut off LED 
li $a2,1
addi $a0, $a0, 1
jal _setLED#Right Midddle
BH1:
addi $a1, $a1, 1 
ble $a0, 0, BH2
bge $a0, 63, BH2
ble $a1, 0, BH2
bge $a1, 63, BH2
jal _setLED#Bottom Right
BH2:
subi $a1, $a1, 2
ble $a0, 0, BH3
bge $a0, 63, BH3
ble $a1, 0, BH3
bge $a1, 63, BH3
jal _setLED#Top Right
BH3:
subi $a0, $a0, 2
ble $a0, 0, BH4
bge $a0, 63, BH4
ble $a1, 0, BH4
bge $a1, 63, BH4
jal _setLED#Left Top
BH4:
addi $a1, $a1, 1
ble $a0, 0, BH5
bge $a0, 63, BH5
ble $a1, 0, BH5
bge $a1, 63, BH5
jal _setLED#Middle Left
BH5:
addi $a1, $a1, 1
ble $a0, 0, BH6
bge $a0, 63, BH6
ble $a1, 0, BH6
bge $a1, 63, BH6
jal _setLED#Right Bottom
BH6:
addi $a0, $a0, 1
ble $a0, 0, BH7
bge $a0, 63, BH7
ble $a1, 0, BH7
bge $a1, 63, BH7
jal _setLED#Middle Bottom
BH7:
subi $a1, $a1, 2
ble $a0, 0, BH8
bge $a0, 63, BH8
ble $a1, 0, BH8
bge $a1, 63, BH8
jal _setLED#Top Middle
BH8:
move $a2, $a1
move $a1, $a0
li $a0, 2
li $a3, 1
jal _insert_q
j poll



erase_pulse:
#erase the pulse just doesnt add it back to the queue so it wont be on the screen anymore
j process

initial_pulse:
#inital pulse saves it up one from the X coordinate of the blaster and then adds it to the queue
move $a0, $s1
li $a1, 62 #the y value will always be 61 (1 less than the 62 it is orignally set to) one step after being fired
li $a2, 1 #make the pulse be red
li $a3, 0
jal _setLED
move $a1, $a0
li $a0, 1
li $a2, 62 #the y value will always be 61 (1 less than the 62 it is orignally set to) one step after being fired
li $a3, 0 
jal _insert_q
j poll

clear_wave: 
#once the wave is >10 it is erased by shutting off the leds at the location of the radius
move $a0, $a1
move $a1, $a2
li $a2, 0
jal _setLED
CW1:
sub $a0, $a0, $a3
sub $a1, $a1, $a3
ble $a0, 0, CW2
bge $a0, 63, CW2
ble $a1, 0, CW2
bge $a1, 63, CW2
li $a2, 0
jal _setLED#Top Left
CW2:
add $a1, $a1, $a3
ble $a0, 0, CW3
bge $a0, 63, CW3
ble $a1, 0, CW3
bge $a1, 63, CW3
li $a2, 0
jal _setLED#Middle Left
CW3:
add $a1, $a1, $a3
ble $a0, 0, CW4
bge $a0, 63, CW4
ble $a1, 0, CW4
bge $a1, 63, CW4
li $a2, 0
jal _setLED#Bottom Left
CW4:
add $a0, $a0, $a3
ble $a0, 0, CW5
bge $a0, 63, CW5
ble $a1, 0, CW5
bge $a1, 63, CW5
li $a2, 0
jal _setLED#Bottom Middle
CW5:
add $a0, $a0, $a3
ble $a0, 0, CW6
bge $a0, 63, CW6
ble $a1, 0, CW6
bge $a1, 63, CW6
li $a2, 0
jal _setLED#Bottom Right
CW6:
sub $a1, $a1, $a3
ble $a0, 0, CW7
bge $a0, 63, CW7
ble $a1, 0, CW7
bge $a1, 63, CW7
li $a2, 0
jal _setLED#Middle Right
CW7:
sub $a1, $a1, $a3
ble $a0, 0, CW8
bge $a0, 63, CW8
ble $a1, 0, CW8
bge $a1, 63, CW8
li $a2, 0
jal _setLED#Top Right
CW8:
sub $a0, $a0, $a3
ble $a0, 0, CW9
bge $a0, 63, CW9
ble $a1, 0, CW9
bge $a1, 63, CW9
li $a2, 0
jal _setLED#Middle Top
CW9:
j process 

wave_move_one:
#check if the radius is > 10
bgt $a3, 10, clear_wave
#PART1 CLEAR BITS FROM LAST RADIUS
move $a0, $a1
move $a1, $a2
li $a2, 0
addi $a1, $a1, 1
ble $a0, 0, WMO1
bge $a0, 63, WMO1
ble $a1, 0, WMO1
bge $a1, 63, WMO1
jal _setLED#shut off middle led
WMO1:
add $a0, $a0, $a3
add $a1,$a1, $a3
ble $a0, 0, WMO2
bge $a0, 63, WMO2
ble $a1, 0, WMO2
bge $a1, 63, WMO2
jal _setLED#bottom right turn off
WMO2:
sub $a1, $a1, $a3
ble $a0, 0, WMO3
bge $a0, 63, WMO3
ble $a1, 0, WMO3
bge $a1, 63, WMO3
jal _setLED#right Middle turn off
WMO3:
sub $a1, $a1, $a3
ble $a0, 0, WMO4
bge $a0, 63, WMO4
ble $a1, 0, WMO4
bge $a1, 63, WMO4
jal _setLED#right top turn off
WMO4:
sub $a0, $a0, $a3
ble $a0, 0, WMO5
bge $a0, 63, WMO5
ble $a1, 0, WMO5
bge $a1, 63, WMO5
jal _setLED#middlet top turn off
WMO5:
sub $a0, $a0, $a3
ble $a0, 0, WMO6
bge $a0, 63, WMO6
ble $a1, 0, WMO6
bge $a1, 63, WMO6
jal _setLED#left top turn off
WMO6:
add $a1, $a1, $a3
ble $a0, 0, WMO7
bge $a0, 63, WMO7
ble $a1, 0, WMO7
bge $a1, 63, WMO7
jal _setLED#left middle turn off
WMO7:
add $a1, $a1, $a3
ble $a0, 0, WMO8
bge $a0, 63, WMO8
ble $a1, 0, WMO8
bge $a1, 63, WMO8
jal _setLED#left botom turn off
WMO8:
add $a0, $a0, $a3
ble $a0, 0, WMO9
bge $a0, 63, WMO9
ble $a1, 0, WMO9
bge $a1, 63, WMO9
jal _setLED#botom middle turn off
WMO9:
sub $a1, $a1, $a3 #back to middle

#PART 2 DRAW NEW WAVE
li $a2, 1
addi $a3, $a3, 1
add $a0, $a0, $a3
add $a1,$a1, $a3
jal _setLED#bottom right turn on
subi $a1, $a1, 1
ble $a0, 0, BR1
bge $a0, 63, BR1
ble $a1, 0, BR1
bge $a1, 63, BR1
jal _getLED
beq $v0, 3, bug_hit
BR1:
addi $a1, $a1, 1
sub $a1, $a1, $a3
ble $a0, 0, RM1
bge $a0, 63, RM1
ble $a1, 0, RM1
bge $a1, 63, RM1
jal _setLED#right Middle turn on
subi $a1, $a1, 1
jal _getLED
beq $v0, 3, bug_hit
addi $a1, $a1, 1
RM1:
sub $a1, $a1, $a3
ble $a0, 0, RT1
bge $a0, 63, RT1
ble $a1, 0, RT1
bge $a1, 63, RT1
jal _setLED#right top turn on
subi $a1, $a1, 1
jal _getLED
beq $v0, 3, bug_hit
addi $a1, $a1, 1
RT1:
sub $a0, $a0, $a3
ble $a0, 0, MT1
bge $a0, 63, MT1
ble $a1, 0, MT1
bge $a1, 63, MT1
jal _setLED#middlet top turn on
subi $a1, $a1, 1
jal _getLED
beq $v0, 3, bug_hit
addi $a1, $a1, 1
MT1:
sub $a0, $a0, $a3
ble $a0, 0, LT
bge $a0, 63, LT
ble $a1, 0, LT
bge $a1, 63, LT
jal _setLED#left top turn on
subi $a1, $a1, 1
jal _getLED
beq $v0, 3, bug_hit
addi $a1, $a1, 1
LT:
add $a1, $a1, $a3
ble $a0, 0, LM1
bge $a0, 63, LM1
ble $a1, 0, LM1
bge $a1, 63, LM1
jal _setLED#left middle turn on
subi $a1, $a1, 1
jal _getLED
beq $v0, 3, bug_hit
addi $a1, $a1, 1
LM1:
add $a1, $a1, $a3
ble $a0, 0, LB1
bge $a0, 63, LB1
ble $a1, 0, LB1
bge $a1, 63, LB1
jal _setLED#left botom turn on
subi $a1, $a1, 1
jal _getLED
beq $v0, 3, bug_hit
addi $a1, $a1, 1
LB1:
add $a0, $a0, $a3
ble $a0, 0, BM1
bge $a0, 63, BM1
ble $a1, 0, BM1
bge $a1, 63, BM1
jal _setLED#botom middle turn on
subi $a1, $a1, 1
jal _getLED
beq $v0, 3, bug_hit
addi $a1, $a1, 1
BM1:
sub $a1, $a1, $a3 #back to middle

#insert it into the queue
move $a2, $a1
move $a1, $a0
li $a0, 2
jal _insert_q



j process

wave_move:
#moves the wave by one in all directions and shuts off he LED at the prev radius
#check if the radius is > 10
bgt $a3, 10, clear_wave
#PART1 CLEAR BITS FROM LAST RADIUS
move $a0, $a1
move $a1, $a2
li $a2, 0
jal _setLED#shut off middle led
BR2:
add $a0, $a0, $a3
add $a1,$a1, $a3
ble $a0, 0, MR2
bge $a0, 63, MR2
ble $a1, 0, MR2
bge $a1, 63, MR2
jal _setLED#bottom right turn off
MR2:
sub $a1, $a1, $a3
ble $a0, 0, TR2
bge $a0, 63, TR2
ble $a1, 0, TR2
bge $a1, 63, TR2
jal _setLED#right Middle turn off
TR2:
sub $a1, $a1, $a3
ble $a0, 0, TM2
bge $a0, 63, TM2
ble $a1, 0, TM2
bge $a1, 63, TM2
jal _setLED#right top turn off
TM2:
sub $a0, $a0, $a3
ble $a0, 0, LT2
bge $a0, 63, LT2
ble $a1, 0, LT2
bge $a1, 63, LT2
jal _setLED#middlet top turn off
LT2:
sub $a0, $a0, $a3
ble $a0, 0, LM2
bge $a0, 63, LM2
ble $a1, 0, LM2
bge $a1, 63, LM2
jal _setLED#left top turn off
LM2:
add $a1, $a1, $a3
ble $a0, 0, LB2
bge $a0, 63, LB2
ble $a1, 0, LB2
bge $a1, 63, LB2
jal _setLED#left middle turn off
LB2:
add $a1, $a1, $a3
ble $a0, 0, BM2
bge $a0, 63, BM2
ble $a1, 0, BM2
bge $a1, 63, BM2
jal _setLED#left botom turn off
BM2:
add $a0, $a0, $a3
ble $a0, 0, PART2
bge $a0, 63, PART2
ble $a1, 0, PART2
bge $a1, 63, PART2
jal _setLED#botom middle turn off
sub $a1, $a1, $a3 #back to middle
PART2:
#PART 2 DRAW NEW WAVE
li $a2, 1
addi $a3, $a3, 1
add $a0, $a0, $a3
add $a1,$a1, $a3
ble $a0, 0, DRM2
bge $a0, 63, DRM2
ble $a1, 0, DRM2
bge $a1, 63, DRM2
jal _setLED#bottom right turn on
jal _getLED
beq $v0, 3, bug_hit
DRM2:
sub $a1, $a1, $a3
ble $a0, 0, DRM2
bge $a0, 63, DRM2
ble $a1, 0, DRM2
bge $a1, 63, DRM2
jal _setLED#right Middle turn on
jal _getLED
beq $v0, 3, bug_hit
DRT2:
sub $a1, $a1, $a3
ble $a0, 0, DTM2
bge $a0, 63, DTM2
ble $a1, 0, DTM2
bge $a1, 63, DTM2
jal _setLED#right top turn on
jal _getLED
beq $v0, 3, bug_hit
DTM2:
sub $a0, $a0, $a3
ble $a0, 0, DTL2
bge $a0, 63, DTL2
ble $a1, 0, DTL2
bge $a1, 63, DTL2
jal _setLED#middlet top turn on
jal _getLED
beq $v0, 3, bug_hit
DTL2:
sub $a0, $a0, $a3
ble $a0, 0, DLM2
bge $a0, 63, DLM2
ble $a1, 0, DLM2
bge $a1, 63, DLM2
jal _setLED#left top turn on
jal _getLED
beq $v0, 3, bug_hit
DLM2:
add $a1, $a1, $a3
ble $a0, 0, DBL2
bge $a0, 63, DBL2
ble $a1, 0, DBL2
bge $a1, 63, DBL2
jal _setLED#left middle turn on
jal _getLED
beq $v0, 3, bug_hit
DBL2:
add $a1, $a1, $a3
ble $a0, 0, DBM2
bge $a0, 63, DBM2
ble $a1, 0, DBM2
bge $a1, 63, DBM2
jal _setLED#left botom turn on
jal _getLED
beq $v0, 3, bug_hit
DBM2:
add $a0, $a0, $a3
ble $a0, 0, DM2
bge $a0, 63, DM2
ble $a1, 0, DM2
bge $a1, 63, DM2
jal _setLED#botom middle turn on
jal _getLED
DM2:
beq $v0, 3, bug_hit
sub $a1, $a1, $a3 #back to middle

#insert it into the queue
move $a2, $a1
move $a1, $a0
li $a0, 2
jal _insert_q
j process




bug_move:
#the bug move is very similar to the pulse move. For this to work we will take the bug off of the queue 
#and then take its X and Y coordinates. We will shut it off at the coordinates that are given and move 
#it down one iteration on the Y axis and turn it back on at this location. After this is done it 
#will need to be re added to the queue

move $a0, $a1
move $a1, $a2
li $a2, 0
jal _setLED
beq $a1, 62, process
##
addi $a1, $a1, 1 
jal _getLED
beq $v0, 1, bug_hit
addi $a1, $a1, 1
ble $a0, 0, A2
bge $a0, 63, A2
ble $a1, 0, A2
bge $a1, 63, A2
jal _getLED
A2:
beq $v0, 1, bug_hit##
subi $a1, $a1, 1
ble $a0, 0, A3
bge $a0, 63, A3
ble $a1, 0, A3
bge $a1, 63, A3
li $a2, 3
jal _setLED
A3:
move $a2, $a1
li $a3, 0
move $a1, $a0
li $a0, 3
jal _insert_q
j process

game_over:
jr $ra

quit:
#game ends so print out the string and end the program
li $v0, 4
la $a0, string1
syscall
#here print out the number of bug hits
li $v0, 1
move $a0, $t5
syscall
li $v0, 4
la $a0, string2
syscall
#here print out the phaser firing
li $v0, 1
move $a0, $t6
syscall
li $v0, 10
syscall





