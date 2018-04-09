`timescale 1ns/10ps

module controller(input wire clock, 
input  wire reset, input wire writeCmd,
input wire ReadCmd,
input wire dq,
input wire [2:0] bank,
input wire [ROW_BITS-1:0] row,
input wire [COL_BITS-1:0] col,
output reg ck, ck_neg, rst, rst_neg, cs_n, cke, ras_n, cas_n, we_n, 
output reg [2:0] ba, reg [15:0] a,
output reg odt,
output reg [18:0] mr0, mr1, mr2, mr3
);


// the parameters for DDR# memory controller
`include "1024Mb_ddr3_parameters.vh"
///

   // assign TZQCS   = max(64, ceil( 80000/TCK_MAX));
    //assign TZQINIT =  max(512, ceil(640000/TCK_MAX));
    //assign TZQOPER =  max(256, ceil(320000/TCK_MAX));

////assgned specially for write operation

wire tck;
assign tck = ceil(TCK_MIN);
wire [3:0] cwl = mr2[5:3] + 5; // dont miss to assign mr2 the values
wire [3:0] al = (mr1[4:3] == 2'b00)?

wire                  [3:0] cl       = {mr0[2], mr0[6:4]} + 4;              //CAS Latency
    wire                        bo       = mr0[3];                    //Burst Order
    reg                   [3:0] bl;                                         //Burst Length
    wire                  [3:0] cwl      = mr2[5:3] + 5;              //CAS Write Latency
    wire                  [3:0] al       = (mr1[4:3] === 2'b00) ? 4'h0 : cl - mr1[4:3]; //Additive Latency
    wire                  [4:0] rl       = cl + al;                         //Read Latency
    wire                  [4:0] wl       = cwl + al;  




//reg [18:0] mr0, mr1, mr2, mr3;  
//reg [15:0] a;
//reg [2:0] ba;
reg readStart, writeStart;
//reg odt;
reg [15:0] count10n, count4n, countTRFC, tFAW, countActivate,countTRCD, countTRC, countTRRD, countTIS;
reg [64:0] count500u, count200u, count512, countTDLLK;


//flags delcaration
reg preChargeFlag, ActivateFlag, wlFlag, refreshFlag, WriteFlag, ReadFlag, nopFlag, AutoPrecharge;

//reg [6:0] nxtState, state;

wire [22:0] command;
wire reset;
reg [3:0] check;
ddr3 M1 (
    .rst_n(rst_neg),
    .ck(ck),
    .ck_n(ck_neg), .cs_n(cs_n), .ras_n(ras_n), .cas_n(ras_n), .we_n(we_n), .ba(ba), .addr(a),
    .odt(odt),.cke(cke), .dq0(dq_en), .dqs(dqs_en)
);

    //assign TZQCS   = max(64, ceil( 80000/TCK_MAX));
  //  assign TZQINIT =  max(512, ceil(640000/TCK_MAX));
    //assign TZQOPER =  max(256, ceil(320000/TCK_MAX));

//reg [6:0] nxtState;
enum logic [6:0] {countInit = 1, powerUp, T500, T10, TXPRstate,NOP1, NOP2, NOP3, NOP4, NOP5, NOP6, NOP7, TMR2, TMR3, TMR1, TMR0, ZQCL, Refresh,IDLE, preCharge, Activate, Read, Write, no_op} state, nxtState; 

parameter paraCount10 = 17,
 paraCount200 = 213220,
 paraCount4 = 5,
 paraCount500 = 533050,
 paraCount512 = 545843,
 paraCountTRFC =129,
paraCountTRCD = TRCD,
paraCountTFAW = TFAW, paraCountTRC = TRC, paraCountTRRD= TRRD, paraCountTIS = TIS, paraCountTDLLK = 512;


assign command = {cs_n, ras_n, cas_n, we_n, ba[2:0], a[15:13], a[12], a[10], a[11],a[9:0]} ;

 
always @ (negedge clock)
  begin
    if (reset)
      begin
      
	//$display("time in controller reset %t",$time);
	//$display("now ill go in %h",state);
	//$display("m sti high. m reset");
	state <= countInit;
      end

    else
      begin
	////$display("time out of controller reset %d",$time);
        state <= nxtState;
	////$display("now ill go in %h",state);
      end
    

 end

  
/*always @(reset) begin
rst <= reset;
rst_neg <= !reset;
*/

always@(*)
begin rst <= !rst_neg; end
  
always @(clock)


  begin
    ck <= clock;
    ck_neg <= !clock;
  end

always @(negedge ck or negedge rst )
  begin
    case(state) 
        countInit : 
        begin
          //$display("this is countInit state");
            // //$display("Time %t",$time);
          count500u <= 0;
          countTIS <= 0;
          count10n <= 0;
          countTDLLK <=0;
          count200u <= 0;
          count4n<= 0;count512<= 0;countTRFC<= 0;tFAW<= 0; countActivate<= 0; countTRCD<= 0; countTRC<= 0; countTRRD<= 0; countTIS<= 0;
          nxtState <= powerUp;
          //rst_neg <= 0;
	  preChargeFlag <= 0;
		  ActivateFlag <= 0;
		  wlFlag <= 0;
		  refreshFlag <= 0;
		// //$display("Value of Reset Neg %d",rst_neg);
        end
      
        powerUp:
        begin
            //
            
            //

//	    //$display("the value of count in powerup is %d",count200u);
            if (count200u <paraCount200) 
            begin
		rst_neg <= 0;
		cke <= 0;

                if (count200u > (213220))
                    begin
			//$display("it came here prior 10ns %d for time %t",count200u,$realtime);
                     		
                        count200u = count200u +1;
                        nxtState <= powerUp;
                    end
                
            
            else       //count200u = count200u+1;
		begin//// //$display(" am i heere?");
		//$display("time in powerup state %t",$time);
              nxtState = T10;
		
		//$display("Time when it enterted T500 state is %t with value of reset_neg to be %h \n",$time,rst_neg);
							//odt <= 0;
		end
					//// //$display(" or no loops stated");	
					
					
        end
	end
	T10: begin
		if (count10n < 12)
			begin
				count10n = count10n+1;
				nxtState <= T10;
			end

		else begin
			nxtState <= T500;
		end
		
	end
		T500:
		begin
		rst_neg = 1; 
		cke <= 0;
		odt <= 0;
		// //$display("Value of Reset Neg %d",rst_neg);
            //// //$display("Time WHEN IT ENTERED T500 %t",$time);
             //// //$display("this is t500 state");
			if (count500u < paraCount500)
				begin
                     //// //$display("this is count 500 loop of t500 state %d",count500u);
					count500u = count500u + 1;
					nxtState <= T500;
                end
			else 
				begin
			//cke<=1;
                    //$display("cke will be 1 here, %t",$time);
                    nxtState <= NOP1;
			//$display("entering NOP1 stage");
                end
            end
            
        NOP1 : 
            begin
               
                
                cs_n <= 1'b0;
                ras_n <= 1'b1;
                cas_n <= 1'b1;
                we_n <= 1'b1;
                odt <=0;
                //ba[2:0] <= 3'b0;
                //a[15:0] <= 16'b0;
                cke <= 1;
                        
               // //$display("This is nop1 stage");
			   // check previous cycles  // NOP state command
					
                 //   // //$display("this is va;ue of check %d",check);
               if (count10n < paraCount10) 
                   begin
                        //$display("value of count10 is %d",count10n);
                        count10n = count10n + 1;
                        cs_n <= 1'b0;
                        ras_n <= 1'b1;
                        cas_n <= 1'b1;
                        we_n <= 1'b1;
                       
                        odt <=0;
                        nxtState <= NOP1;
                    end
                else 
                    begin
                        nxtState <= TXPRstate;
                        count10n <= 0;
                        //$display ("Count TIS value %d",count10n);
                    end                      
					                   					
					
            end
    
		
		TXPRstate:
		
		begin
           
           //$display("Is it coming here?");
            //// //$display("vlaue of coubntTRFC is %d vs paracount TRFC %d ",countTRFC, paraCountTRFC);
            
			if (countTRFC > paraCountTRFC)
				begin
                    //// //$display("value of countTRFC is %d",countTRFC);
					countTRFC = countTRFC + 1;
					nxtState <= TXPRstate;
				end
			else
				begin
                    // //$display("value of countTRFC is %d",countTRFC);
					//nxtState <= TMR2;
					nxtState <= TMR2;
				end
		end
//////////// NOP stage before all loads
		NOP2: 
            begin
               countTRFC <= 0;
                count10n = count10n + 1;
                cs_n <= 1'b0;
                ras_n <= 1'b1;
                cas_n <= 1'b1;
                we_n <= 1'b1;
                odt <=0;
                //ba[2:0] <= 3'b0;
                //a[15:0] <= 16'b0;
                cke <= 1;
                        
               // //$display("This is nop1 stage");
			   // check previous cycles  // NOP state command
					
                 //   // //$display("this is va;ue of check %d",check);
               if (count10n < paraCount10) 
                   begin
                        //$display("value of count10 is %d",count10n);
                        count10n = count10n + 1;
                        cs_n <= 1'b0;
                        ras_n <= 1'b1;
                        cas_n <= 1'b1;
                        we_n <= 1'b1;
                       
                        odt <=0;
                        nxtState <= NOP2;
                    end
                else 
                    begin
                        nxtState <= TMR2;
                        count10n <= 0;
                        //$display ("Count TIS value %d",count10n);
                    end                      
					                   					
					
            end                
                
////////////// TMR2 stage            
		
		TMR2:
		begin
            //$display("This is TMR2 stage");
			//mr2 <= {ba[2:0], a[15:0]};
			
			cke <= 1'b1; // check previous cycles
			cs_n <= 1'b0;
			ras_n <= 1'b0;
			cas_n <= 1'b0;
			we_n <= 1'b0;
			ba <= 3'b010;
			a<= 14'h200;
			
				//ba <= bank;
			//a <= row;
			//nxtState <= TMR3;
			if (count4n < paraCount4)
				begin
                    // //$display("This is count4n value %d vs %d",count4n,paraCount4);
                   
					count4n =count4n + 1;
					nxtState<= TMR2;
				end
			else
				begin
                 //   count4n <= 0;
					nxtState<=NOP3;
					
				end
		end
//////////// NOP stage before all loads
		NOP3: 
            begin
               
                cs_n <= 1'b0;
                ras_n <= 1'b1;
                cas_n <= 1'b1;
                we_n <= 1'b1;
                odt <=0;
                //ba[2:0] <= 3'b0;
                //a[15:0] <= 16'b0;
                cke <= 1;
                mr2 <= a;        
               // //$display("This is nop1 stage");
			   // check previous cycles  // NOP state command
					
                 //   // //$display("this is va;ue of check %d",check);
               if (count4n < paraCount4) 
                   begin
                        //$display("value of count10 is %d",count10n);
                        count4n = count4n + 1;
                        cs_n <= 1'b0;
                        ras_n <= 1'b1;
                        cas_n <= 1'b1;
                        we_n <= 1'b1;
                       
                        odt <=0;
                        nxtState <= NOP3;
                    end
                else 
                    begin
                        nxtState <= TMR3;
                        count10n <= 0;
                        //$display ("Count TIS value %d",count10n);
                    end                      
					                   					
					
            end                
                		
		
		TMR3:
		begin
             //$display("this is TMR3 state");
			//mr2 <= {ba[2:0], a[15:0]};
			///mr3 <= 19'b0_11_0000000000000_0_00;
			cke <= 1'b1; // check previous cycles
			cs_n <= 1'b0;
			ras_n <= 1'b0;
			cas_n <= 1'b0;
			we_n <= 1'b0;
			ba <= 3'b011;
			a<= 14'h0;
			
			//nxtState <= TMR3;
			if (count4n < paraCount4)
				begin
                    // //$display("TMR3 state This is count4n value %d vs %d",count4n,paraCount4);
                    
					count4n = count4n+1;
					nxtState <= TMR3;
				end
			else
				begin
				//count4n <= 0;
					nxtState<=NOP4;
				end
		end
		
		
		//////////// NOP stage before all loads
		NOP4: 
            begin
                cs_n <= 1'b0;
                ras_n <= 1'b1;
                cas_n <= 1'b1;
                we_n <= 1'b1;
                odt <=0;
                //ba[2:0] <= 3'b0;
               // a[15:0] <= 16'b0;
                cke <= 1;
				mr3<=a;
                        
               // //$display("This is nop1 stage");
			   // check previous cycles  // NOP state command
					
                 //   // //$display("this is va;ue of check %d",check);
               if (count4n < paraCount4) 
                   begin
                        //$display("value of count10 is %d",count10n);
                        count4n = count4n + 1;
                        cs_n <= 1'b0;
                        ras_n <= 1'b1;
                        cas_n <= 1'b1;
                        we_n <= 1'b1;
                       
                        odt <=0;
                        nxtState <= NOP4;
                    end
                else 
                    begin
                        nxtState <= TMR1;
                        
                        //$display ("Count TIS value %d",count10n);
                    end                      
					                   					
					
            end                
                          
		
		
		TMR1:
		begin
            //$display("This is TMR1 state");
			//mr2 <= {ba[2:0], a[15:0]};
			//mr1 <= 19'b0_01_00_0_0_0_0_0_0_0_0_00_0_0_00;
			cke <= 1'b1; // check previous cycles
			cs_n <= 1'b0;
			ras_n <= 1'b0;
			cas_n <= 1'b0;
			we_n <= 1'b0;
			
			ba <= 3'b001;
			a<=14'h16;
		
			//nxtState <= TMR3;
					nxtState<=NOP5;
				end
				
//////////// NOP stage before all loads
		NOP5: 
            begin
                cs_n <= 1'b0;
                ras_n <= 1'b1;
                cas_n <= 1'b1;
                we_n <= 1'b1;
                odt <=0;
                //ba[2:0] <= 3'b0;
                //a[15:0] <= 16'b0;
                cke <= 1;
                mr1<=a;        
               // //$display("This is nop1 stage");
			   // check previous cycles  // NOP state command
					
                 //   // //$display("this is va;ue of check %d",check);
               if (count4n < paraCount4) 
                   begin
                        //$display("value of count10 is %d",count10n);
                        count4n = count4n + 1;
                        cs_n <= 1'b0;
                        ras_n <= 1'b1;
                        cas_n <= 1'b1;
                        we_n <= 1'b1;
                       
                        odt <=0;
                        nxtState <= NOP5;
                    end
                else 
                    begin
                        nxtState <= TMR0;
                        
                        //$display ("Count TIS value %d",count10n);
                    end                      
					                   					
					
            end                
                                  
		
		TMR0:
		begin
			//mr2 <= {ba[2:0], a[15:0]};
			 //$display("This is TMR) state ");
			//mr0 <= 19'b 0_00_00000_00_1_0_0_000_000;
			cke <= 1'b1; // check previous cycles
			cs_n <= 1'b0;
			ras_n <= 1'b0;
			cas_n <= 1'b0;
			we_n <= 1'b0;
			ba <= 3'b000;
			a<= 14'b1000100100100;
		
			//nxtState <= TMR3;
			if (count4n < paraCount4)
				begin
                    // //$display("TMR1 state : This is count4n value %d vs %d",count4n,paraCount4);
                  	count4n = count4n+1;
					nxtState <= TMR0;
				end
			else
				begin
				//count4n <= 0;
                nxtState<=NOP6;
				end
		end
		//////////// NOP stage before all loads
		NOP6: 
            begin
               //count4n <= 0;
                //count10n = count10n + 1;
                cs_n <= 1'b0;
                ras_n <= 1'b1;
                cas_n <= 1'b1;
                we_n <= 1'b1;
                odt <=0;
				mr0<=a;
                //ba[2:0] <= 3'b0;
                //a[15:0] <= 16'b0;
               // cke <= 1;
                        
               // //$display("This is nop1 stage");
			   // check previous cycles  // NOP state command
					
                 //   // //$display("this is va;ue of check %d",check);
               if (count10n < paraCount10) 
                   begin
                        //$display("value of count10 is %d",count10n);
                        count10n = count10n + 1;
                        cs_n <= 1'b0;
                        ras_n <= 1'b1;
                        cas_n <= 1'b1;
                        we_n <= 1'b1;
                       
                        odt <=0;
                        nxtState <= NOP6;
                    end
                else 
                    begin
                        nxtState <= ZQCL;
                        //count10n <= 0;
                        //$display ("Count TIS value %d",count10n);
                    end                      
					                   					
					
            end                
                
                  
		
		ZQCL:
		begin
		    //// //$display("ZQCL state");
			cke <= 1'b1; // check previous cycles
			cs_n <= 1'b0;
			ras_n <= 1'b1;
			cas_n <= 1'b1;
			we_n <= 1'b0;
			a[10] <= 1'b1;
			a[15:11]<= 5'b0;
			ba <= 0;
			//a[9:0] <= 10'b0;
			//ba[2:0] <= 3'b0;
			if (countTDLLK <= paraCountTDLLK)
				begin
				// //$display("count512 value is %d vs %d",count512, paraCount512);
					countTDLLK = countTDLLK+ 1;
					nxtState <= ZQCL;
				end
			else
				begin
                    countTDLLK = paraCountTDLLK+10;
				      // //$display("countTDLLK value is %d vs %d",countTDLLK, paraCountTDLLK);
					nxtState <= IDLE;
				end
		end
		
		NOP7:
		begin
            countTDLLK <= 0;
            cs_n <= 1'b0;
                ras_n <= 1'b1;
                cas_n <= 1'b1;
                we_n <= 1'b1;
                ba[2:0] <= 3'b0;
                a[15:0] <= 16'b0;
                if (count10n < paraCount10) 
                    begin
                        count10n = count10n + 1;
                        nxtState <= NOP7;
                    end
                else begin 
                        count10n = 0;
                        nxtState = IDLE;
                end
        end
                  
		
		
		IDLE:
		begin
            // //$display(" this is idle state");
			//mr1[7] <= 1;
			if (!cs_n && !ras_n && !cas_n && we_n) // system should enter refresh cycle, but for that it should first go in precharge
			// idle --> precharge --> idle --> activate --> read/write 
				begin
					if(preChargeFlag)
						begin
							nxtState <= Activate;
						end
					else
						begin
							nxtState <= preCharge;
						end
				end
				
									
		end
		
		preCharge: // check if any open row in particular/ all banks, set ba = 0 i.e deactivate it, there should be no open rows to continue pre charge
// next row activation after tRP/ except if concurrent auto precharge		
		begin
            // //$display("precharge done");
			if(ba==0)
				begin
					//bank <= 0;
					//row <= 0;
					ActivateFlag <= 1;
					tFAW <= 0;
					if (ba == bank && a == row)
						begin
							nxtState <= Activate;
							countActivate +=1;
						end
					else if (ba == bank && a != row)
						begin
							a = 0;
							ba = bank;
						end
					
					else
						begin
							nxtState <= Refresh;
						end
			// if already precharged, ju8mp to refresh
				end
			else 
				begin
				// start precharge here for all banks
				//and idle for minimum of the precharge time before going to refresh state
				end
				
		end
		// 8 refresh commands can be ignored
		Refresh: // address bits are X, internal address ounter gives address. no control of external address bus. after refresh, all should be in precharge(idle). 
		begin
		
		end
		
		no_op: 
		begin
			nxtState <= Activate;
			nopFlag = 0;
		end
	
		Activate:
		begin	
			cke   <= 1'b1;
            		cs_n  <= 1'b0;
            		ras_n <= 1'b0;
           		cas_n <= 1'b1;
            		we_n  <= 1'b1;
            
			//row <= a;
			ActivateFlag <= 0;
			nopFlag <= 1;
			if (countTRCD < paraCountTRCD)
				begin
					nxtState <= no_op;
				end
			else 
				begin
					if (readStart)
						begin
							nxtState <= Read;
						end
					else if (writeStart)
						begin
							nxtState <= Write;
						end
				end
			
			if (tFAW < paraCountTFAW)
				if (countActivate >3)
				begin
					nxtState <= preCharge;
					countActivate <= 0;
				end
				else 
				begin
					ActivateFlag <= 1; // 
				end
	
			else
				begin
				end
				
			if (ba == bank && a != row)
				begin
					if (countTRC < paraCountTRC)
						begin
							nxtState <= Activate;
						end
					else
						begin
							nxtState <= preCharge;
						end
				end
			else if (ba == bank && a == row)
				begin
					nxtState <= Write;
				end
			else if (ba != bank)
				begin
					if (countTRRD < paraCountTRRD)
						begin
						ba = bank;
						a = row;
						end
				end
				
					
			
	 		
			
			
			if (countTRCD <paraCountTRCD) // all the counter needs to be divided by clock to check next positive edge
				begin
					nxtState <= Activate;
				end
			else
				begin				
					if (WriteFlag)
						begin
							nxtState<= Write;
						end
					else if (ReadFlag)	
						begin
							nxtState <= Read;
						end
					else if (ActivateFlag)
						begin
							nxtState <= Activate;
							countActivate += 1; 
						end
				end
		end
					
		
		//writeLevel:
		//begin
			//mr1[7] <= 1;
			 
		//end
		
		//Read 
		
		Read:
		begin
			 
		end
		
		// Write Stage if (write input is high, it comes to this stage, after precharged)
		Write: 
		begin
			
			cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b1;
		    cas_n <= 1'b0;
            we_n  <= 1'b0;
			ba <= bank;
			a[9:0] <= col[9:0];         //a[ 9: 0] = COL[ 9: 0]
            a[11] <= col[10];//a[   11] = COL[   10]
            a[13]<= col[14];a[atemp[2] = (col>>11)<<13;         //a[ N:13] = COL[ N:11]
			a[10] <= 0; // auto precharge kept to 0
			a[12] <= bc; // burst mode disabled bc = 0 for bc4 and bc = 1 for bl8
			if (bc ==1) begin bl <= 8; end
			else if (bc == 0) begin bl <= 4; end
			else begin bc <= 0; bl <= 4; end // default condition of bc4
			dqs_en <= 1'b1;
            dq_en  <= 1'b1;
			if (countTDQS <(wl*tck + bl*tck/2 + tck/2) )
			begin
				countTDQS <= countTDQS +1;
				dqs_en <= 1'b1;
				dq_en  <= 1'b1;
			end
			else begin
			
			dqs_en <= 1'b0;
            dq_en  <= 1'b0;
			end
			
			//first complete the write command.
			
			if (a[10]) 
				begin
					nxtState <= AutoPrecharge;
				end
			else
				begin // need to check whether idle or write
					nxtState <= IDLE;
				end
					// Auto precharge is activated, after write operation, it should jump to auto precharge state
		end
		
		
		
		default: nxtState <= nxtState;
	endcase

  end

			
endmodule
	
			
			
		
		
		
			
					
		
					
			
              
              