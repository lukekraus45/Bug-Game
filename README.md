# Bug-Game
A game that is written in MIPS and allows the user to fire a pulse to scare away bugs. Needs special MIPS software to run. Use the .jar file above and under tools select: Keyboard and LED Display Simulator  

Luke Kraus
lek81@pitt.edu
Assignment 1 Spring 2016
CS447
Recitation: Fri 2pm

Implementation:

For this project I used a circular buffer as suggested for the main implementation. To bein the project created the buffer and created 3 functions to work with the buffer. I made a read from buffer and write to buffer as well as sizeof() buffer functions. I tested these 3 functions and ensured that they worked properly. After I was able to verify that the buffer was working properly I was able to contiue working on the implementation. The next part of the project that I worked on was the keyboard polling. I used most of the code provided to us to get it to work. I kept one register set aside for the X value of the bug buster at the the bottom (orange dot) and then throughout the program anytime that the left arrow was pressed I moved it minus 1 x coordinate and if the right arrow was pressed I moved it 1 to the right. After I got these two keys to work I added the center button to be able to start and stop the program. To do this before the main function was called the program would wait until the center key was pressed. Once the center key was pressed it began the program and moved into the main execution. In the main loop it began by drawing the orange dot at the bottom and drawing the orignal 3 bugs. Once this happened it checked to see if any keys were pressed. If a key was pressed than it executed the correct function. For the left and right key the bug buster moved, if the down or center button was pressed the program quit and the score was printed out, and if the up arrow was pressed than a pulse was created and fired up. In order to process the events in the game the ciruclar queue was used. For each event the following format was used:
$a0 = event id (1= pulse move, 2= wave move, 3=bug move)
$a1 = x value
$a2 = y value
$a3 = radius (only used for wave move)

So for each event that was created the correct values were stored in each of the registers and then added to the queue. So if a bug was created than $a0 = 3, the x and y value were whatever they are, and radius is 0. Then I called the add to queue function and these were added to the queue. Whenever 1000 miliseconds (1 second) elapsed than events were processed. To do this I would take an item off the queue and read its ID. Based on the idea I would jump to the appropriate function. In each function I would move it correctly based on the ID and then save it back to the queue. After all the events were processed it waited again for 1 second to elapse. As a result of this the bugs would move down every 1 second and the pulse moves up every 1 second. To get the bugs to remove when hit I looked 1 y value ahead of the bug and if the color was red than the bug would be removed from the queue and a wave was created with a radius of 1. Than as long as the size of the radius was <=10 the wave would be expanded by 1 radius every step. If the wave hit another bug than it repeated this process. Another implementation detail was the 2 minute timer. To do this I set a register aside that increased by 1 every time step. As a result of this when the register was equal to 120 (120 seconds = 2 minutes) the program ended. Also whenever a pulse was fired or a bug was hit a register was increased so this was just printed out at the end of the program. To get the system time I was able to use syscall 30 to get the value. For adding bugs I began a counter at 10 (meaning I added a bug evey 10 seconds) and then decreased this value every time a bug was added. This just made the bugs come faster as the game progressed to add difficulty. 


Issues:
I don't believe that there are any issues with the program that I can see. There was 1 time during testing that the program just froze and nothing happened. I am not sure if this was an issue with MIPS or an issue with the code, but it hasn't happened since. I also have the time step set to 1000 miliseconds rather than the 100 that was suggested. This can be changed in the code by changing the bge 1000 to 100 if this is an issue.  
