#include "sendAck.h"
#include "Timer.h"

module sendAckC @safe(){

  uses {
  /****** INTERFACES *****/
    //interfaces for communication
	interface Boot; 
	interface SplitControl;
	interface Packet;
	interface AMSend;
	interface Receive;
	//interface for timer
	interface Timer<TMilli> as Timer1;
	interface Timer<TMilli> as Timer2;
	// interface ACK
	interface PacketAcknowledgements;
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t> as DataRead;
  }

} implementation {

  uint8_t counter=0;
  uint8_t rec_id;
  message_t packet;
  bool first_lap=TRUE;

  void sendReq();
  void sendResp();
  
  
  //***************** Send request function ********************//
  void sendReq() {
     counter++;
	/* This function is called when we want to send a request
	 *
	 * STEPS:
	 * 1. Prepare the msg
	 * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	 *     (read the docs)
	 * 3. Send an UNICAST message to the correct node
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
   
     //creating the message size of payload
     //variable della struct
      
      //1.
      
      my_msg_t* msg = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
      if (msg == NULL) {
	  return; //if not corrected
      }
	  //we assign the counter one if the termini della struct ovvero il counter
      msg->counter = counter;
      msg->type=REQ;
      //msg->data=0;
      //we are sending the message in broadcast to everyone
      
      //2.
      if(call PacketAcknowledgements.requestAck(&msg) == SUCCESS){
        dbg("Received ACK","Received ACK\n");
      }
      else{
        dbgerror("Error ACK","Error ACK\n");
      }
      
      //3.
      if (call AMSend.send(2, &packet, sizeof(my_msg_t)) == SUCCESS) {
	    dbg("Request send", "Mote 1: packet send.\n");	
      }
    
  }        

  //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raises the event read one.
  	 */
  	  call DataRead.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	//modificare file python
	switch(TOS_NODE_ID){
	  case 1:
       call Timer1.startOneShot(1000);
     break;
     case 2:
      call Timer2.startOneShot(5000);
     break;
     
	}
	
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
   if(err==SUCCESS){
      call Timer1.startPeriodic(1000);
   }else{
     dbgerror("radio_err","radio error, restart radio\n");
     call SplitControl.start();
   }
  }
  
  event void SplitControl.stopDone(error_t err){
    /* Fill it ... */
  }

  //***************** MilliTimer interface ********************//
  event void Timer1.fired() {
     if(first_lap==TRUE){
       call SplitControl.start();
     }
	 /* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 * Fill this part...
	 */
	 call sendReq();
  }
  
  event void Timer2.fired() {
   call SplitControl.start();
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 * Fill this part...
	 */
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a message is sent 
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer. The program is done
	 * 2b. Otherwise, send again the request
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 
	 //1.
	 if(&packet==buf && error == SUCCESS){
    	dbg("radio_send","message sent correctly\n");
     }else{
    	dbg("radio_send", "sending error\n"):
     }
     //2.
     if(call PacketAcknowledgements.wasAcked(msg) == TRUE){
       Timer1.stop();
       dbg("mote 1 stop","Mote 1: Timer stop,bye \n");
     } 
     
  }
     
	 
	 
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 
	 dbg("Mote2 received", "Received packet from mote 1 of length %hhu.\n", len);
    //check size message equal size what we have received
     if (len != sizeof(my_msg_t)) {return bufPtr;}
     else {
      //we take the payload of the message and the assign to rcm
      my_msg_t* msg = (my_msg_t*)payload; 
      if(msg->type == REQ){
        counter=msg->counter;
        call sendResp();
      }
  }
  
  /*
  void sendData(uint16_t data, uint8_t type){
      sensor_msg_t* mess = (sensor_msg_t*)(call Packet.getPayload(&packet, sizeof(sensor_msg_t)));
      if (mess == NULL) {
        return;
      }
      mess->type = type;
      mess->data = data;
     
      dbg("radio_pack","Preparing the message... \n");
     
      if(call AMSend.send(0, &packet,sizeof(sensor_msg_t)) == SUCCESS){
         dbg("radio_send", "Packet passed to lower layer successfully!\n");
         dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
         dbg_clear("radio_pack","\t Payload Sent\n" );
         dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->type);
         dbg_clear("radio_pack", "\t\t data: %hhu \n", mess->data);
       
      }
  }/*
  
  //************************* Read interface **********************//
  event void DataRead.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finish to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */ 
      double temp = ((double)data/65535)*100;
      dbg("temp","temp read done %f\n",temp);
   
      //sendData((uint16_t) temp, 2);
	  
	  
      my_msg_t* msg = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
      if (msg == NULL) {
	   return; //if not corrected
      }
	  //we assign the counter one if the termini della struct ovvero il counter
      msg->counter = counter;
      msg->type = RESP;
      msg->data = temp;
      //we are sending the message in broadcast to everyone
      
      //2.
      if(call PacketAcknowledgements.requestAck(&msg) == SUCCESS){
        dbg("ACKok","ACK OK \n");
      }
      else{
        dbgerror("Error ACK ok","Error ACK ok\n");
      }
      
      //3.
      if (call AMSend.send(1, &packet, sizeof(my_msg_t)) == SUCCESS) {
	    dbg("Response sent", "Mote 2: packet response sent.\n");	
      }
}

