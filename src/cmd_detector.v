/*********************************************************
 MODULE:        Sub Level SDRAM Command Detector

 FILE NAME:    cmd_detector.v
 VERSION:    1.0
 DATE:        May 2nd, 2002
 AUTHOR:        Hossein Amidi
 COMPANY:    
 CODE TYPE:    Register Transfer Level

 DESCRIPTION:    This module is the sub level RTL code of SDRAM Controller ASIC verilog
 code. It will detect the uProcessor command and create appropriate internal signal 
 for SDRAM Controller FSM.


 Hossein Amidi
 (C) April 2002

*********************************************************/

`timescale 1ns / 10ps

`include "parameter.v"

module cmd_detector(
    input reset,
    input clk0,
    input nop,
    input ref_req,
    input refresh,
    input reada,
    input writea,
    input preacharge,
    input load_mod,
    input [ref_dur_size - 1 : 0] ref_dur,

    output reg do_nop,
    output reg do_reada,
    output reg do_writea,
    output reg do_writea1,
    output reg do_refresh,
    output reg do_preacharge,
    output reg do_load_mod,
    output rw_flag
);

reg command_done;
reg [7:0] command_delay;

reg [3:0] rp_shift;
reg rp_done;

/**
 * This always block monitors the individual command lines and issues a command
 * to the next stage if there currently another command already running.
 */

always @(posedge reset or posedge clk0) begin
    if (reset == 1'b1) begin
        do_nop          <= 0;
        do_reada        <= 0;
        do_writea       <= 0;
        do_refresh      <= 0;
        do_preacharge   <= 0;
        do_load_mod     <= 0;
        command_done    <= 0;
        command_delay   <= 8'b0000_0000;
        rw_flag         <= 0;
        rp_shift        <= 0;
        rp_done         <= 0;
    end else begin
        //  Issue the appropriate command if the sdram is not currently busy
                if ((nop == 1)  & (command_done == 0) & (do_nop == 0)) // refresh
                    do_nop <= 1;                                   
                else
                    do_nop <= 0;


                if ((ref_req == 1 | refresh == 1) 
                    & command_done == 0 & do_refresh == 0 & rp_done == 0         
                    & do_reada == 0 & do_writea == 0) // refresh
                        do_refresh <= 1;
                else
                    do_refresh <= 0;

                if ((reada == 1) & (command_done == 0) & (do_reada == 0) & (rp_done == 0) & (ref_req == 0)) // reada
                    do_reada <= 1;
                else
                    do_reada <= 0;

                if ((writea == 1) & (command_done == 0) & (do_writea == 0) & (rp_done == 0) & (ref_req == 0))  // writea
                begin
                    do_writea <= 1;
                    do_writea1 <= 1;
                end else begin
                    do_writea <= 0;
                    do_writea1 <= 0;
                end

                if ((preacharge == 1) & (command_done == 0) & (do_preacharge == 0)) // preacharge
                        do_preacharge <= 1;
                else
                        do_preacharge <= 0;
 
                if ((load_mod == 1) & (command_done == 0) & (do_load_mod == 0)) // LOADMODE
                    do_load_mod <= 1;
                else
                    do_load_mod <= 0;
                                               
// set command_delay shift register and command_done flag
// The command delay shift register is a timer that is used to ensure that
// the SDRAM devices have had sufficient time to finish the last command.

                if ((do_refresh == 1) | (do_reada == 1) | (do_writea == 1) | (do_preacharge == 1)
                     | (do_load_mod))
                begin
                        command_delay <= 8'b11111111;
                        command_done  <= 1;
                        rw_flag <= do_reada;                                                  

                end
                
                else
                begin
                        command_done        <= command_delay[0];                // the command_delay shift operation
                        command_delay[6:0]  <= command_delay[7:1];                                
                        command_delay[7]    <= 0;
                end 
                
 
 // start additional timer that is used for the refresh, writea, reada commands               
                if (command_delay[0] == 0 & command_done == 1)
                begin
//                        rp_shift <= 4'b1111;
                        rp_shift <= ref_dur;
                        rp_done <= 1;
                end
                else
                begin
                        rp_done         <= rp_shift[0];
                        rp_shift[2:0]   <= rp_shift[3:1];
                        rp_shift[3]     <= 0;
                end
        end
end




endmodule
