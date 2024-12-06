##################1602LCD 溝通##################################
import serial
from time import *
deter='!,.:;?。，！？；'
COMlist=[]
available=[]
try:
    ######## 尋找裝置 ###########
    for i in range(32):
        COMlist.append("COM"+str(i))
        try:
            serial.Serial(COMlist[i],9600,timeout=30)
        except:
            pass
        else:
            print(COMlist[i]+" found")
            available.append(COMlist[i])
    for i in available:
        print("use "+i+" ?")
        if input()=="y":
            Serial=serial.Serial(i,9600,timeout=30)
    while(1):
        try:
            send=input("enter data('RS+RW'(2),'D7-D0(16)')").split(',')

            Serial.write(b'%c'%0xFF)
            Serial.write(b'%c'%eval("0b"+send[0]))
            Serial.write(b'%c'%eval("0x"+send[1]))
        except:
            if input("wrong input. if you want leave,just type 'close'") in ["close","over","shut down","leave","out"]:
                break
    Serial.close()
except Exception as e:
    print(e)