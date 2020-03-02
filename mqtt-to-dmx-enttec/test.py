from DMXEnttecPro import Controller

dmx = Controller("/dev/ttyUSB0");

dmx.set_channel(2, 255)
dmx.submit()
