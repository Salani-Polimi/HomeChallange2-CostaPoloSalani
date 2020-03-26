/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"
#include "Timer.h"


configuration sendAckAppC {}

implementation {


/****** COMPONENTS *****/
  
  

/****** INTERFACES *****/
  
  components MainC, sendAckC as App;
  //add the other components here
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
  components new FakeSensorC();
  components ActiveMessageC;
  components new AMSenderC(AM_MY_MSG);

  

  //Boot interface
  App.Boot -> MainC.Boot;
  
  /****** Wire the other interfaces down here *****/
  //Send and Receive interfaces
  //Radio Control
  //Interfaces to access package fields
  //Timer interface
  //Fake Sensor read
  App.Timer1 -> Timer1;
  App.Timer2 -> Timer2;
  //Sensor read
  
  App.SplitControl->ActiveMessageC;
  App.AMSend->AMSenderC;
  App.Packet->AMSenderC;
  App.DataRead -> FakeSensorC;

}

