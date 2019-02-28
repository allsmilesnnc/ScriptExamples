#
# Source File: FC.tcl
# Code written By: Scott Edge on 10/12/2018 and updated on 01/21/2019
#
#
set systemTime [clock seconds]
#
file copy /export/home/se1810/MYNAH/NMA/LOGS/FC.out /export/home/se1810/MYNAH/NMA/LOGS/FC.[clock format $systemTime -format %m-%d_%H:%M:%S]

# disable internal call backs and traces to improve performance.
set mytrace [xmySeDisableCallback]

# To achieve better script performance, disable language output from scripts by
# setting script output level
set xmyVar(OutputLevel) {childscr error script summary sutimage testobj user}

# 
# Log into NMA
#
set conn1 [xmyTermAsync connect  -size {24 80} ]
$conn1 wait -expect "$ "
$conn1 sendWait "telnet nmamwm1.lno.att.com 74\r" -expect "H\033\[0;1m\033\[4m\033\[0;39;1m"
$conn1 sendWait "m13478\r" -expect "H\033\[18;28H"
$conn1 sendWait "xxxxxxxx\r" -expect "8\033\[H"
$conn1 send -key ENTER
$conn1 wait -expect "H\033\[0;1m\033\[4m\033\[0;39;1m"
$conn1 send "1"
$conn1 send -key ENTER
$conn1 wait -expect "H\033\[0;1m\033\[4m\033\[0;39;1m"
$conn1 sendWait "w" -expect "3H"
$conn1 send -key ENTER
sleep 5

#
# Set up I/O
#
set results [ open /export/home/se1810/MYNAH/NMA/LOGS/FC.out a+ ]
set input [ open /export/home/se1810/MYNAH/NMA/FC_INPUT_DATA r ]

#
# Define procedures
#

proc arrow_left { conn_async l } {
for {set i 0} {$i < $l} {incr i} {
$conn_async send -key LEFT_ARROW
  }
}

proc arrow_up { conn_async u } {
for {set i 0} {$i < $u} {incr i} {
$conn_async send -key UP_ARROW
  }
}

proc arrow_right { conn_async r } {
for {set i 0} {$i < $r} {incr i} {
$conn_async send -key RIGHT_ARROW
  }
}

proc arrow_down { conn_async d } {
for {set i 0} {$i < $d} {incr i} {
$conn_async send -key DOWN_ARROW
  }
}

proc myTimeoutHandler {conn pkg} {
  global results
  global conn1
  global errorInfo
  global logid
  global market
  set dt [clock format [clock seconds] -format {%m/%d %H:%M:%S}]
  puts $results "$dt the FC ticket process timed out on this screen."
  set myscreen [join [$conn screen -region {1 1 80 24} ] \n]
  puts $results $myscreen
  puts $results "$dt disconnected from NMA"
  puts $results "$dt End of FC ticket Process"
  exit
}
set xmyVar(TimeoutHandler) myTimeoutHandler

#
# BEGIN WHILE LOOP HERE BY SETTING FILED NAMES AND LENGTHS
#

#set j 0
#while {$j<2} 
proc _set_up {} {
  global conn1
    arrow_up $conn1 5
    sleep 5
    arrow_right $conn1 1
    sleep 5
    $conn1 send -key TOP_1
    sleep 5
    arrow_up $conn1 1
    sleep 5
    $conn1 send "\t"
    sleep 5
    arrow_left $conn1 1
    sleep 5
    $conn1 send -key TOP_1
    sleep 5
    arrow_up $conn1 2
    sleep 5
    arrow_left $conn1 8
    sleep 5
    $conn1 send -key TOP_1
 }
    _set_up
    #
    # FC ticket
    #
proc _fc {} { 
  global conn1
  global results
    $conn1 send -key ENTER
    sleep 5
    $conn1 send -key ESC
    $conn1 sendWait "\033SF03" -expect "9;1m"
    set dt [clock format [clock seconds] -format {%m/%d %H:%M:%S}]
    sleep 5
    $conn1 send -key ESC
    $conn1 sendWait "\033SF05" -expect "9;1m"
    set msg_fld {24 1 5 1}
    $conn1 wait {[$conn1 compare -region $msg_fld -expect "Press"]} -timeout 15
    $conn1 send -key ESC
    $conn1 sendWait "\033SF05" -expect "9;1m"
    set msg_fld {24 1 6 1}
    $conn1 wait {[$conn1 compare -region $msg_fld -expect "entity"]} -timeout 15
    if {[regexp "completed" [join [$conn1 screen -region "24 20 10 1"] ""]]} {
       puts $results "$dt force clear completed."
       $conn1 send -key ESC
       $conn1 send "\033SF16" 
       } else {
         puts $results "$dt force clear failed."
         $conn1 send -key ESC
         $conn1 send "\033SF16" 
         }
}
  _fc
    #
    # Transfer Ticket to ltloop
    #
proc _transfer {} { 
  global conn1
    sleep 5
    $conn1 send -key LEFT_1
    sleep 5
    $conn1 send ".ticket"
    sleep 5
    $conn1 send -key LEFT_1
    sleep 5
    $conn1 send -key TOP_1 
    sleep 5
    arrow_right $conn1 3
    sleep 5
    $conn1 send -key TOP_4
    sleep 5
    $conn1 send "ltloop"
    sleep 5
    $conn1 send -key TOP_5
    sleep 5
}
    _transfer

    set x 0
    while {$x<9} {
        $conn1 send -key ENTER
        sleep 5
        _fc
        _transfer
        sleep 2
        incr x
    }
    #set myscreen [join [$conn1 screen -region {1 1 80 24} ] \n]
    #  puts $results $myscreen
    #incr j
#}
#
# Close files
#
close $input
close $results
# 
# Logout of NMA
#
$conn1 send -key LEFT_1
$conn1 wait -expect "9;1m"
$conn1 send "amp_login"
$conn1 send -key LEFT_1
$conn1 wait -expect "H\033\[0;1m\033\[4m\033\[0;39;1m"
$conn1 disconnect
