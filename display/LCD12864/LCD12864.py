##################1602LCD 溝通##################################
import serial
from time import *
deter='!,.:;?。，！？；'
COMlist=[]
available=[]
def writebyte(ins,data):
    print(ins,data)
    Serial.write(b'%c'%0xFF)
    Serial.write(b'%c'%eval("0b"+ins))
    Serial.write(b'%c'%eval("0x"+data))
    
    sleep(0.1)
    
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
    mode=int(input("select mode \n1.instruction\n2.write string"))
    while(1):
        try:
            if mode==1:
                data=input("RW+RS D7-D0\n=>")
                if data=="mode":
                    mode=int(input())
                else:
                    data=data.split(',')
                    writebyte(data[0],data[1])
            elif mode==2:
                data=input("enter a string\n=>")
                if data=="mode":
                    mode=int(input())
                else:
                    count=0
                    for i in data:
                        i=i.encode("big5")
                        if len(i)==2 and count%2==0:
                            writebyte("10","%x"%i[0])
                            writebyte("10","%x"%i[1])
                            count+=2
                        elif len(i)==1:
                            writebyte("10","%x"%i[0])
                            count+=1
                        else:
                            writebyte("10","0x20")
                            count+=1
        except Exception as e:
            print("error occurred　",end=str(e))
            if input("wrong input. if you want leave,just type 'close'") in ["close","over","shut down","leave","out"]:
                break
    Serial.close()
except Exception as e:
    print(e)