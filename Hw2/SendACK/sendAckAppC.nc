/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"

configuration sendAckAppC {}

implementation {


/****** COMPONENTS *****/
  components MainC, sendAckC as App;
  //add the other components here
  components new TimerMilliC() as Timer1;
  components new FakeSensorC();
  components ActiveMessageC;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  

/****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Wire the other interfaces down here *****/
  //Send and Receive interfaces
  //Radio Control
  //Interfaces to access package fields
  //Timer interface
  //Fake Sensor read
  App.AMSend->AMSenderC;
  App.Receive -> AMReceiverC;
  App.SplitControl->ActiveMessageC;
  App.DataRead -> FakeSensorC;
  App.Packet->AMSenderC;
  App.PacketAcknowledgements->ActiveMessageC;
  App.Timer1 -> Timer1;
}

