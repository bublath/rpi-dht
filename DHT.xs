#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <wiringPi.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define false 0
#define true 1

#define MAXTIMINGS  85

//wiringPi setup modes

#define RPI_MODE_WPI 0
#define RPI_MODE_GPIO 1
#define RPI_MODE_GPIO_SYS 2 // unused
#define RPI_MODE_PHYS 3
#define RPI_MODE_UNINIT -1

typedef struct env_data {
    int temp;
    int humidity;
	int success;
} EnvData;

int debug = 0;
int dht_type = 0;

EnvData read_env(int pin);

int c_cleanup(int pin);
int c_debug(int flag);
bool noboard_test(); // unit testing with no RPi board
bool setup();

EnvData read_env(int pin){
    int data[10] = {0, 0, 0, 0, 0, 0,0, 0, 0, 0};
    
    uint8_t laststate = HIGH;
    uint8_t counter = 0;
    uint8_t j = 0, i;
    EnvData env_data;

    data[0] = data[1] = data[2] = data[3] = data[4] = 0;
    
    pinMode(pin, OUTPUT);
	//Init, first 100ms high, then low
    digitalWrite(pin, HIGH);
	delay(100);
    digitalWrite(pin, LOW);
	if (dht_type)
		delayMicroseconds(500);
	else
		delay(18);
    
    digitalWrite(pin, HIGH);
    delayMicroseconds(40);
    pinMode(pin, INPUT);

	//Wait up to 100ms until signal goes high =Handshake start of data
	int countdown=20;
	while (!digitalRead(pin)&&--countdown) {
		delayMicroseconds(5);
	}
	//Wait up to 100ms until signal goes low = first data
	int countdown2=20;
	while (digitalRead(pin)&&--countdown2) {
		delayMicroseconds(5);
	}

	uint16_t timeoutcounter = 0;
	for (j=0; j<5; j++) { //read 5 byte
		uint8_t result=0;
		for(i=0; i<8; i++) {//read every bit
			timeoutcounter = 0;
			while(!digitalRead(pin)) { //wait for an high input (non blocking)
				timeoutcounter++;
				delayMicroseconds(1);
				if(timeoutcounter > 100) {
					break; //timeout
				}
			}
			delayMicroseconds(30);
			if(digitalRead(pin)) //if input is high after 30 us, get result
				result |= (1<<(7-i));
			timeoutcounter = 0;
			while(digitalRead(pin)) { //wait until input get low (non blocking)
				timeoutcounter++;
				delayMicroseconds(1);
				if(timeoutcounter > 100) {
					break; //timeout
				}
			}
			if (timeoutcounter>100) break;
		}
		if (timeoutcounter>100) break;
		data[j] = result;
	}
	
	//Reset
	pinMode(pin, OUTPUT);
    digitalWrite(pin, LOW);
	delay(100);


//	printf("%i: %x %x %x %x %x %x %x %x\n",j,data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7]);
//	printf("C1:%i C2:%i\n",countdown,countdown2);
    
    if ((j >= 5) &&
         (data[4] == ((data[0] + data[1] + data[2] + data[3]) & 0xFF))){
		
		if (debug) {
			printf( "Humidity = %d.%d %% Temperature = %d.%d *C\n",
			data[0], data[1], data[2], data[3]);
		}

	int h,t;
	if (dht_type) {
		h = data[0]<<8 | data[1];
		t = data[2]<<8 | data[3];
		if (t&0x8000) { t=-(t&0x7fff); }
	} else {
        t = data[2]*10+data[3]; //not really documented, but it seems like DHT11 has one 1/10 temperature digit in data[3]
        h = data[0]*10;
	}

		env_data.success = true;
        env_data.temp = t;
		if (t<-1000 || t>2000) env_data.success= false;
        env_data.humidity = h;
		if (h<0 || h>1000) env_data.success= false;
	}
    else {
		//Not enough data or checksum error
		if (debug) printf("Checksum error or insufficient data\n");
        env_data.success= false;
    }
    return env_data;
}

int c_cleanup(int pin){
    // reset the pin to default status

    digitalWrite(pin, LOW);
    pinMode(pin, INPUT);

    return(0);
}

bool noboard_test(){
    if (getenv("RDE_NOBOARD_TEST") && atoi(getenv("RDE_NOBOARD_TEST")) == 1)
        return true;
    return false;
}

int c_conf(int flag,int type){
    debug = flag;
	dht_type = type;
    return debug;
}
     
bool setup(){

    if (! noboard_test()){
        int setupMode = -1;

        if (getenv("RPI_PIN_MODE"))
            setupMode = atoi(getenv("RPI_PIN_MODE"));

        if (setupMode == -1){
            if (wiringPiSetupGpio() == -1)
                exit(1);
        }
        else {
            char modeEnvVar[20];
            sprintf(modeEnvVar, "RPI_PIN_MODE=%d", setupMode);
            putenv(modeEnvVar);
        }
    }
    return true;
}

MODULE = RPi::DHT  PACKAGE = RPi::DHT

PROTOTYPES: DISABLE

int
c_temp (pin)
	int	pin
	PREINIT:
	 EnvData env_data;
	CODE:
	 env_data = read_env(pin);
	 if (!env_data.success) {
		XSRETURN_UNDEF;
	 }
	 RETVAL=env_data.temp;
	OUTPUT:
	 RETVAL

int
c_humidity (pin)
	int	pin
	PREINIT:
	 EnvData env_data;
	CODE:
	 env_data = read_env(pin);
	 if (!env_data.success) {
		XSRETURN_UNDEF;
	 }
	 RETVAL=env_data.humidity;
	OUTPUT:
	 RETVAL
	 
void
c_query(OUTLIST temp,OUTLIST humidity,IN pin)
	int temp
	int humidity
	int pin
	PREINIT:
	 EnvData env_data;
	CODE:
	 env_data = read_env(pin);
	 if (!env_data.success) {
		XSRETURN_UNDEF;
	 }
	 temp=env_data.temp;
	 humidity=env_data.humidity;
//     if (debug)
//       printf( "Humidity = %.1f %% Temperature = %.1f *C\n", humidity/10.0, temp/10.0);
	 
int
c_cleanup (pin)
	int	pin

int
c_conf (flag,type)
    int flag
	int type

bool
setup()
