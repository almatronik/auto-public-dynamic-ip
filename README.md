# auto-static-dynamic-ip

The function of this script is to check if I am connected to my home wifi or elsewhere and set static or dynamic ip accordingly.

The script will check thet name of the wireless adapter, the ssid, if the computer currently has static or dynamic ip.

If the computer is connected to the configured HOME ssid it will check if the local ip is static and set it to static if it is not already.
If the computer is connected to any other ssid it will check if the local ip is dynamic and set it to dynamic if it is not already.

The script can also be installed via the task scheduler if the variable 'install' is set to 1. In that case it will run automatically at every user logon and spare the hassle of changing my settings manually.

The default use is portable.
