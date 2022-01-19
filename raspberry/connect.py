###
# set in launcher.sh to run recommender.py

# in recommender.py define a flag to check if it has worked today

# run in recommender.py the bluetooth.py untill a the phone is nearby

# if the phone is nearby, run the rest of the recommender.py

# add line at the end of recommender.py to turn flag on
###

import threading
import time
import datetime
from datetime import timedelta
from time import perf_counter

import pexpect
import switch
import pause
import recommender


has_recommended = False
phone_dectected = False
timer_started = False
SECONDS_TO_SEARCH = 20

child = pexpect.spawn("bluetoothctl")
child.send("scan on\n")
bdaddrs = []
bdaddrs1 = []




# while true:
#     bluetooth:


#def foo():
    #print(time.ctime())
    #Wthreading.Timer(10, foo).start()


#foo()
#print('Hola')

try:
	while True:
		print("Main loop running")
		while not phone_dectected:
			print("Waiting for the user to arrive home")
			child.expect(
				"Device (([0-9A-Fa-f]{2}:){5}([0-9A-Fa-f]{2}))", timeout=None)
			bdaddr = str(child.match.group(1))
			print(bdaddr)
			if bdaddr not in bdaddrs1:
				bdaddrs1.append(bdaddr)
				if bdaddr == "b'A8:91:3D:61:E9:E4'":
					print("The user's phone is nearby")
					phone_dectected = True
		bdaddrs1 = []	
				
		if not has_recommended:          
			print("Recommendation happening")
			#switch.switchon(1)
			recommender.main()
			has_recommended = True 
			
		if has_recommended:	
			today = datetime.datetime.now()
			#time = today.replace(day = today.day+1, hour=0, minute=0, second =0, microsecond =0)	
			#time = today.replace(day = today.day, hour=10, minute=8, second =0, microsecond =0)	
			time_to_continue = today + timedelta(minutes=1)
			print("Pausing now until", time_to_continue)
			pause.until(time_to_continue)
			print("Today is a new day")
			bdaddrs = []
			has_recommended = False
			
		while phone_dectected:
			if not timer_started:
				tic = time.perf_counter()
				timer_started = True
			print("The user is home")
			child.expect(
				"Device (([0-9A-Fa-f]{2}:){5}([0-9A-Fa-f]{2}))", timeout=None)
			bdaddr = str(child.match.group(1))
			print(bdaddr)
			toc = time.perf_counter()
			time_searched = toc - tic
			if bdaddr not in bdaddrs:
				bdaddrs.append(bdaddr)
			if "b'A8:91:3D:61:E9:E4'" in bdaddrs and time_searched > SECONDS_TO_SEARCH:
				# looked for enough time, clear the list
				bdaddrs = []
				timer_started = False
				print ("Clearing the list bdaddrs")
			
			# check if user's phone is not in the list and if the scan went through sufficient times		
			#if "b'A8:91:3D:61:E9:E4'" not in bdaddrs:
			if "b'A8:91:3D:61:E9:E4'" not in bdaddrs and time_searched > SECONDS_TO_SEARCH:
				print("The user's phone is not nearby")
				print("The user has left home")
				child1 = pexpect.spawn("bluetoothctl")
				child1.send("remove A8:91:3D:61:E9:E4")
				bdaddrs = []
				timer_started = False
				phone_dectected = False
				
		
		#bdaddrs = []
    

except KeyboardInterrupt:
    child.close()



