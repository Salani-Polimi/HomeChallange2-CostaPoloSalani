/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC{

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
	// interface ACK
	interface PacketAcknowledgements;
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t> as DataRead;
  }

} implementation {

  message_t packet;
  uint8_t counter=0;
  uint8_t counter_timer1=0;
  uint8_t rec_id;
  bool data_lock=TRUE;
  void sendReq();
  void sendResp();
  double temp;
  
  //***************** Send request function ********************//
  void sendReq() {
    
	/* This function is called when we want to send a request
	 *
	 * STEPS:
	 * 1. Prepare the msg
	 * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	 *     (read the docs)
	 * 3. Send an UNICAST message to the correct node
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
      
      
	  my_msg_t* msg = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
      if (msg == NULL) {
       return;
      }
      
      msg->counter = counter;
      msg->type=REQ;
      msg->data=0;
	  
	  
      //2
      
      if(call PacketAcknowledgements.requestAck(&packet) == SUCCESS){
        dbg("radio_ack","Mote 1:requested ACK. \n");
      }
      else{
        dbgerror("error_ack","Mote 1:Error ACK\n");
      }
      
      //3.
      if (call AMSend.send(2, &packet, sizeof(my_msg_t)) == SUCCESS) {
	    dbg("radio_send", "Mote 1: packet sent.\n");	
      }
      
      
     
	 
 }   

  //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raise the event read one.
  	 */
	 call DataRead.read();
  }
  
  

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","APPLICATION BOOTED.\n");
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
    if(err==SUCCESS){
      switch(TOS_NODE_ID){
	  	case 1:
	  	 dbg("radio_on","RADIO 1 ACCESA CORRETTAMENTE, TOS_NODE_ID=%d\n",TOS_NODE_ID);
       	 call Timer1.startPeriodic(1000);
        break;
        case 2:
         dbg("radio_on","RADIO 2 ACCESA CORRETTAMENTE, TOS_NODE_ID=%d\n",TOS_NODE_ID);
        break;
	}
   }else{
     dbgerror("radio_error","RADIO ERROR, RESTART RADIO\n");
     call SplitControl.start();
   }
   
  }
  
  event void SplitControl.stopDone(error_t err){
   
   dbg("radio_rec","RADIO SWITCHED OFF TO PREVENT IDLE LISTENING POWER CONSUMPTION.\n");
  }

  //***************** MilliTimer interface ********************//
  event void Timer1.fired() {
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 * Fill this part...
	 */
      counter++;
	  dbg("radio_on","Counter Request value=%d\n",counter);
	  sendReq();
     
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
	 if(&packet==buf && err== SUCCESS){
    	dbg("radio_send","Message sent correctly. :)\n");
     }else{
    	dbg("radio_send", "Sending error\n");
     }
     
     //2.
     
     switch(TOS_NODE_ID){
      case 1:
     	if(call PacketAcknowledgements.wasAcked(buf)){
     	 call Timer1.stop();
       	 dbg("radio_rec","Mote 1:ACK received so stop timer 1,bye. \n");
        } 
     break;
     case 2:
      if(call PacketAcknowledgements.wasAcked(buf)){  
       	 dbg("radio_rec","Mote 2:ACK received stop radio 2,bye. \n");
       	 data_lock=TRUE;
       	 call SplitControl.stop();
      } 
      else{
        dbg("radio_rec","Mote 2:ACK not received :(, sending again the response.\n");
        sendResp();
      }
     break;
     }
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf, void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 
     if (len != sizeof(my_msg_t)) {return buf;}
     else {
      //we take the payload of the message and the assign to rcm
      my_msg_t* msg = (my_msg_t*)payload; 
      if(msg->type == REQ){
        counter=msg->counter;
        dbg("radio_pack","Mote 2: received a REQuest packet, it was number=%d, sorry I didn't hear the previous %d :(\n",counter,counter-1);
        sendResp();
      }
      return buf;
     }
    
   }
   
  //************************* Read interface **********************//
  event void DataRead.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finish to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */
     
     my_msg_t* msg = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
     if(data_lock==TRUE){
      temp = ((double)data/65535)*100;
      data_lock=FALSE;
     }
     
     dbg("fake_sensor_value","The value of the sensor is: %f\n",temp);
     
      if (msg == NULL) {
	   return; //if not corrected
      }
	  //we assign the counter one if the termini della struct ovvero il counter
      msg->counter = counter;
      msg->type = RESP;
      msg->data = temp;
      //we are sending the message in broadcast to everyone
      
      //2.
      if(call PacketAcknowledgements.requestAck(&packet) == SUCCESS){
        dbg("radio_ack","Mote 2: requested ACK for response.\n");
      }
      
      //3.
      if (call AMSend.send(1, &packet, sizeof(my_msg_t)) == SUCCESS) {
	    dbg("radio_send", "Mote 2: packet response sent correctly, waiting for ACK.\n");	
      }
   }
   
   
}
