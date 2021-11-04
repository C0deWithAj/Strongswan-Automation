#!/usr/bin/python

import socket
from datetime import timedelta
import json
import vici
import requests
import subprocess

# NOTE: Vici and requests is required for this script - Can be installed using pip

SERVER_META_FILE = "/root/strongswan/SERVER_INFO.conf"

s = socket.socket(socket.AF_UNIX)
s.connect("/var/run/charon.vici")
v = vici.Session()


# print("***Active-Sas***")
# list_sas = v.list_sas()
# for data in list_sas:
#     for key in data:
#         # print("data = "+data)
#         object = data[key]
#         print("state: " + object['state'])
#         print("Subnet IP: " + object['local-host'])
#         mainChild = object["child-sas"]
#         if mainChild != []:
#             childKey = list(mainChild.keys())[0]
#             child = mainChild[childKey]
#             print("Life-time = " + child["life-time"])
#             print("bytes-out = " + child["bytes-out"])
#             print("bytes-in = " + child["bytes-in"])


def get_total_up_conn(v):
    resultStats = v.stats()
    ikesas = resultStats["ikesas"]
    totalUp = ikesas["total"]
    return totalUp


def parse_active_stats(vici):
    result_ike = []
    list_sas = vici.list_sas()
    for data in list_sas:
        for k in data:

            # Complete object of one connection
            mainObject = data[k]
            # childsas = mainObject['child-sas']
            state = mainObject['state']
            # local_ip = mainObject['remote-vips']
            remote_ip = mainObject['remote-host']
            # print(mainObject)
            # Child object inside main conn

            if mainObject != []:
                mainChild = mainObject["child-sas"]
                key = next(iter(mainChild))
                childObj = mainChild[key]
                bytesout = childObj["bytes-out"]
                bytesIn = childObj["bytes-in"]
                # print(childObj)

                lifeTime = childObj["install-time"]

                data = {}
                data['ip'] = remote_ip
                data['state'] = state
                data['bytes-out'] = bytesout
                data['bytes-In'] = bytesIn
                data['lifeTime'] = lifeTime
                if k == "IOS-IPSEC":
                    data['client'] = "IOS"
                else:
                    if k == "AndroidCon":
                        data['client'] = "Android"

                #   json_data = json.dumps(data)
                result_ike.append(data)

    return result_ike


def get_server_type():
    with open(SERVER_META_FILE, 'r') as myfile:
        data = myfile.read()
        serv_type_line = ""
        for item in data.split("\n"):
            if "ServerType" in item:
                serv_type_line = item.strip()

        # We now have "ServerType: Premium/Free"
        typeArray = serv_type_line.split(" ")
        if typeArray != []:
            if typeArray[1].lower() == "free":
                return "Free"
            else:
                if typeArray[1].lower() == "premium":
                    return "Premium"
    return ""


# ******************** Utility Function ****************************

def get_server_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP


def get_server_uptime():
    with open('/proc/uptime', 'r') as f:
        uptime_seconds = float(f.readline().split()[0])
        uptime_string = str(timedelta(seconds=uptime_seconds))
    return uptime_string

    # ******************** Utility Function Ends****************************


def prepare_server_data():
    uptime = get_server_uptime()
    ikeList = parse_active_stats(v)
    data = {}
    data['uptime'] = uptime
    data['server_ip'] = get_server_ip()
    data['active_clients'] = ikeList
    data['server_type'] = get_server_type()
    # data['node-name'] = subprocess.check_output(['bash', '-c', "uname -n"])
    data['node-name'] = subprocess.check_output("uname -n", shell=True).strip()
    print(data['node-name'])
    return data


def post_data_to_server(stats):
    data = {}
    data['token'] = "logan"
    data['appId'] = "1.0"
    data['bundleid'] = "vpn.server"
    data['version'] = "1.0"
    data['installedDuration'] = 29
    data['sessionCount'] = 0
    data['deviceType'] = "Mobile"
    data['deviceOSVersion'] = 11.0
    data['platform'] = "android"
    data['request'] = "updateServer"
    data['server'] = stats
    postData = json.dumps(data)
    headers = {'Accept': 'application/x-www-form-urlencoded', 'Content-Type': 'application/json'}
    request = requests.post('http://www.efusion.co:30257/api', data=postData, headers=headers)
    print(request.text)
    return


serverData = prepare_server_data()
post_data_to_server(serverData)
