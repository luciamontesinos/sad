import pexpect
import switch

child = pexpect.spawn("bluetoothctl")
child.send("scan on\n")
bdaddrs = []

try:
    while True:
        child.expect(
            "Device (([0-9A-Fa-f]{2}:){5}([0-9A-Fa-f]{2}))", timeout=None)
        bdaddr = str(child.match.group(1))
        print(bdaddr)
        if bdaddr not in bdaddrs:
            bdaddrs.append(bdaddr)
            if bdaddr == "b'A8:91:3D:61:E9:E4'":
                print("The phone of lucia is nearby")
                print("Running switch script")
                switch.switchon(2)

except KeyboardInterrupt:
    child.close()

