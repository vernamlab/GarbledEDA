//////////////////////////////////////////////////////////////////
//                                                              //
//  Amber 2 Core top-Level module                               //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Instantiates the core consisting of fetch, instruction      //
//  decode, execute, and co-processor.                          //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//  Modification:                                               //
//      - Mohammad Hashemi, mhashemi@wpi.edu                    //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////


module a23_core
(
input                       i_clk,
input                       i_rst,

output   [31:0]             o_m_address, //data memory
output   [31:0]             o_m_write,
output                      o_m_write_en,
output   [3:0]              o_m_byte_enable,
input    [31:0]             i_m_read,        

output                      terminate
);

wire      [31:0]          execute_address;
wire      [31:0]          execute_address_nxt;  // un-registered version of execute_address to the cache rams
wire      [31:0]          write_data;
wire                      write_enable;
wire      [31:0]          read_data;
wire      [3:0]           byte_enable;
wire                      status_bits_flags_wen;
                 
wire     [31:0]           imm32;                   
wire     [4:0]            imm_shift_amount;   
wire     [3:0]            condition;               
wire     [31:0]           read_data_s2;            
wire     [4:0]            read_data_alignment;     

wire     [3:0]            rm_sel;                  
wire     [3:0]            rds_sel;                 
wire     [3:0]            rn_sel;                  
wire     [3:0]            rm_sel_nxt;
wire     [3:0]            rds_sel_nxt;
wire     [3:0]            rn_sel_nxt;
wire     [1:0]            barrel_shift_amount_sel; 
wire     [1:0]            barrel_shift_data_sel;   
wire     [1:0]            barrel_shift_function; 
wire                      use_carry_in;  
wire     [8:0]            alu_function;            
wire     [1:0]            multiply_function;
wire     [3:0]            address_sel;             
wire     [1:0]            pc_sel;                  
wire     [1:0]            byte_enable_sel;         
wire     [2:0]            status_bits_sel;                
wire     [2:0]            reg_write_sel;
wire                      write_data_wen;
wire                      pc_wen;                  
wire     [14:0]           reg_bank_wen;

wire                      multiply_done;


assign terminate = ({execute_address[31:2], 2'd0} == 32'h00000018) && (execute_address_nxt == 32'h0000001c);

a23_fetch u_fetch (
    .i_clk                              ( i_clk                             ),
    .i_rst                              ( i_rst                             ),

    .i_address                          ( {execute_address[31:2], 2'd0}     ),
    .i_address_nxt                      ( execute_address_nxt               ),
    .i_write_data                       ( write_data                        ),
    .i_write_enable                     ( write_enable                      ),
    .o_read_data                        ( read_data                         ),
    .i_byte_enable                      ( byte_enable                       ),     
    .i_cache_enable                     ( 1'b0                              ),     
    .i_cache_flush                      ( 1'b0                              ), 
    .i_cacheable_area                   ( 32'b0                             ),
    
    .o_m_address                        ( o_m_address                       ),
    .o_m_write                          ( o_m_write                         ),
    .o_m_write_en                       ( o_m_write_en                      ),
    .o_m_byte_enable                    ( o_m_byte_enable                   ),
    .i_m_read                           ( i_m_read                          )
);


a23_decode u_decode (
    .i_clk                              ( i_clk                             ),
    .i_rst                              ( i_rst                             ),
    
    // Instruction fetch or data read signals
    .i_read_data                        ( read_data                         ),                                          
    .i_execute_address                  ( execute_address                   ),                                          
    
    .o_read_data                        ( read_data_s2                      ),                                          
    .o_read_data_alignment              ( read_data_alignment               ),                                          
    .i_multiply_done                    ( multiply_done                     ),  
    .o_imm32                            ( imm32                             ),
    .o_imm_shift_amount                 ( imm_shift_amount                  ),
    .o_condition                        ( condition                         ),
    .o_rm_sel                           ( rm_sel                            ),
    .o_rds_sel                          ( rds_sel                           ),
    .o_rn_sel                           ( rn_sel                            ),
    .o_rm_sel_nxt                       ( rm_sel_nxt                        ),
    .o_rds_sel_nxt                      ( rds_sel_nxt                       ),
    .o_rn_sel_nxt                       ( rn_sel_nxt                        ),
    .o_barrel_shift_amount_sel          ( barrel_shift_amount_sel           ),
    .o_barrel_shift_data_sel            ( barrel_shift_data_sel             ),
    .o_barrel_shift_function            ( barrel_shift_function             ),
    .o_use_carry_in                     ( use_carry_in                      ),
    .o_alu_function                     ( alu_function                      ),
    .o_multiply_function                ( multiply_function                 ),
    .o_address_sel                      ( address_sel                       ),
    .o_pc_sel                           ( pc_sel                            ),
    .o_byte_enable_sel                  ( byte_enable_sel                   ),
    .o_status_bits_sel                  ( status_bits_sel                   ),
    .o_reg_write_sel                    ( reg_write_sel                     ),
    .o_write_data_wen                   ( write_data_wen                    ),
    .o_pc_wen                           ( pc_wen                            ),
    .o_reg_bank_wen                     ( reg_bank_wen                      ),
    .o_status_bits_flags_wen            ( status_bits_flags_wen             )
);


a23_execute u_execute (
    .i_clk                              ( i_clk                             ),
    .i_rst                              ( i_rst                             ),

    .i_read_data                        ( read_data_s2                      ),
    .i_read_data_alignment              ( read_data_alignment               ), 
    
    .o_write_data                       ( write_data                        ),
    .o_address                          ( execute_address                   ),
    .o_address_nxt                      ( execute_address_nxt               ),

    .o_byte_enable                      ( byte_enable                       ),
    .o_write_enable                     ( write_enable                      ),
    .o_multiply_done                    ( multiply_done                     ),   
    .i_imm32                            ( imm32                             ),   
    .i_imm_shift_amount                 ( imm_shift_amount                  ),

    .i_condition                        ( condition                         ),
  
    .i_rm_sel                           ( rm_sel                            ),   
    .i_rds_sel                          ( rds_sel                           ),   
    .i_rn_sel                           ( rn_sel                            ),   
    .i_rm_sel_nxt                       ( rm_sel_nxt                        ),
    .i_rds_sel_nxt                      ( rds_sel_nxt                       ),
    .i_rn_sel_nxt                       ( rn_sel_nxt                        ),
    .i_barrel_shift_amount_sel          ( barrel_shift_amount_sel           ),   
    .i_barrel_shift_data_sel            ( barrel_shift_data_sel             ),   
    .i_barrel_shift_function            ( barrel_shift_function             ),   
    .i_use_carry_in                     ( use_carry_in                      ),
    .i_alu_function                     ( alu_function                      ),   
    .i_multiply_function                ( multiply_function                 ),   
    .i_address_sel                      ( address_sel                       ),   
    .i_pc_sel                           ( pc_sel                            ),   
    .i_byte_enable_sel                  ( byte_enable_sel                   ),   
    .i_status_bits_sel                  ( status_bits_sel                   ),   
    .i_reg_write_sel                    ( reg_write_sel                     ),

    .i_write_data_wen                   ( write_data_wen                    ),      
    .i_pc_wen                           ( pc_wen                            ),   
    .i_reg_bank_wen                     ( reg_bank_wen                      ),
    .i_status_bits_flags_wen            ( status_bits_flags_wen             )
);


endmodule

//////////////////////////////////////////////////////////////////
//                                                              //
//  Arithmetic Logic Unit (ALU) for Amber 2 Core                //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Supported functions: 32-bit add and subtract, AND, OR,      //
//  XOR, NOT, Zero extent 8-bit numbers                         //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////


module a23_alu (
input       [31:0]          i_a_in,
input       [31:0]          i_b_in,
input                       i_barrel_shift_carry,
input                       i_status_bits_carry,
input       [8:0]           i_function,


output      [31:0]          o_out,
output      [3:0]           o_flags       // negative, zero, carry, overflow
);

wire     [31:0]         a, b, b_not;
wire     [31:0]         and_out, or_out, xor_out;
wire     [31:0]         sign_ex8_out, sign_ex_16_out;
wire     [31:0]         zero_ex8_out, zero_ex_16_out;
wire     [32:0]         fadder_out;
wire                    swap_sel;
wire                    not_sel;
wire     [1:0]          cin_sel;
wire                    cout_sel;
wire     [3:0]          out_sel;
wire                    carry_in;
wire                    carry_out;
wire                    overflow_out;
wire                    fadder_carry_out;

assign  { swap_sel, not_sel, cin_sel, cout_sel, out_sel } = i_function;


// ========================================================
// A Select
// ========================================================
assign a     = (swap_sel ) ? i_b_in : i_a_in ;

// ========================================================
// B Select
// ========================================================
assign b     = (swap_sel ) ? i_a_in : i_b_in ;
                             
// ========================================================
// Not Select
// ========================================================
assign b_not     = (not_sel ) ? ~b : b ;
                             
// ========================================================
// Cin Select
// ========================================================
assign carry_in  = (cin_sel==2'd0 ) ? 1'd0                   :
                   (cin_sel==2'd1 ) ? 1'd1                   :
                                      i_status_bits_carry    ;  // add with carry

// ========================================================
// Cout Select
// ========================================================
assign carry_out = (cout_sel==1'd0 ) ? fadder_carry_out     :
                                       i_barrel_shift_carry ;

// For non-addition/subtractions that incorporate a shift 
// operation, C is set to the last bit
// shifted out of the value by the shifter.


// ========================================================
// Overflow out
// ========================================================
// Only assert the overflow flag when using the adder
assign  overflow_out    = out_sel == 4'd1 &&
                            // overflow if adding two positive numbers and get a negative number
                          ( (!a[31] && !b_not[31] && fadder_out[31]) ||
                            // or adding two negative numbers and get a positive number
                            (a[31] && b_not[31] && !fadder_out[31])     );


// ========================================================
// ALU Operations
// ========================================================

assign fadder_out       = { 1'd0,a} + {1'd0,b_not} + {32'd0,carry_in};
assign fadder_carry_out = fadder_out[32];
assign and_out          = a & b_not;
assign or_out           = a | b_not;
assign xor_out          = a ^ b_not;
assign zero_ex8_out     = {24'd0,  b_not[7:0]};
assign zero_ex_16_out   = {16'd0,  b_not[15:0]};
assign sign_ex8_out     = {{24{b_not[7]}},  b_not[7:0]};
assign sign_ex_16_out   = {{16{b_not[15]}}, b_not[15:0]};
                          
// ========================================================
// Out Select
// ========================================================
assign o_out = out_sel == 4'd0 ? b_not            : 
               out_sel == 4'd1 ? fadder_out[31:0] : 
               out_sel == 4'd2 ? zero_ex_16_out   :
               out_sel == 4'd3 ? zero_ex8_out     :
               out_sel == 4'd4 ? sign_ex_16_out   :
               out_sel == 4'd5 ? sign_ex8_out     :
               out_sel == 4'd6 ? xor_out          :
               out_sel == 4'd7 ? or_out           :
                                 and_out          ;

wire only_carry;
// activate for adc
assign only_carry = (out_sel == 4'd1)  && (cin_sel == 2'd2);

assign o_flags = only_carry ?
                 {1'b0, 1'b0, carry_out, 1'b0}:
                 {
                 o_out[31],      // negative
                 |o_out == 1'd0,  // zero
                 carry_out,       // carry
                 overflow_out     // overflow
                 };
                         
                                     
endmodule

//////////////////////////////////////////////////////////////////
//                                                              //
//  Barrel Shifter for Amber 2 Core                             //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Provides 32-bit shifts LSL, LSR, ASR and ROR                //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////


module a23_barrel_shift (

input       [31:0]          i_in,
input                       i_carry_in,
input       [7:0]           i_shift_amount,     // uses 8 LSBs of Rs, or a 5 bit immediate constant
input       [1:0]           i_function,

output      [31:0]          o_out,
output                      o_carry_out

);

`include "a23_localparams.vh"

  // MSB is carry out
wire [32:0] lsl_out;
wire [32:0] lsr_out;
wire [32:0] asr_out;
wire [32:0] ror_out;


// Logical shift right zero is redundant as it is the same as logical shift left zero, so
// the assembler will convert LSR #0 (and ASR #0 and ROR #0) into LSL #0, and allow
// lsr #32 to be specified.

// lsl #0 is a special case, where the shifter carry out is the old value of the status flags
// C flag. The contents of Rm are used directly as the second operand.
// assign lsl_out = i_shift_imm_zero         ? {i_carry_in, i_in              } :  // fall through case 
//                  i_shift_amount == 8'd 0  ? {i_carry_in, i_in              } :  // fall through case
//                  i_shift_amount == 8'd 1  ? {i_in[31],   i_in[30: 0],  1'd0} :
//                  i_shift_amount == 8'd 2  ? {i_in[30],   i_in[29: 0],  2'd0} :
//                  i_shift_amount == 8'd 3  ? {i_in[29],   i_in[28: 0],  3'd0} :
//                  i_shift_amount == 8'd 4  ? {i_in[28],   i_in[27: 0],  4'd0} :
//                  i_shift_amount == 8'd 5  ? {i_in[27],   i_in[26: 0],  5'd0} :
//                  i_shift_amount == 8'd 6  ? {i_in[26],   i_in[25: 0],  6'd0} :
//                  i_shift_amount == 8'd 7  ? {i_in[25],   i_in[24: 0],  7'd0} :
//                  i_shift_amount == 8'd 8  ? {i_in[24],   i_in[23: 0],  8'd0} :
//                  i_shift_amount == 8'd 9  ? {i_in[23],   i_in[22: 0],  9'd0} :
//                  i_shift_amount == 8'd10  ? {i_in[22],   i_in[21: 0], 10'd0} :
//                  i_shift_amount == 8'd11  ? {i_in[21],   i_in[20: 0], 11'd0} :
//                  i_shift_amount == 8'd12  ? {i_in[20],   i_in[19: 0], 12'd0} :
//                  i_shift_amount == 8'd13  ? {i_in[19],   i_in[18: 0], 13'd0} :
//                  i_shift_amount == 8'd14  ? {i_in[18],   i_in[17: 0], 14'd0} :
//                  i_shift_amount == 8'd15  ? {i_in[17],   i_in[16: 0], 15'd0} :
//                  i_shift_amount == 8'd16  ? {i_in[16],   i_in[15: 0], 16'd0} :
//                  i_shift_amount == 8'd17  ? {i_in[15],   i_in[14: 0], 17'd0} :
//                  i_shift_amount == 8'd18  ? {i_in[14],   i_in[13: 0], 18'd0} :
//                  i_shift_amount == 8'd19  ? {i_in[13],   i_in[12: 0], 19'd0} :
//                  i_shift_amount == 8'd20  ? {i_in[12],   i_in[11: 0], 20'd0} :
//                  i_shift_amount == 8'd21  ? {i_in[11],   i_in[10: 0], 21'd0} :
//                  i_shift_amount == 8'd22  ? {i_in[10],   i_in[ 9: 0], 22'd0} :
//                  i_shift_amount == 8'd23  ? {i_in[ 9],   i_in[ 8: 0], 23'd0} :
//                  i_shift_amount == 8'd24  ? {i_in[ 8],   i_in[ 7: 0], 24'd0} :
//                  i_shift_amount == 8'd25  ? {i_in[ 7],   i_in[ 6: 0], 25'd0} :
//                  i_shift_amount == 8'd26  ? {i_in[ 6],   i_in[ 5: 0], 26'd0} :
//                  i_shift_amount == 8'd27  ? {i_in[ 5],   i_in[ 4: 0], 27'd0} :
//                  i_shift_amount == 8'd28  ? {i_in[ 4],   i_in[ 3: 0], 28'd0} :
//                  i_shift_amount == 8'd29  ? {i_in[ 3],   i_in[ 2: 0], 29'd0} :
//                  i_shift_amount == 8'd30  ? {i_in[ 2],   i_in[ 1: 0], 30'd0} :
//                  i_shift_amount == 8'd31  ? {i_in[ 1],   i_in[ 0: 0], 31'd0} :
//                  i_shift_amount == 8'd32  ? {i_in[ 0],   32'd0             } :  // 32
//                                             {1'd0,       32'd0             } ;  // > 32
                                            

wire [32:0] lsl_out_struct;
lsl_struct #(.CTRL(5)) u_lsl_struct(i_in, i_shift_amount[4:0], lsl_out_struct);

assign lsl_out[32] = i_shift_amount == 5'd0  ? i_carry_in: lsl_out_struct[32];
assign lsl_out[31:0] = lsl_out_struct[31:0];

// The form of the shift field which might be expected to correspond to LSR #0 is used
// to encode LSR #32, which has a zero result with bit 31 of Rm as the carry output. 
                                           // carry out, < -------- out ---------->
// assign lsr_out = i_shift_imm_zero         ? {i_in[31], 32'd0             } :
//                  i_shift_amount == 8'd 0  ? {i_carry_in, i_in            } :  // fall through case
//                  i_shift_amount == 8'd 1  ? {i_in[ 0],  1'd0, i_in[31: 1]} :
//                  i_shift_amount == 8'd 2  ? {i_in[ 1],  2'd0, i_in[31: 2]} :
//                  i_shift_amount == 8'd 3  ? {i_in[ 2],  3'd0, i_in[31: 3]} :
//                  i_shift_amount == 8'd 4  ? {i_in[ 3],  4'd0, i_in[31: 4]} :
//                  i_shift_amount == 8'd 5  ? {i_in[ 4],  5'd0, i_in[31: 5]} :
//                  i_shift_amount == 8'd 6  ? {i_in[ 5],  6'd0, i_in[31: 6]} :
//                  i_shift_amount == 8'd 7  ? {i_in[ 6],  7'd0, i_in[31: 7]} :
//                  i_shift_amount == 8'd 8  ? {i_in[ 7],  8'd0, i_in[31: 8]} :
//                  i_shift_amount == 8'd 9  ? {i_in[ 8],  9'd0, i_in[31: 9]} :
//                  i_shift_amount == 8'd10  ? {i_in[ 9], 10'd0, i_in[31:10]} :
//                  i_shift_amount == 8'd11  ? {i_in[10], 11'd0, i_in[31:11]} :
//                  i_shift_amount == 8'd12  ? {i_in[11], 12'd0, i_in[31:12]} :
//                  i_shift_amount == 8'd13  ? {i_in[12], 13'd0, i_in[31:13]} :
//                  i_shift_amount == 8'd14  ? {i_in[13], 14'd0, i_in[31:14]} :
//                  i_shift_amount == 8'd15  ? {i_in[14], 15'd0, i_in[31:15]} :
//                  i_shift_amount == 8'd16  ? {i_in[15], 16'd0, i_in[31:16]} :
//                  i_shift_amount == 8'd17  ? {i_in[16], 17'd0, i_in[31:17]} :
//                  i_shift_amount == 8'd18  ? {i_in[17], 18'd0, i_in[31:18]} :
//                  i_shift_amount == 8'd19  ? {i_in[18], 19'd0, i_in[31:19]} :
//                  i_shift_amount == 8'd20  ? {i_in[19], 20'd0, i_in[31:20]} :
//                  i_shift_amount == 8'd21  ? {i_in[20], 21'd0, i_in[31:21]} :
//                  i_shift_amount == 8'd22  ? {i_in[21], 22'd0, i_in[31:22]} :
//                  i_shift_amount == 8'd23  ? {i_in[22], 23'd0, i_in[31:23]} :
//                  i_shift_amount == 8'd24  ? {i_in[23], 24'd0, i_in[31:24]} :
//                  i_shift_amount == 8'd25  ? {i_in[24], 25'd0, i_in[31:25]} :
//                  i_shift_amount == 8'd26  ? {i_in[25], 26'd0, i_in[31:26]} :
//                  i_shift_amount == 8'd27  ? {i_in[26], 27'd0, i_in[31:27]} :
//                  i_shift_amount == 8'd28  ? {i_in[27], 28'd0, i_in[31:28]} :
//                  i_shift_amount == 8'd29  ? {i_in[28], 29'd0, i_in[31:29]} :
//                  i_shift_amount == 8'd30  ? {i_in[29], 30'd0, i_in[31:30]} :
//                  i_shift_amount == 8'd31  ? {i_in[30], 31'd0, i_in[31   ]} :
//                  i_shift_amount == 8'd32  ? {i_in[31], 32'd0             } :
//                                             {1'd0,     32'd0             } ;  // > 32



wire [32:0] lsr_out_struct;
lsr_struct #(.CTRL(5)) u_lsr_struct(i_in, i_shift_amount[4:0], lsr_out_struct);

assign lsr_out[32] = i_shift_amount == 5'd0  ? i_carry_in: lsr_out_struct[32];
assign lsr_out[31:0] = lsr_out_struct[31:0];


// The form of the shift field which might be expected to give ASR #0 is used to encode
// ASR #32. Bit 31 of Rm is again used as the carry output, and each bit of operand 2 is
// also equal to bit 31 of Rm. The result is therefore all ones or all zeros, according to
// the value of bit 31 of Rm.

                                          // carry out, < -------- out ---------->
// assign asr_out = i_shift_imm_zero         ? {i_in[31], {32{i_in[31]}}             } :
//                  i_shift_amount == 8'd 0  ? {i_carry_in, i_in                     } :  // fall through case
//                  i_shift_amount == 8'd 1  ? {i_in[ 0], { 2{i_in[31]}}, i_in[30: 1]} :
//                  i_shift_amount == 8'd 2  ? {i_in[ 1], { 3{i_in[31]}}, i_in[30: 2]} :
//                  i_shift_amount == 8'd 3  ? {i_in[ 2], { 4{i_in[31]}}, i_in[30: 3]} :
//                  i_shift_amount == 8'd 4  ? {i_in[ 3], { 5{i_in[31]}}, i_in[30: 4]} :
//                  i_shift_amount == 8'd 5  ? {i_in[ 4], { 6{i_in[31]}}, i_in[30: 5]} :
//                  i_shift_amount == 8'd 6  ? {i_in[ 5], { 7{i_in[31]}}, i_in[30: 6]} :
//                  i_shift_amount == 8'd 7  ? {i_in[ 6], { 8{i_in[31]}}, i_in[30: 7]} :
//                  i_shift_amount == 8'd 8  ? {i_in[ 7], { 9{i_in[31]}}, i_in[30: 8]} :
//                  i_shift_amount == 8'd 9  ? {i_in[ 8], {10{i_in[31]}}, i_in[30: 9]} :
//                  i_shift_amount == 8'd10  ? {i_in[ 9], {11{i_in[31]}}, i_in[30:10]} :
//                  i_shift_amount == 8'd11  ? {i_in[10], {12{i_in[31]}}, i_in[30:11]} :
//                  i_shift_amount == 8'd12  ? {i_in[11], {13{i_in[31]}}, i_in[30:12]} :
//                  i_shift_amount == 8'd13  ? {i_in[12], {14{i_in[31]}}, i_in[30:13]} :
//                  i_shift_amount == 8'd14  ? {i_in[13], {15{i_in[31]}}, i_in[30:14]} :
//                  i_shift_amount == 8'd15  ? {i_in[14], {16{i_in[31]}}, i_in[30:15]} :
//                  i_shift_amount == 8'd16  ? {i_in[15], {17{i_in[31]}}, i_in[30:16]} :
//                  i_shift_amount == 8'd17  ? {i_in[16], {18{i_in[31]}}, i_in[30:17]} :
//                  i_shift_amount == 8'd18  ? {i_in[17], {19{i_in[31]}}, i_in[30:18]} :
//                  i_shift_amount == 8'd19  ? {i_in[18], {20{i_in[31]}}, i_in[30:19]} :
//                  i_shift_amount == 8'd20  ? {i_in[19], {21{i_in[31]}}, i_in[30:20]} :
//                  i_shift_amount == 8'd21  ? {i_in[20], {22{i_in[31]}}, i_in[30:21]} :
//                  i_shift_amount == 8'd22  ? {i_in[21], {23{i_in[31]}}, i_in[30:22]} :
//                  i_shift_amount == 8'd23  ? {i_in[22], {24{i_in[31]}}, i_in[30:23]} :
//                  i_shift_amount == 8'd24  ? {i_in[23], {25{i_in[31]}}, i_in[30:24]} :
//                  i_shift_amount == 8'd25  ? {i_in[24], {26{i_in[31]}}, i_in[30:25]} :
//                  i_shift_amount == 8'd26  ? {i_in[25], {27{i_in[31]}}, i_in[30:26]} :
//                  i_shift_amount == 8'd27  ? {i_in[26], {28{i_in[31]}}, i_in[30:27]} :
//                  i_shift_amount == 8'd28  ? {i_in[27], {29{i_in[31]}}, i_in[30:28]} :
//                  i_shift_amount == 8'd29  ? {i_in[28], {30{i_in[31]}}, i_in[30:29]} :
//                  i_shift_amount == 8'd30  ? {i_in[29], {31{i_in[31]}}, i_in[30   ]} :
//                  i_shift_amount == 8'd31  ? {i_in[30], {32{i_in[31]}}             } :
//                                             {i_in[31], {32{i_in[31]}}             } ; // >= 32
                                            

wire [32:0] asr_out_struct;
asr_struct #(.CTRL(5)) u_asr_struct(i_in, i_shift_amount[4:0], asr_out_struct);

assign asr_out[32] = i_shift_amount == 5'd0  ? i_carry_in: asr_out_struct[32];
assign asr_out[31:0] = asr_out_struct[31:0];

                                          // carry out, < ------- out --------->
// assign ror_out = i_shift_imm_zero              ? {i_in[ 0], i_carry_in,  i_in[31: 1]} :  // RXR, (ROR w/ imm 0)
//                  i_shift_amount[7:0] == 8'd 0  ? {i_carry_in, i_in                  } :  // fall through case
//                  i_shift_amount[4:0] == 5'd 0  ? {i_in[31], i_in                    } :  // Rs > 31
//                  i_shift_amount[4:0] == 5'd 1  ? {i_in[ 0], i_in[    0], i_in[31: 1]} :
//                  i_shift_amount[4:0] == 5'd 2  ? {i_in[ 1], i_in[ 1: 0], i_in[31: 2]} :
//                  i_shift_amount[4:0] == 5'd 3  ? {i_in[ 2], i_in[ 2: 0], i_in[31: 3]} :
//                  i_shift_amount[4:0] == 5'd 4  ? {i_in[ 3], i_in[ 3: 0], i_in[31: 4]} :
//                  i_shift_amount[4:0] == 5'd 5  ? {i_in[ 4], i_in[ 4: 0], i_in[31: 5]} :
//                  i_shift_amount[4:0] == 5'd 6  ? {i_in[ 5], i_in[ 5: 0], i_in[31: 6]} :
//                  i_shift_amount[4:0] == 5'd 7  ? {i_in[ 6], i_in[ 6: 0], i_in[31: 7]} :
//                  i_shift_amount[4:0] == 5'd 8  ? {i_in[ 7], i_in[ 7: 0], i_in[31: 8]} :
//                  i_shift_amount[4:0] == 5'd 9  ? {i_in[ 8], i_in[ 8: 0], i_in[31: 9]} :
//                  i_shift_amount[4:0] == 5'd10  ? {i_in[ 9], i_in[ 9: 0], i_in[31:10]} :
//                  i_shift_amount[4:0] == 5'd11  ? {i_in[10], i_in[10: 0], i_in[31:11]} :
//                  i_shift_amount[4:0] == 5'd12  ? {i_in[11], i_in[11: 0], i_in[31:12]} :
//                  i_shift_amount[4:0] == 5'd13  ? {i_in[12], i_in[12: 0], i_in[31:13]} :
//                  i_shift_amount[4:0] == 5'd14  ? {i_in[13], i_in[13: 0], i_in[31:14]} :
//                  i_shift_amount[4:0] == 5'd15  ? {i_in[14], i_in[14: 0], i_in[31:15]} :
//                  i_shift_amount[4:0] == 5'd16  ? {i_in[15], i_in[15: 0], i_in[31:16]} :
//                  i_shift_amount[4:0] == 5'd17  ? {i_in[16], i_in[16: 0], i_in[31:17]} :
//                  i_shift_amount[4:0] == 5'd18  ? {i_in[17], i_in[17: 0], i_in[31:18]} :
//                  i_shift_amount[4:0] == 5'd19  ? {i_in[18], i_in[18: 0], i_in[31:19]} :
//                  i_shift_amount[4:0] == 5'd20  ? {i_in[19], i_in[19: 0], i_in[31:20]} :
//                  i_shift_amount[4:0] == 5'd21  ? {i_in[20], i_in[20: 0], i_in[31:21]} :
//                  i_shift_amount[4:0] == 5'd22  ? {i_in[21], i_in[21: 0], i_in[31:22]} :
//                  i_shift_amount[4:0] == 5'd23  ? {i_in[22], i_in[22: 0], i_in[31:23]} :
//                  i_shift_amount[4:0] == 5'd24  ? {i_in[23], i_in[23: 0], i_in[31:24]} :
//                  i_shift_amount[4:0] == 5'd25  ? {i_in[24], i_in[24: 0], i_in[31:25]} :
//                  i_shift_amount[4:0] == 5'd26  ? {i_in[25], i_in[25: 0], i_in[31:26]} :
//                  i_shift_amount[4:0] == 5'd27  ? {i_in[26], i_in[26: 0], i_in[31:27]} :
//                  i_shift_amount[4:0] == 5'd28  ? {i_in[27], i_in[27: 0], i_in[31:28]} :
//                  i_shift_amount[4:0] == 5'd29  ? {i_in[28], i_in[28: 0], i_in[31:29]} :
//                  i_shift_amount[4:0] == 5'd30  ? {i_in[29], i_in[29: 0], i_in[31:30]} :
//                                                  {i_in[30], i_in[30: 0], i_in[31:31]} ;
                 
wire [32:0] ror_out_struct;
ror_struct #(.CTRL(5)) u_ror_struct(i_in, i_shift_amount[4:0], ror_out_struct);


assign ror_out[32] = i_shift_amount == 5'd0  ? i_carry_in: ror_out_struct[32];
assign ror_out[31:0] = ror_out_struct[31:0];

 
assign {o_carry_out, o_out} = i_function == LSL ? lsl_out :
                              i_function == LSR ? lsr_out :
                              i_function == ASR ? asr_out :
                                                  ror_out ;

endmodule


module ror_struct
#( 
  parameter CTRL=5, 
  parameter WIDTH=2**CTRL
)
( 
  input   [WIDTH-1:0] in,
  input   [ CTRL-1:0] shift,
  output  [WIDTH:0] out 
);

  wire [WIDTH:0] tmp [CTRL:0];
  assign tmp[CTRL] = {in[31], in};
  assign out = tmp[0];
  genvar i;
  generate
    for (i = 0; i < CTRL; i = i + 1) begin: mux
      assign tmp[i] = shift[i] ? {tmp[i+1][(2**i)-1], tmp[i+1][(2**i)-1:0],tmp[i+1][WIDTH-1:(2**i)]} : tmp[i+1];
    end
  endgenerate
endmodule


module asr_struct
#( 
  parameter CTRL=5, 
  parameter WIDTH=2**CTRL
)
( 
  input   [WIDTH-1:0] in,
  input   [ CTRL-1:0] shift,
  output  [WIDTH:0] out 
);

  wire sign = in[WIDTH -1];

  wire [WIDTH:0] tmp [CTRL:0];
  assign tmp[CTRL] = {in[0], in};
  assign out = tmp[0];
  genvar i;
  generate
    for (i = 0; i < CTRL; i = i + 1) begin: mux
      assign tmp[i] = shift[i] ? {tmp[i+1][(2**i)-1], {(2**i){sign}}, tmp[i+1][WIDTH-1:(2**i)]} : tmp[i+1];
    end
  endgenerate
endmodule


module lsr_struct
#( 
  parameter CTRL=5, 
  parameter WIDTH=2**CTRL
)
( 
  input   [WIDTH-1:0] in,
  input   [ CTRL-1:0] shift,
  output  [WIDTH:0] out 
);

  wire sign = 1'b0;

  wire [WIDTH:0] tmp [CTRL:0];
  assign tmp[CTRL] = {in[0], in};
  assign out = tmp[0];
  genvar i;
  generate
    for (i = 0; i < CTRL; i = i + 1) begin: mux
      assign tmp[i] = shift[i] ? {tmp[i+1][(2**i)-1], {(2**i){sign}}, tmp[i+1][WIDTH-1:(2**i)]} : tmp[i+1];
    end
  endgenerate
endmodule

module lsl_struct
#( 
  parameter CTRL=5, 
  parameter WIDTH=2**CTRL
)
( 
  input   [WIDTH-1:0] in,
  input   [ CTRL-1:0] shift,
  output  [WIDTH:0] out 
);

  wire [WIDTH:0] tmp [CTRL:0];
  assign tmp[CTRL] = {in[WIDTH-1], in};
  assign out = tmp[0];
  genvar i, j;
  generate
    for (i = 0; i < CTRL; i = i + 1) begin: mux
      assign tmp[i] = shift[i] ? {tmp[i+1][WIDTH-(2**i)], tmp[i+1][WIDTH-(2**i)-1:0], {(2**i){1'b0}}} : tmp[i+1];
    end
  endgenerate
endmodule
//////////////////////////////////////////////////////////////////
//                                                              //
//  Decode stage of Amber 2 Core                                //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  This module is the most complex part of the Amber core      //
//  It decodes and sequences all instructions and handles all   //
//  interrupts                                                  //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////
`include "global_defines.vh"

module a23_decode
(
input                       i_clk,
input                       i_rst,
input       [31:0]          i_read_data,
input       [31:0]          i_execute_address,              // Registered address output by execute stage
                                                            // 2 LSBs of read address used for calculating
                                                            // shift in LDRB ops
input                       i_multiply_done,                // multiply unit is nearly done


// --------------------------------------------------
// Control signals to execute stage
// --------------------------------------------------
output reg  [31:0]          o_read_data,
output reg  [4:0]           o_read_data_alignment,  // 2 LSBs of read address used for calculating shift in LDRB ops

output reg  [31:0]          o_imm32,
output reg  [4:0]           o_imm_shift_amount,
output wire [3:0]           o_condition,
output reg  [3:0]           o_rm_sel,
output reg  [3:0]           o_rds_sel,
output reg  [3:0]           o_rn_sel,
output      [3:0]           o_rm_sel_nxt,
output      [3:0]           o_rds_sel_nxt,
output      [3:0]           o_rn_sel_nxt,
output reg  [1:0]           o_barrel_shift_amount_sel,
output reg  [1:0]           o_barrel_shift_data_sel,
output reg  [1:0]           o_barrel_shift_function,
output reg  [8:0]           o_alu_function,
output reg                  o_use_carry_in,
output reg  [1:0]           o_multiply_function,
output wire [3:0]           o_address_sel,
output wire [1:0]           o_pc_sel,
output reg  [1:0]           o_byte_enable_sel,        // byte, halfword or word write
output reg  [2:0]           o_status_bits_sel,
output reg  [2:0]           o_reg_write_sel,

output reg                  o_write_data_wen,
output wire                 o_pc_wen,
output reg  [14:0]          o_reg_bank_wen,
output reg                  o_status_bits_flags_wen
);

`include "a23_localparams.vh"
`include "a23_functions.vh"

localparam [4:0] RST_WAIT1      = 5'd0,
                 RST_WAIT2      = 5'd1,
                 INT_WAIT1      = 5'd2,
                 INT_WAIT2      = 5'd3,
                 EXECUTE        = 5'd4,
                 PRE_FETCH_EXEC = 5'd5,  // Execute the Pre-Fetched Instruction
                 MEM_WAIT1      = 5'd6,  // conditionally decode current instruction, in case
                                         // previous instruction does not execute in S2
                 MEM_WAIT2      = 5'd7,
                 PC_STALL1      = 5'd8,  // Program Counter altered
                                         // conditionally decude current instruction, in case
                                         // previous instruction does not execute in S2
                 PC_STALL2      = 5'd9,
                 MTRANS_EXEC1   = 5'd10,
                 MTRANS_EXEC2   = 5'd11,
                 MTRANS_EXEC3   = 5'd12,
                 MTRANS_EXEC3B  = 5'd13,
                 MTRANS_EXEC4   = 5'd14,
                 //MTRANS5_ABORT  = 5'd15,
                 MULT_PROC1     = 5'd16,  // first cycle, save pre fetch instruction
                 MULT_PROC2     = 5'd17,  // do multiplication
                 MULT_STORE     = 5'd19;  // save RdLo
                 //MULT_ACCUMU    = 5'd20;  // Accumulate add lower 32 bits
                 //SWAP_WRITE     = 5'd22,
                 //SWAP_WAIT1     = 5'd23,
                 //SWAP_WAIT2     = 5'd24,
                 //COPRO_WAIT     = 5'd25;


// ========================================================
// Internal signals
// ========================================================
wire    [31:0]         instruction;
wire    [31:0]         instruction_address;     // instruction virtual address, follows
                                                // the instruction
wire    [1:0]          instruction_sel;
reg     [3:0]          itype;
wire    [3:0]          opcode;
wire    [7:0]          imm8;
wire    [31:0]         offset12;
wire    [31:0]         offset24;
wire    [4:0]          shift_imm;

wire                   opcode_compare;
wire                   mem_op;
wire                   load_op;
wire                   store_op;
wire                   write_pc;
wire                   immediate_shifter_operand;
wire                   rds_use_rs;
wire                   branch;
wire                   mem_op_pre_indexed;
wire                   mem_op_post_indexed;

// Flop inputs
wire    [31:0]         imm32_nxt;
wire    [4:0]          imm_shift_amount_nxt;
wire    [3:0]          condition_nxt;
wire                   shift_extend;

reg     [1:0]          barrel_shift_function_nxt;
wire    [8:0]          alu_function_nxt;
reg                    use_carry_in_nxt;
reg     [1:0]          multiply_function_nxt;

reg     [1:0]          barrel_shift_amount_sel_nxt;
reg     [1:0]          barrel_shift_data_sel_nxt;
reg     [3:0]          address_sel_nxt;
reg     [1:0]          pc_sel_nxt;
reg     [1:0]          byte_enable_sel_nxt;
reg     [2:0]          status_bits_sel_nxt;
reg     [2:0]          reg_write_sel_nxt;

// ALU Function signals
reg                    alu_swap_sel_nxt;
reg                    alu_not_sel_nxt;
reg     [1:0]          alu_cin_sel_nxt;
reg                    alu_cout_sel_nxt;
reg     [3:0]          alu_out_sel_nxt;

reg                    write_data_wen_nxt;
reg                    copro_write_data_wen_nxt;
reg                    pc_wen_nxt;
reg     [3:0]          reg_bank_wsel_nxt;
reg                    status_bits_flags_wen_nxt;

reg                    saved_current_instruction_wen;   // saved load instruction
reg                    pre_fetch_instruction_wen;       // pre-fetch instruction

reg     [4:0]          control_state;
reg     [4:0]          control_state_nxt;


reg     [31:0]         saved_current_instruction;
reg     [31:0]         saved_current_instruction_address;       // virtual address of abort instruction
reg     [31:0]         pre_fetch_instruction;
reg     [31:0]         pre_fetch_instruction_address;           // virtual address of abort instruction

wire                   instruction_valid;

reg     [3:0]          mtrans_reg;              // the current register being accessed as part of STM/LDM
reg     [3:0]          mtrans_reg_d1;     // delayed by 1 period
reg     [3:0]          mtrans_reg_d2;     // delayed by 2 periods
reg     [31:0]         mtrans_instruction_nxt;

wire   [31:0]          mtrans_base_reg_change;
wire   [4:0]           mtrans_num_registers;
wire                   use_saved_current_instruction;
wire                   use_pre_fetch_instruction;
reg                    mtrans_r15;
reg                    mtrans_r15_nxt;

wire                   regop_set_flags;



// ========================================================
// registers for output ports with non-zero initial values
// ========================================================
reg  [3:0]           condition_r;             // 4'he = al
reg  [3:0]           address_sel_r;
reg  [1:0]           pc_sel_r;
reg                  pc_wen_r;

assign o_condition              = condition_r;
assign o_address_sel            = address_sel_r;
assign o_pc_sel                 = pc_sel_r;
assign o_pc_wen                 = pc_wen_r;



// ========================================================
// Instruction Decode
// ========================================================

// for instructions that take more than one cycle
// the instruction is saved in the 'saved_mem_instruction'
// register and then that register is used for the rest of
// the execution of the instruction.
// But if the instruction does not execute because of the
// condition, then need to select the next instruction to
// decode
assign use_saved_current_instruction = ( control_state == MEM_WAIT1     ||
                                         control_state == MEM_WAIT2     ||
                                         control_state == MTRANS_EXEC1  ||
                                         control_state == MTRANS_EXEC2  ||
                                         control_state == MTRANS_EXEC3  ||
                                         control_state == MTRANS_EXEC3B ||
                                         control_state == MTRANS_EXEC4  ||
                                         control_state == MULT_PROC1    ||
                                         control_state == MULT_PROC2    ||
                                         //control_state == MULT_ACCUMU   ||
                                         control_state == MULT_STORE    );

assign use_pre_fetch_instruction = control_state == PRE_FETCH_EXEC;


assign instruction_sel  =         use_saved_current_instruction  ? 2'd1 :  // saved_current_instruction
                                  use_pre_fetch_instruction      ? 2'd2 :  // pre_fetch_instruction
                                                                   2'd0 ;  // o_read_data

assign instruction      =         instruction_sel == 2'd0 ? o_read_data               :
                                  instruction_sel == 2'd1 ? saved_current_instruction :
                                                            pre_fetch_instruction     ;
assign instruction_address =      instruction_sel == 2'd1 ? saved_current_instruction_address :
                                                            pre_fetch_instruction_address     ;

// Instruction Decode - Order is important!
always @*
    casez ({instruction[27:20], instruction[7:4]})
        12'b00010?001001 : itype = SWAP;
        12'b000000??1001 : itype = MULT;
        12'b00?????????? : itype = REGOP;
        12'b01?????????? : itype = TRANS;
        12'b100????????? : itype = MTRANS;
        12'b101????????? : itype = BRANCH;
        12'b110????????? : itype = CODTRANS;
        12'b1110???????0 : itype = COREGOP;
        12'b1110???????1 : itype = CORTRANS;
        default:           itype = SWI;
    endcase


// ========================================================
// Fixed fields within the instruction
// ========================================================

assign opcode        = instruction[24:21];
assign condition_nxt = instruction[31:28];

assign o_rm_sel_nxt    = instruction[3:0];

assign o_rn_sel_nxt    = branch  ? 4'd15              : // Use PC to calculate branch destination
                                   instruction[19:16] ;

assign o_rds_sel_nxt   = itype == MTRANS              ? mtrans_reg         :
                         branch                       ? 4'd15              : // Update the PC
                         rds_use_rs                   ? instruction[11:8]  :
                                                        instruction[15:12] ;


assign shift_imm     = instruction[11:7];

// this is used for RRX
assign shift_extend  = !instruction[25] && !instruction[4] && !(|instruction[11:7]) && instruction[6:5] == 2'b11;

assign offset12      = { 20'h0, instruction[11:0]};
assign offset24      = {{6{instruction[23]}}, instruction[23:0], 2'd0 }; // sign extend
assign imm8          = instruction[7:0];

assign immediate_shifter_operand = instruction[25];
assign rds_use_rs                = (itype == REGOP && !instruction[25] && instruction[4]) ||
                                   (itype == MULT &&
                                    (control_state == MULT_PROC1  ||
                                     control_state == MULT_PROC2  ||
                                     instruction_valid )) ;
assign branch                    = itype == BRANCH;
assign opcode_compare =
            opcode == CMP ||
            opcode == CMN ||
            opcode == TEQ ||
            opcode == TST ;


assign mem_op               = itype == TRANS;
assign load_op              = mem_op && instruction[20];
assign store_op             = mem_op && !instruction[20];
assign write_pc             = pc_wen_nxt && pc_sel_nxt != 2'd0;
assign regop_set_flags      = itype == REGOP && instruction[20];

assign mem_op_pre_indexed   =  instruction[24] && instruction[21];
assign mem_op_post_indexed  = !instruction[24];

assign imm32_nxt            =  // add 0 to Rm
                               itype == MULT               ? {  32'd0                      } :

                               // 4 x number of registers
                               itype == MTRANS             ? {  mtrans_base_reg_change     } :
                               itype == BRANCH             ? {  offset24                   } :
                               itype == TRANS              ? {  offset12                   } :
                               instruction[11:8] == 4'h0  ? {            24'h0, imm8[7:0] } :
                               instruction[11:8] == 4'h1  ? { imm8[1:0], 24'h0, imm8[7:2] } :
                               instruction[11:8] == 4'h2  ? { imm8[3:0], 24'h0, imm8[7:4] } :
                               instruction[11:8] == 4'h3  ? { imm8[5:0], 24'h0, imm8[7:6] } :
                               instruction[11:8] == 4'h4  ? { imm8[7:0], 24'h0            } :
                               instruction[11:8] == 4'h5  ? { 2'h0,  imm8[7:0], 22'h0     } :
                               instruction[11:8] == 4'h6  ? { 4'h0,  imm8[7:0], 20'h0     } :
                               instruction[11:8] == 4'h7  ? { 6'h0,  imm8[7:0], 18'h0     } :
                               instruction[11:8] == 4'h8  ? { 8'h0,  imm8[7:0], 16'h0     } :
                               instruction[11:8] == 4'h9  ? { 10'h0, imm8[7:0], 14'h0     } :
                               instruction[11:8] == 4'ha  ? { 12'h0, imm8[7:0], 12'h0     } :
                               instruction[11:8] == 4'hb  ? { 14'h0, imm8[7:0], 10'h0     } :
                               instruction[11:8] == 4'hc  ? { 16'h0, imm8[7:0], 8'h0      } :
                               instruction[11:8] == 4'hd  ? { 18'h0, imm8[7:0], 6'h0      } :
                               instruction[11:8] == 4'he  ? { 20'h0, imm8[7:0], 4'h0      } :
                                                            { 22'h0, imm8[7:0], 2'h0      } ;


assign imm_shift_amount_nxt = shift_imm ;
assign alu_function_nxt     = { alu_swap_sel_nxt,
                                alu_not_sel_nxt,
                                alu_cin_sel_nxt,
                                alu_cout_sel_nxt,
                                alu_out_sel_nxt  };


// ========================================================
// MTRANS Operations
// ========================================================

   // Bit 15 = r15
   // Bit 0  = R0
   // In LDM and STM instructions R0 is loaded or stored first
always @*
    casez (instruction[15:0])
    16'b???????????????1 : mtrans_reg = 4'h0 ;
    16'b??????????????10 : mtrans_reg = 4'h1 ;
    16'b?????????????100 : mtrans_reg = 4'h2 ;
    16'b????????????1000 : mtrans_reg = 4'h3 ;
    16'b???????????10000 : mtrans_reg = 4'h4 ;
    16'b??????????100000 : mtrans_reg = 4'h5 ;
    16'b?????????1000000 : mtrans_reg = 4'h6 ;
    16'b????????10000000 : mtrans_reg = 4'h7 ;
    16'b???????100000000 : mtrans_reg = 4'h8 ;
    16'b??????1000000000 : mtrans_reg = 4'h9 ;
    16'b?????10000000000 : mtrans_reg = 4'ha ;
    16'b????100000000000 : mtrans_reg = 4'hb ;
    16'b???1000000000000 : mtrans_reg = 4'hc ;
    16'b??10000000000000 : mtrans_reg = 4'hd ;
    16'b?100000000000000 : mtrans_reg = 4'he ;
    default              : mtrans_reg = 4'hf ;
    endcase


always @*
    casez (instruction[15:0])
    16'b???????????????1 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 1],  1'd0};
    16'b??????????????10 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 2],  2'd0};
    16'b?????????????100 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 3],  3'd0};
    16'b????????????1000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 4],  4'd0};
    16'b???????????10000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 5],  5'd0};
    16'b??????????100000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 6],  6'd0};
    16'b?????????1000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 7],  7'd0};
    16'b????????10000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 8],  8'd0};
    16'b???????100000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 9],  9'd0};
    16'b??????1000000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15:10], 10'd0};
    16'b?????10000000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15:11], 11'd0};
    16'b????100000000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15:12], 12'd0};
    16'b???1000000000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15:13], 13'd0};
    16'b??10000000000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15:14], 14'd0};
    16'b?100000000000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15   ], 15'd0};
    default              : mtrans_instruction_nxt = {instruction[31:16],                     16'd0};
    endcase


// number of registers to be stored
assign mtrans_num_registers =   {4'd0, instruction[15]} +
                                {4'd0, instruction[14]} +
                                {4'd0, instruction[13]} +
                                {4'd0, instruction[12]} +
                                {4'd0, instruction[11]} +
                                {4'd0, instruction[10]} +
                                {4'd0, instruction[ 9]} +
                                {4'd0, instruction[ 8]} +
                                {4'd0, instruction[ 7]} +
                                {4'd0, instruction[ 6]} +
                                {4'd0, instruction[ 5]} +
                                {4'd0, instruction[ 4]} +
                                {4'd0, instruction[ 3]} +
                                {4'd0, instruction[ 2]} +
                                {4'd0, instruction[ 1]} +
                                {4'd0, instruction[ 0]} ;

// 4 x number of registers to be stored
assign mtrans_base_reg_change = {25'd0, mtrans_num_registers, 2'd0};


// ========================================================
// Generate control signals
// ========================================================
always @(*)
    begin

    // Save an instruction to use later
    saved_current_instruction_wen   = 1'd0;
    pre_fetch_instruction_wen       = 1'd0;
    mtrans_r15_nxt                  = mtrans_r15;

    // default Mux Select values
    barrel_shift_amount_sel_nxt     = 'd0;  // don't shift the input
    barrel_shift_data_sel_nxt       = 'd0;  // immediate value
    barrel_shift_function_nxt       = 'd0;
    use_carry_in_nxt                = 'd0;
    multiply_function_nxt           = 'd0;
    address_sel_nxt                 = 'd0;
    pc_sel_nxt                      = 'd0;
    byte_enable_sel_nxt             = 'd0;
    status_bits_sel_nxt             = 'd0;
    reg_write_sel_nxt               = 'd0;

    // ALU Muxes
    alu_swap_sel_nxt                = 'd0;
    alu_not_sel_nxt                 = 'd0;
    alu_cin_sel_nxt                 = 'd0;
    alu_cout_sel_nxt                = 'd0;
    alu_out_sel_nxt                 = 'd0;

    // default Flop Write Enable values
    write_data_wen_nxt              = 'd0;
    pc_wen_nxt                      = 'd1;
    reg_bank_wsel_nxt               = 'hF;  // Don't select any
    status_bits_flags_wen_nxt       = 'd0;

    if ( instruction_valid ) begin
        if ( itype == REGOP ) begin
            if ( !opcode_compare ) begin
                // Check is the load destination is the PC
                if (instruction[15:12]  == 4'd15) begin
                    pc_sel_nxt      = 2'd1; // alu_out
                    address_sel_nxt = 4'd1; // alu_out
                end else
                    reg_bank_wsel_nxt = instruction[15:12];
            end

            if ( !immediate_shifter_operand )
                barrel_shift_function_nxt  = instruction[6:5];

            if ( !immediate_shifter_operand )
                barrel_shift_data_sel_nxt = 2'd2; // Shift value from Rm register

            if ( !immediate_shifter_operand && instruction[4] )
                barrel_shift_amount_sel_nxt = 2'd1; // Shift amount from Rs registter

            if ( !immediate_shifter_operand && !instruction[4] )
                barrel_shift_amount_sel_nxt = 2'd2; // Shift immediate amount

            // regops that do not change the overflow flag
            if ( opcode == AND || opcode == EOR || opcode == TST || opcode == TEQ ||
                 opcode == ORR || opcode == MOV || opcode == BIC || opcode == MVN )
                status_bits_sel_nxt = 3'd5;

            if ( opcode == ADD || opcode == CMN ) begin  // CMN is just like an ADD
                alu_out_sel_nxt  = 4'd1; // Add
                use_carry_in_nxt = shift_extend;
            end

            if ( opcode == ADC ) begin // Add with Carry
                alu_out_sel_nxt  = 4'd1; // Add
                alu_cin_sel_nxt  = 2'd2; // carry in from status_bits
                use_carry_in_nxt = shift_extend;
            end

            if ( opcode == SUB || opcode == CMP ) begin// Subtract
                alu_out_sel_nxt  = 4'd1; // Add
                alu_cin_sel_nxt  = 2'd1; // cin = 1
                alu_not_sel_nxt  = 1'd1; // invert B
            end

            // SBC (Subtract with Carry) subtracts the value of its
            // second operand and the value of NOT(Carry flag) from
            // the value of its first operand.
            //  Rd = Rn - shifter_operand - NOT(C Flag)
            if ( opcode == SBC ) begin// Subtract with Carry
                alu_out_sel_nxt  = 4'd1; // Add
                alu_cin_sel_nxt  = 2'd2; // carry in from status_bits
                alu_not_sel_nxt  = 1'd1; // invert B
                use_carry_in_nxt = 1'd1;
            end

            if ( opcode == RSB ) begin // Reverse Subtract
                alu_out_sel_nxt  = 4'd1; // Add
                alu_cin_sel_nxt  = 2'd1; // cin = 1
                alu_not_sel_nxt  = 1'd1; // invert B
                alu_swap_sel_nxt = 1'd1; // swap A and B
                end

            if ( opcode == RSC ) begin // Reverse Subtract with carry
                alu_out_sel_nxt  = 4'd1; // Add
                alu_cin_sel_nxt  = 2'd2; // carry in from status_bits
                alu_not_sel_nxt  = 1'd1; // invert B
                alu_swap_sel_nxt = 1'd1; // swap A and B
                use_carry_in_nxt = 1'd1;
                end

            if ( opcode == AND || opcode == TST ) begin // Logical AND, Test  (using AND operator)
                alu_out_sel_nxt  = 4'd8;  // AND
                alu_cout_sel_nxt = 1'd1;  // i_barrel_shift_carry
                end

            if ( opcode == EOR || opcode == TEQ ) begin // Logical Exclusive OR, Test Equivalence (using EOR operator)
                alu_out_sel_nxt  = 4'd6; // XOR
                alu_cout_sel_nxt = 1'd1; // i_barrel_shift_carry
                use_carry_in_nxt = 1'd1;
                end

            if ( opcode == ORR ) begin
                alu_out_sel_nxt  = 4'd7; // OR
                alu_cout_sel_nxt = 1'd1; // i_barrel_shift_carry
                use_carry_in_nxt = 1'd1;
                end

            if ( opcode == BIC ) begin // Bit Clear (using AND & NOT operators)
                alu_out_sel_nxt  = 4'd8;  // AND
                alu_not_sel_nxt  = 1'd1;  // invert B
                alu_cout_sel_nxt = 1'd1;  // i_barrel_shift_carry
                use_carry_in_nxt = 1'd1;
                end

            if ( opcode == MOV ) begin // Move
                alu_cout_sel_nxt = 1'd1;  // i_barrel_shift_carry
                use_carry_in_nxt = 1'd1;
                end

            if ( opcode == MVN ) begin // Move NOT
                alu_not_sel_nxt  = 1'd1; // invert B
                alu_cout_sel_nxt = 1'd1; // i_barrel_shift_carry
                use_carry_in_nxt = 1'd1;
                end
            end

        // Load & Store instructions
        if ( mem_op ) begin
            saved_current_instruction_wen   = 1'd1; // Save the memory access instruction to refer back to later
            pc_wen_nxt                      = 1'd0; // hold current PC value
            alu_out_sel_nxt                 = 4'd1; // Add

            if ( !instruction[23] ) begin // U: Subtract offset
                alu_cin_sel_nxt  = 2'd1; // cin = 1
                alu_not_sel_nxt  = 1'd1; // invert B
            end

            if ( store_op ) begin
                write_data_wen_nxt = 1'd1;
                if ( itype == TRANS && instruction[22] )
                    byte_enable_sel_nxt = 2'd1;         // Save byte
            end

                // need to update the register holding the address ?
                // This is Rn bits [19:16]
            if ( mem_op_pre_indexed || mem_op_post_indexed ) begin
                // Check is the load destination is the PC
                if ( o_rn_sel_nxt  == 4'd15 )
                    pc_sel_nxt = 2'd1;
                else
                    reg_bank_wsel_nxt = o_rn_sel_nxt;
            end

                // if post-indexed, then use Rn rather than ALU output, as address
            if ( mem_op_post_indexed )
               address_sel_nxt = 4'd4; // Rn
            else
               address_sel_nxt = 4'd1; // alu out

            if ( instruction[25] && itype ==  TRANS )
                barrel_shift_data_sel_nxt = 2'd2; // Shift value from Rm register

            if ( itype == TRANS && instruction[25] && shift_imm != 5'd0 ) begin
                barrel_shift_function_nxt   = instruction[6:5];
                barrel_shift_amount_sel_nxt = 2'd2; // imm_shift_amount
            end
        end

        if ( itype == BRANCH ) begin
            pc_sel_nxt      = 2'd3; // branch_pc
            address_sel_nxt = 4'd8; // branch_address
            alu_out_sel_nxt = 4'd1; // Add

            if ( instruction[24] ) begin // Link
                reg_bank_wsel_nxt  = 4'd14;  // Save PC to LR
                reg_write_sel_nxt = 3'd1;            // pc - 32'd4
            end
        end

        if ( itype == MTRANS ) begin
            saved_current_instruction_wen   = 1'd1; // Save the memory access instruction to refer back to later
            pc_wen_nxt                      = 1'd0; // hold current PC value
            alu_out_sel_nxt                 = 4'd1; // Add
            mtrans_r15_nxt                  = instruction[15];  // load or save r15 ?

            // Increment or Decrement
            if ( instruction[23] ) begin// increment
                
                if ( instruction[24] )    // increment before
                    address_sel_nxt = 4'd7; // Rn + 4
                else
                    address_sel_nxt = 4'd4; // Rn
            end else begin// decrement
                alu_cin_sel_nxt  = 2'd1; // cin = 1
                alu_not_sel_nxt  = 1'd1; // invert B
                if ( !instruction[24] )    // decrement after
                    address_sel_nxt  = 4'd6; // alu out + 4
                else
                    address_sel_nxt  = 4'd1; // alu out
            end

            // Load or store ?
            if ( !instruction[20] )  // Store
                write_data_wen_nxt = 1'd1;

            // update the base register ?
            if ( instruction[21] )  // the W bit
                reg_bank_wsel_nxt  = o_rn_sel_nxt;
        end


        if ( itype == MULT ) begin
            multiply_function_nxt[0]        = 1'd1; // set enable
                                                    // some bits can be changed just below
            saved_current_instruction_wen   = 1'd1; // Save the Multiply instruction to
                                                    // refer back to later
            pc_wen_nxt                      = 1'd0; // hold current PC value

            if ( instruction[21] )
                multiply_function_nxt[1]    = 1'd1; // accumulate
        end

        if ( regop_set_flags ) begin
            status_bits_flags_wen_nxt = 1'd1;

            // If <Rd> is r15, the ALU output is copied to the Status Bits.
            // Not allowed to use r15 for mul or lma instructions
            if ( instruction[15:12] == 4'd15 ) begin
                status_bits_sel_nxt       = 3'd1; // alu out
            end
        end

    end


    // previous instruction was either ldr or sdr
    // if it is currently executing in the execute stage do the following
    if ( control_state == MEM_WAIT1 ) begin
        // Save the next instruction to execute later
        // Do this even if this instruction does not execute because of Condition
        pre_fetch_instruction_wen   = 1'd1;
        address_sel_nxt             = 4'd3; // pc  (not pc + 4)
        pc_wen_nxt                  = 1'd0; // hold current PC value
    end


    // completion of load operation
    if ( control_state == MEM_WAIT2 && load_op ) begin
        barrel_shift_data_sel_nxt   = 2'd1;  // load word from memory
        barrel_shift_amount_sel_nxt = 2'd3;  // shift by address[1:0] x 8

        // shift needed
        if ( i_execute_address[1:0] != 2'd0 )
            barrel_shift_function_nxt = ROR;

        // load a byte
        if ( itype == TRANS && instruction[22] )
            alu_out_sel_nxt             = 4'd3;  // zero_extend8
        // Check if the load destination is the PC
        if (instruction[15:12]  == 4'd15) begin
            pc_sel_nxt      = 2'd1; // alu_out
            address_sel_nxt = 4'd1; // alu_out
        end else
            reg_bank_wsel_nxt = instruction[15:12];
    end


    // second cycle of multiple load or store
    if ( control_state == MTRANS_EXEC1 ) begin
        // Save the next instruction to execute later
        // Do this even if this instruction does not execute because of Condition
        pre_fetch_instruction_wen   = 1'd1;

        address_sel_nxt             = 4'd5;  // o_address
        pc_wen_nxt                  = 1'd0;  // hold current PC value
        if ( !instruction[20] ) // Store
            write_data_wen_nxt = 1'd1;
    end


    // third cycle of multiple load or store
    if ( control_state == MTRANS_EXEC2 ) begin
        address_sel_nxt             = 4'd5;  // o_address
        pc_wen_nxt                  = 1'd0;  // hold current PC value
        barrel_shift_data_sel_nxt   = 2'd1;  // load word from memory

        // Load or Store
        if ( instruction[20] ) // Load
                reg_bank_wsel_nxt = mtrans_reg_d2;
        else // Store
            write_data_wen_nxt = 1'd1;
    end

        // second or fourth cycle of multiple load or store
    if ( control_state == MTRANS_EXEC3 ) begin
        address_sel_nxt             = 4'd3; // pc  (not pc + 4)
        pc_wen_nxt                  = 1'd0;  // hold current PC value
        barrel_shift_data_sel_nxt   = 2'd1;  // load word from memory

        // Can never be loading the PC in this state, as the PC is always
        // the last register in the set to be loaded
        if ( instruction[20] ) // Load
            reg_bank_wsel_nxt = mtrans_reg_d2;
    end

    // state is used for LMD/STM of a single register
    if ( control_state == MTRANS_EXEC3B ) begin
        // Save the next instruction to execute later
        // Do this even if this instruction does not execute because of Condition
        pre_fetch_instruction_wen   = 1'd1;

        address_sel_nxt             = 4'd3;  // pc  (not pc + 4)
        pc_wen_nxt                  = 1'd0;  // hold current PC value

    end

    if ( control_state == MTRANS_EXEC4 ) begin
        barrel_shift_data_sel_nxt   = 2'd1;  // load word from memory
        if ( instruction[20] ) begin// Load
            if ( mtrans_reg_d2 == 4'd15 ) begin// load new value into PC
                address_sel_nxt = 4'd1; // alu_out - read instructions using new PC value
                pc_sel_nxt      = 2'd1; // alu_out
                pc_wen_nxt      = 1'd1; // write PC

                // ldm with S bit and pc: the Status bits are updated
                // Node this must be done only at the end
                // so the register set is the set in the mode before it
                // gets changed.
                if ( instruction[22] ) begin
                     status_bits_sel_nxt           = 3'd1; // alu out
                     status_bits_flags_wen_nxt     = 1'd1;
                end
            end else begin
                reg_bank_wsel_nxt = mtrans_reg_d2;
            end
        end
    end


    // Multiply or Multiply-Accumulate
    if ( control_state == MULT_PROC1 ) begin
        // Save the next instruction to execute later
        // Do this even if this instruction does not execute because of Condition
        pre_fetch_instruction_wen   = 1'd1;
        pc_wen_nxt                  = 1'd0;  // hold current PC value
        multiply_function_nxt       = o_multiply_function;
    end


        // Multiply or Multiply-Accumulate
        // Do multiplication
        // Wait for done or accumulate signal
    if ( control_state == MULT_PROC2 ) begin
        // Save the next instruction to execute later
        // Do this even if this instruction does not execute because of Condition
        pc_wen_nxt              = 1'd0;  // hold current PC value
        address_sel_nxt         = 4'd3;  // pc  (not pc + 4)
        multiply_function_nxt   = o_multiply_function;
    end 


    // Save RdLo
    // always last cycle of all multiply or multiply accumulate operations
    if ( control_state == MULT_STORE ) begin
        reg_write_sel_nxt     = 3'd2; // multiply_out
        multiply_function_nxt = o_multiply_function;

        reg_bank_wsel_nxt      = instruction[19:16]; // Rd
     
        if ( instruction[20] ) begin // the 'S' bit
            status_bits_sel_nxt       = 3'd4; // { multiply_flags, status_bits_flags[1:0] }
            status_bits_flags_wen_nxt = 1'd1;
        end
    end
end


// ========================================================
// Next State Logic
// ========================================================

assign instruction_valid = (control_state == EXECUTE || control_state == PRE_FETCH_EXEC);


 always @* begin
    // default is to hold the current state
    control_state_nxt = control_state;

    // Note: The order is important here
    if ( control_state == RST_WAIT1 )          
        control_state_nxt = RST_WAIT2;
    else if ( control_state == RST_WAIT2 )     
        control_state_nxt = EXECUTE;
    else if ( control_state == INT_WAIT1 )     
        control_state_nxt = INT_WAIT2;
    else if ( control_state == INT_WAIT2 )     
        control_state_nxt = EXECUTE;
    else if ( control_state == PC_STALL1 )     
        control_state_nxt = PC_STALL2;
    else if ( control_state == PC_STALL2 )     
        control_state_nxt = EXECUTE;
    else if ( control_state == MULT_STORE )    
        control_state_nxt = PRE_FETCH_EXEC;
    else if ( control_state == MEM_WAIT1 )     
        control_state_nxt = MEM_WAIT2;
    else if ( control_state == MEM_WAIT2) begin
        if ( write_pc ) // writing to the PC!!
            control_state_nxt = PC_STALL1;
        else
            control_state_nxt = PRE_FETCH_EXEC;
    end else if ( control_state == MTRANS_EXEC1 ) begin
        if (mtrans_instruction_nxt[15:0] != 16'd0)
            control_state_nxt = MTRANS_EXEC2;
        else   // if the register list holds a single register
            control_state_nxt = MTRANS_EXEC3;
    end else if ( control_state == MTRANS_EXEC2 && mtrans_num_registers == 5'd1 ) 
        // Stay in State MTRANS_EXEC2 until the full list of registers to
        // load or store has been processed
        control_state_nxt = MTRANS_EXEC3;
    else if ( control_state == MTRANS_EXEC3 )     
        control_state_nxt = MTRANS_EXEC4;
    else if ( control_state == MTRANS_EXEC3B )    
        control_state_nxt = MTRANS_EXEC4;
    else if ( control_state == MTRANS_EXEC4  ) begin
        if (write_pc) // writing to the PC!!
            control_state_nxt = PC_STALL1;
        else
            control_state_nxt = PRE_FETCH_EXEC;
    end else if ( control_state == MULT_PROC1 ) begin
        control_state_nxt = MULT_PROC2;
    end else if ( control_state == MULT_PROC2 ) begin
        if ( i_multiply_done )
            control_state_nxt = MULT_STORE;
    end else if ( instruction_valid ) begin
        control_state_nxt = EXECUTE;

        if ( mem_op )  // load or store word or byte
             control_state_nxt = MEM_WAIT1;
        if ( write_pc )
             control_state_nxt = PC_STALL1;
        if ( itype == MTRANS ) begin
            if ( mtrans_num_registers != 5'd0 ) begin
                // check for LDM/STM of a single register
                if ( mtrans_num_registers == 5'd1 )
                    control_state_nxt = MTRANS_EXEC3B;
                else
                    control_state_nxt = MTRANS_EXEC1;
            end else begin
                control_state_nxt = MTRANS_EXEC3;
            end
        end

        if ( itype == MULT )
            control_state_nxt = MULT_PROC1;
    end
end


// ========================================================
// Register Update
// ========================================================

always @ ( posedge i_clk  or posedge i_rst)
    if(i_rst) begin
        o_read_data                 <= 'b0;
        o_read_data_alignment       <= 'd0;
        o_imm32                     <= 'd0;
        o_imm_shift_amount          <= 'd0;
        condition_r                 <=  4'he;
        o_rm_sel                    <= 'd0;
        o_rds_sel                   <= 'd0;
        o_rn_sel                    <= 'd0;
        o_barrel_shift_amount_sel   <= 'd0;
        o_barrel_shift_data_sel     <= 'd0;
        o_barrel_shift_function     <= 'd0;
        o_alu_function              <= 'd0;
        o_use_carry_in              <= 'd0;
        o_multiply_function         <= 'd0;
        address_sel_r               <= 'd0;
        pc_sel_r                    <= 'd0;
        o_byte_enable_sel           <= 'd0;
        o_status_bits_sel           <= 'd0;
        o_reg_write_sel             <= 'd0;
        o_write_data_wen            <= 'd0;
        pc_wen_r                    <= 1'd1;
        o_reg_bank_wen              <= 'd0;
        o_status_bits_flags_wen     <= 'd0;
        mtrans_r15                  <= 'd0;
        control_state               <= RST_WAIT2;
        mtrans_reg_d1               <= 'd0;
        mtrans_reg_d2               <= 'd0;
    end else begin
        o_read_data                 <= i_read_data;
        o_read_data_alignment       <= {i_execute_address[1:0], 3'd0};
        o_imm32                     <= imm32_nxt;
        o_imm_shift_amount          <= imm_shift_amount_nxt;

        condition_r                 <= instruction_valid ? condition_nxt : condition_r;

        o_rm_sel                    <= o_rm_sel_nxt;
        o_rds_sel                   <= o_rds_sel_nxt;
        o_rn_sel                    <= o_rn_sel_nxt;
        o_barrel_shift_amount_sel   <= barrel_shift_amount_sel_nxt;
        o_barrel_shift_data_sel     <= barrel_shift_data_sel_nxt;
        o_barrel_shift_function     <= barrel_shift_function_nxt;
        o_alu_function              <= alu_function_nxt;
        o_use_carry_in              <= use_carry_in_nxt;
        o_multiply_function         <= multiply_function_nxt;
        address_sel_r               <= address_sel_nxt;
        pc_sel_r                    <= pc_sel_nxt;
        o_byte_enable_sel           <= byte_enable_sel_nxt;
        o_status_bits_sel           <= status_bits_sel_nxt;
        o_reg_write_sel             <= reg_write_sel_nxt;
        o_write_data_wen            <= write_data_wen_nxt;
        pc_wen_r                    <= pc_wen_nxt;
        o_reg_bank_wen              <= decode ( reg_bank_wsel_nxt );
        o_status_bits_flags_wen     <= status_bits_flags_wen_nxt;

        mtrans_r15                  <= mtrans_r15_nxt;
        control_state               <= control_state_nxt;
        mtrans_reg_d1               <= mtrans_reg;
        mtrans_reg_d2               <= mtrans_reg_d1;
    end



always @ ( posedge i_clk or posedge i_rst)
    if(i_rst) begin
      saved_current_instruction              <= 'd0;
      saved_current_instruction_address      <= 'd0;
      pre_fetch_instruction                  <= 'd0;
      pre_fetch_instruction_address          <= 'd0;
    end else begin
        // sometimes this is a pre-fetch instruction
        // e.g. two ldr instructions in a row. The second ldr will be saved
        // to the pre-fetch instruction register
        // then when its decoded, a copy is saved to the saved_current_instruction
        // register
        if      (itype == MTRANS)
            begin
            saved_current_instruction              <= mtrans_instruction_nxt;
            saved_current_instruction_address      <= instruction_address;
            end
        else if (saved_current_instruction_wen)
            begin
            saved_current_instruction              <= instruction;
            saved_current_instruction_address      <= instruction_address;
            end

        if      (pre_fetch_instruction_wen)
        begin
            pre_fetch_instruction                  <= o_read_data;
        end
    end
endmodule

//////////////////////////////////////////////////////////////////
//                                                              //
//  Execute stage of Amber 2 Core                               //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Executes instructions. Instantiates the register file, ALU  //
//  multiplication unit and barrel shifter. This stage is       //
//  relitively simple. All the complex stuff is done in the     //
//  decode stage.                                               //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////

`include "a23_config_defines.vh"

module a23_execute (

input                       i_clk,
input                       i_rst,
input       [31:0]          i_read_data,
input       [4:0]           i_read_data_alignment,  // 2 LSBs of address in [4:3], appended 
                                                    // with 3 zeros
output reg  [31:0]          o_write_data,
output wire [31:0]          o_address,
                                                    // wishbone access
output      [31:0]          o_address_nxt,          // un-registered version of address to the 
                                                    // cache rams address ports
output reg                  o_write_enable,
output reg  [3:0]           o_byte_enable,
                                                    // low = instruction fetch
output                      o_multiply_done,


// --------------------------------------------------
// Control signals from Instruction Decode stage
// --------------------------------------------------
input      [31:0]           i_imm32,
input      [4:0]            i_imm_shift_amount,
input      [3:0]            i_condition,
input                       i_use_carry_in,         // e.g. add with carry instruction

input      [3:0]            i_rm_sel,
input      [3:0]            i_rds_sel,
input      [3:0]            i_rn_sel,
input      [3:0]            i_rm_sel_nxt,
input      [3:0]            i_rds_sel_nxt,
input      [3:0]            i_rn_sel_nxt,
input      [1:0]            i_barrel_shift_amount_sel,
input      [1:0]            i_barrel_shift_data_sel,
input      [1:0]            i_barrel_shift_function,
input      [8:0]            i_alu_function,
input      [1:0]            i_multiply_function,
input      [3:0]            i_address_sel,
input      [1:0]            i_pc_sel,
input      [1:0]            i_byte_enable_sel,
input      [2:0]            i_status_bits_sel,
input      [2:0]            i_reg_write_sel,
input                       i_write_data_wen,
                                                    // in case of data abort
input                       i_pc_wen,
input      [14:0]           i_reg_bank_wen,
input                       i_status_bits_flags_wen
);

`include "a23_localparams.vh"
`include "a23_functions.vh"

// ========================================================
// Internal signals
// ========================================================
wire [31:0]         write_data_nxt;
wire [3:0]          byte_enable_nxt;
wire [31:0]         pc_plus4;
wire [31:0]         pc_minus4;
wire [31:0]         address_plus4;
wire [31:0]         alu_plus4;
wire [31:0]         rn_plus4;
wire [31:0]         alu_out;
wire [3:0]          alu_flags;
wire [31:0]         rm;
wire [31:0]         rs;
wire [31:0]         rd;
wire [31:0]         rn;
wire [31:0]         pc;
wire [31:0]         pc_nxt;
wire [31:0]         branch_pc_nxt;
wire                write_enable_nxt;
wire [7:0]          shift_amount;
wire [31:0]         barrel_shift_in;
wire [31:0]         barrel_shift_out;
wire                barrel_shift_carry;
wire                barrel_shift_carry_alu;

wire [3:0]          status_bits_flags_nxt;
reg  [3:0]          status_bits_flags;

wire                execute;           // high when condition execution is true
wire [31:0]         reg_write_nxt;
wire                pc_wen;
wire [14:0]         reg_bank_wen;
wire [3:0]          reg_bank_wsel;
wire [31:0]         multiply_out;
wire [1:0]          multiply_flags;

wire                address_update;
wire                write_data_update;
wire                byte_enable_update;
wire                write_enable_update;
wire                status_bits_flags_update;

wire [31:0]         alu_out_pc_filtered;
wire [31:0]         branch_address_nxt;

wire                carry_in;

reg  [31:0]         address_r;


// ========================================================
// Status Bits Select
// ========================================================
assign status_bits_flags_nxt     = i_status_bits_sel == 3'd0 ? alu_flags                           :
                                   i_status_bits_sel == 3'd1 ? alu_out          [31:28]            :
                                   //i_status_bits_sel == 3'd3 ? i_copro_read_data[31:28]            :
                                   //  update flags after a multiply operation
                                   i_status_bits_sel == 3'd4 ? { multiply_flags, status_bits_flags[1:0] } :
                                   // regops that do not change the overflow flag
                                   i_status_bits_sel == 3'd5 ? { alu_flags[3:1], status_bits_flags[0] } :
                                                               4'b1111 ;

// ========================================================
// Adders
// ========================================================
assign pc_plus4      = pc        + 32'd4;
assign pc_minus4     = pc        - 32'd4;
assign address_plus4 = address_r + 32'd4;
assign alu_plus4     = alu_out   + 32'd4;
assign rn_plus4      = rn        + 32'd4;


// ========================================================
// Barrel Shift Amount Select
// ========================================================
// An immediate shift value of 0 is translated into 32
assign shift_amount = i_barrel_shift_amount_sel == 2'd0 ? 8'd0                           :
                      i_barrel_shift_amount_sel == 2'd1 ? rs[7:0]                        :
                      i_barrel_shift_amount_sel == 2'd2 ? {3'd0, i_imm_shift_amount    } :
                                                          {3'd0, i_read_data_alignment } ;

// ========================================================
// Barrel Shift Data Select
// ========================================================
assign barrel_shift_in = i_barrel_shift_data_sel == 2'd0 ? i_imm32       :
                         i_barrel_shift_data_sel == 2'd1 ? i_read_data   :
                                                           rm            ;
                            
// ========================================================
// Address Select
// ========================================================

// If rd is the pc, then seperate the address bits from the status bits for
// generating the next address to fetch
assign alu_out_pc_filtered = pc_wen && i_pc_sel == 2'd1 ? pcf(alu_out) : alu_out;


assign branch_address_nxt = (!execute) ? pc_minus4 : alu_out_pc_filtered;

// if current instruction does not execute because it does not meet the condition
// then address advances to next instruction
assign o_address_nxt = (i_address_sel == 4'd0) ? pc_plus4              :
                       (i_address_sel == 4'd1) ? alu_out_pc_filtered   :
                       (i_address_sel == 4'd3) ? pc                    :
                       (i_address_sel == 4'd4) ? rn                    :
                       (i_address_sel == 4'd5) ? address_plus4         :  // MTRANS address incrementer
                       (i_address_sel == 4'd6) ? alu_plus4             :  // MTRANS decrement after
                       (i_address_sel == 4'd7) ? rn_plus4              :  // MTRANS increment before
                                                 branch_address_nxt    ;

// ========================================================
// Program Counter Select
// ========================================================

assign branch_pc_nxt = (!execute) ? pc_minus4 : alu_out;

// If current instruction does not execute because it does not meet the condition
// then PC advances to next instruction
assign pc_nxt = i_pc_sel == 2'd0 ? pc_plus4              :
                i_pc_sel == 2'd1 ? alu_out               :
                                   branch_pc_nxt         ;


// ========================================================
// Register Write Select
// ========================================================
wire [31:0] save_int_pc_m4;

assign save_int_pc_m4 = { status_bits_flags, 
                          1'b1, 
                          1'b1, 
                          pc_minus4[25:2], 
                          2'b0      };

assign reg_write_nxt = i_reg_write_sel == 3'd0 ? alu_out               :
                       // save pc to lr on an interrupt                    
                       i_reg_write_sel == 3'd1 ? save_int_pc_m4        :
                                                 multiply_out          ;  


// ========================================================
// Byte Enable Select
// ========================================================
assign byte_enable_nxt = i_byte_enable_sel == 2'd0  ? 4'b1111 :  // word write
                         i_byte_enable_sel == 2'd2  ?            // halfword write, never happen
                         ( o_address_nxt[1] == 1'd0 ? 4'b0011 : 
                                                      4'b1100  ) :
                           
                         o_address_nxt[1:0] == 2'd0 ? 4'b0001 :  // byte write
                         o_address_nxt[1:0] == 2'd1 ? 4'b0010 :
                         o_address_nxt[1:0] == 2'd2 ? 4'b0100 :
                                                      4'b1000 ;


// ========================================================
// Write Data Select
// ========================================================
assign write_data_nxt = i_byte_enable_sel == 2'd0 ? rd            :
                                                    {4{rd[ 7:0]}} ;


// ========================================================
// Conditional Execution
// ========================================================
assign execute = conditional_execute ( i_condition, status_bits_flags );
            
// allow the PC to increment to the next instruction when current
// instruction does not execute
assign pc_wen       = i_pc_wen ;//|| !execute;

// only update register bank if current instruction executes
assign reg_bank_wen = {{15{execute}} & i_reg_bank_wen};

// ========================================================
// Write Enable
// ========================================================
// This must be de-asserted when execute is fault
assign write_enable_nxt = execute && i_write_data_wen;


// ========================================================
// Register Update
// ========================================================

assign status_bits_flags_update        = execute && i_status_bits_flags_wen;

always @( posedge i_clk or posedge i_rst)
    if(i_rst) begin
      o_write_enable          <= 'd0;
      o_write_data            <= 'd0;
      address_r               <= 'd0;
      o_byte_enable           <= 'd0;
      status_bits_flags       <= 'd0;
    end else begin
      o_write_enable          <= write_enable_nxt;
      o_write_data            <= write_data_nxt; 
      address_r               <= o_address_nxt;
      o_byte_enable           <= byte_enable_nxt;
      status_bits_flags       <= status_bits_flags_update       ? status_bits_flags_nxt        : status_bits_flags;
    end

assign o_address = address_r;


// ========================================================
// Instantiate Barrel Shift
// ========================================================

assign carry_in = i_use_carry_in ? status_bits_flags[1] : 1'd0;

a23_barrel_shift u_barrel_shift  (
    .i_in             ( barrel_shift_in           ),
    .i_carry_in       ( carry_in                  ),
    .i_shift_amount   ( shift_amount              ),
    .i_function       ( i_barrel_shift_function   ),
    .o_out            ( barrel_shift_out          ),
    .o_carry_out      ( barrel_shift_carry        )
    );



// ========================================================
// Instantiate ALU
// ========================================================
assign barrel_shift_carry_alu =  i_barrel_shift_data_sel == 2'd0 ? 
                                  (i_imm_shift_amount[4:1] == 0 ? status_bits_flags[1] : i_imm32[31]) : 
                                   barrel_shift_carry;

a23_alu u_alu (
    .i_a_in                  ( rn                      ),
    .i_b_in                  ( barrel_shift_out        ),
    .i_barrel_shift_carry    ( barrel_shift_carry_alu  ),
    .i_status_bits_carry     ( status_bits_flags[1]    ),
    .i_function              ( i_alu_function          ),
    .o_out                   ( alu_out                 ),
    .o_flags                 ( alu_flags               )
    );

// ========================================================
// Instantiate Booth 64-bit Multiplier-Accumulator
// ========================================================
a23_multiply u_multiply (
    .i_clk          ( i_clk                 ),
    .i_rst          ( i_rst                 ),
    .i_a_in         ( rs                    ),
    .i_b_in         ( rm                    ),
    .i_function     ( i_multiply_function   ),
    .i_execute      ( execute               ),
    .o_out          ( multiply_out          ),
    .o_flags        ( multiply_flags        ),  // [1] = N, [0] = Z
    .o_done         ( o_multiply_done       )
    );


// ========================================================
// Instantiate Register Bank
// ========================================================
a23_register_bank u_register_bank(
    .i_clk                   ( i_clk                     ),
    .i_rst                   ( i_rst                     ),
    .i_rm_sel                ( i_rm_sel                  ),
    .i_rds_sel               ( i_rds_sel                 ),
    .i_rn_sel                ( i_rn_sel                  ),
    .i_pc_wen                ( pc_wen                    ),
    .i_reg_bank_wen          ( reg_bank_wen              ),
    .i_pc                    ( pc_nxt[25:2]              ),
    .i_reg                   ( reg_write_nxt             ),
    .i_status_bits_flags     ( status_bits_flags         ),
    .o_rm                    ( rm                        ),
    .o_rs                    ( rs                        ),
    .o_rd                    ( rd                        ),
    .o_rn                    ( rn                        ),
    .o_pc                    ( pc                        )
    );

endmodule

//////////////////////////////////////////////////////////////////
//                                                              //
//  Fetch - Instantiates the fetch stage sub-modules of         //
//  the Amber 2 Core                                            //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Instantiates the Cache and Wishbone I/F                     //
//  Also contains a little bit of logic to decode memory        //
//  accesses to decide if they are cached or not                //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////


module a23_fetch
(
input                       i_clk,
input                       i_rst,

input       [31:0]          i_address,
input       [31:0]          i_address_nxt,      // un-registered version of address to the cache rams
input       [31:0]          i_write_data,
input                       i_write_enable,
output       [31:0]         o_read_data,
input       [3:0]           i_byte_enable,
input                       i_cache_enable,     // cache enable
input                       i_cache_flush,      // cache flush
input       [31:0]          i_cacheable_area,   // each bit corresponds to 2MB address space
output   [31:0]             o_m_address, //memory
output   [31:0]             o_m_write,
output                      o_m_write_en,
output   [3:0]              o_m_byte_enable,
input    [31:0]             i_m_read
);

assign o_m_address     = i_address;
assign o_m_write       = i_write_data;
assign o_m_write_en    = i_write_enable;
assign o_m_byte_enable = i_byte_enable;
assign o_read_data     = i_m_read;

endmodule
module a23_gc_main
#(
  // mem size in words (32bit)
  parameter CODE_MEM_SIZE  = 64  ,   //Code:    0x00000000
  parameter G_MEM_SIZE     = 64  ,   //AdrGarbler: 0x01000000
  parameter E_MEM_SIZE     = 64  ,   //AdrEvaluator:   0x02000000
  parameter OUT_MEM_SIZE   = 64  ,   //AdrOut:   0x03000000
  parameter STACK_MEM_SIZE = 64      //AdrStack:  0x04000000
)
(
  input                           clk,
  input                           rst,
  input  [CODE_MEM_SIZE*32-1:0]   p_init,
  input  [G_MEM_SIZE   *32-1:0]   g_init,
  input  [E_MEM_SIZE   *32-1:0]   e_init,
  output [OUT_MEM_SIZE *32-1:0]   o,
  output                          terminate
);

wire   [31:0]             m_address;
wire   [31:0]             m_write;
wire                      m_write_en;
wire   [3:0]              m_byte_enable;
wire   [31:0]             m_read;

a23_core u_a23_core
(
  .i_clk             (clk               ),
  .i_rst             (rst               ),
  .o_m_address       (m_address         ),
  .o_m_write         (m_write           ),
  .o_m_write_en      (m_write_en        ),
  .o_m_byte_enable   (m_byte_enable     ),
  .i_m_read          (m_read            ),
  .terminate         (terminate         )
);

a23_mem
#(
  .CODE_MEM_SIZE     (CODE_MEM_SIZE),
  .G_MEM_SIZE        (G_MEM_SIZE),
  .E_MEM_SIZE        (E_MEM_SIZE),
  .OUT_MEM_SIZE      (OUT_MEM_SIZE),
  .STACK_MEM_SIZE    (STACK_MEM_SIZE)
)
u_a23_mem
(
  .i_clk              (clk              ),
  .i_rst              (rst              ),

  .p_init             (p_init           ),
  .g_init             (g_init           ),
  .e_init             (e_init           ),
  .o                  (o                ),

  .i_m_address        (m_address        ),
  .i_m_write          (m_write          ),
  .i_m_write_en       (m_write_en       ),
  .i_m_byte_enable    (m_byte_enable    ),
  .o_m_read           (m_read           )
);




endmodule
module a23_mem
#
(
  // mem size in words (32bit)
  parameter CODE_MEM_SIZE  = 64  ,   //Code:    0x00000000
  parameter G_MEM_SIZE     = 64  ,   //AdrGarbler: 0x01000000
  parameter E_MEM_SIZE     = 64  ,   //AdrEvaluator:   0x02000000
  parameter OUT_MEM_SIZE   = 64  ,   //AdrOut:   0x03000000
  parameter STACK_MEM_SIZE = 64      //AdrStack:  0x04000000
)
(
input                           i_clk,
input                           i_rst,

input  [CODE_MEM_SIZE*32-1:0]   p_init,
input  [G_MEM_SIZE   *32-1:0]   g_init,
input  [E_MEM_SIZE   *32-1:0]   e_init,
output [OUT_MEM_SIZE *32-1:0]   o,

input   [31:0]                  i_m_address,
input   [31:0]                  i_m_write,
input                           i_m_write_en,
input   [3:0]                   i_m_byte_enable,
output  [31:0]                  o_m_read
);

reg [7:0]  p_mem     [4*CODE_MEM_SIZE-1:0];
reg [7:0]  g_mem     [4*G_MEM_SIZE-1:0];
reg [7:0]  e_mem     [4*E_MEM_SIZE-1:0];
reg [7:0]  out_mem   [4*OUT_MEM_SIZE-1:0];
reg [7:0]  stack_mem [4*STACK_MEM_SIZE-1:0];

genvar gi;


// instruction memory
wire [7:0]  p_init_byte [4*CODE_MEM_SIZE-1:0];
wire [7:0]  g_init_byte [4*G_MEM_SIZE-1:0];
wire [7:0]  e_init_byte [4*E_MEM_SIZE-1:0];
generate
  for (gi = 0; gi < 4*CODE_MEM_SIZE; gi = gi + 1) begin:code_gen
    assign p_init_byte[gi] = p_init[8*(gi+1)-1:8*gi];
  end
  for (gi = 0; gi < 4*G_MEM_SIZE; gi = gi + 1)begin: g_gen
    assign g_init_byte[gi] = g_init[8*(gi+1)-1:8*gi];
  end
  for (gi = 0; gi < 4*E_MEM_SIZE; gi = gi + 1)begin: e_gen
    assign e_init_byte[gi] = e_init[8*(gi+1)-1:8*gi];
  end
  for (gi = 0; gi < 4*OUT_MEM_SIZE; gi = gi + 1) begin:out_gen
    assign o[8*(gi+1)-1:8*gi] = out_mem[gi];
  end
endgenerate


wire [23:0] trunc_m_address;
assign trunc_m_address = {i_m_address[23:2], 2'b0};

assign  o_m_read =  (i_m_address[31:24] == 8'h00) ? {p_mem[trunc_m_address+3], p_mem[trunc_m_address+2], p_mem[trunc_m_address+1], p_mem[trunc_m_address]}  ://Code:  0x00000000
                    (i_m_address[31:24] == 8'h01) ? {g_mem[trunc_m_address+3], g_mem[trunc_m_address+2], g_mem[trunc_m_address+1], g_mem[trunc_m_address]}  ://AdrGarbler: 0x01000000
                    (i_m_address[31:24] == 8'h02) ? {e_mem[trunc_m_address+3], e_mem[trunc_m_address+2], e_mem[trunc_m_address+1], e_mem[trunc_m_address]}  ://AdrEvaluator:   0x02000000
                    (i_m_address[31:24] == 8'h03) ? {out_mem[trunc_m_address+3], out_mem[trunc_m_address+2], out_mem[trunc_m_address+1], out_mem[trunc_m_address]}  ://AdrOut:   0x03000000
                    (i_m_address[31:24] == 8'h04) ? {stack_mem[trunc_m_address+3], stack_mem[trunc_m_address+2], stack_mem[trunc_m_address+1], stack_mem[trunc_m_address]}  ://AdrStack:  0x04000000
                                                     32'b0;

integer i;
always @(posedge i_clk or posedge i_rst) begin
  if (i_rst) begin
    for(i=0;i<4*CODE_MEM_SIZE;i=i+1) begin
      p_mem[i] <= p_init_byte[i];
    end
    for(i=0;i<4*G_MEM_SIZE;i=i+1) begin
      g_mem[i] <= g_init_byte[i];
    end
    for(i=0;i<4*E_MEM_SIZE;i=i+1) begin
      e_mem[i] <= e_init_byte[i];
    end
    for(i=0;i<4*OUT_MEM_SIZE;i=i+1) begin
      out_mem[i] <= 8'b0;
    end
    for(i=0;i<4*STACK_MEM_SIZE;i=i+1) begin
      stack_mem[i] <= 8'b0;
    end
  end else begin
    for(i=0;i<4*CODE_MEM_SIZE;i=i+1) begin
      p_mem[i] <= p_mem[i];
    end
    for(i=0;i<4*G_MEM_SIZE;i=i+1) begin
      g_mem[i] <= g_mem[i];
    end
    for(i=0;i<4*E_MEM_SIZE;i=i+1) begin
      e_mem[i] <= e_mem[i];
    end
    for(i=0;i<4*OUT_MEM_SIZE;i=i+1) begin
      out_mem[i] <= out_mem[i];
    end
    for(i=0;i<4*STACK_MEM_SIZE;i=i+1) begin
      stack_mem[i] <= stack_mem[i];
    end
    if (i_m_write_en) begin // AdrGarbler and AdrEvaluator are const
      if(i_m_address[31:24] == 8'h00) begin //Code: 0x00000000
        case(i_m_byte_enable)
        4'b1111: begin
          p_mem[trunc_m_address+3] <= i_m_write[31:24];
          p_mem[trunc_m_address+2] <= i_m_write[23:16];
          p_mem[trunc_m_address+1] <= i_m_write[15:8];
          p_mem[trunc_m_address+0] <= i_m_write[7:0];
        end
        4'b0001: begin
          p_mem[trunc_m_address+0] <= i_m_write[7:0];
        end
        4'b0010: begin
          p_mem[trunc_m_address+1] <= i_m_write[7:0];
        end
        4'b0100: begin
          p_mem[trunc_m_address+2] <= i_m_write[7:0];
        end
        4'b1000: begin
          p_mem[trunc_m_address+3] <= i_m_write[7:0];
        end
        endcase
      end else if(i_m_address[31:24] == 8'h03) begin //AdrOut: 0x03000000
        case(i_m_byte_enable)
        4'b1111: begin
          out_mem[trunc_m_address+3] <= i_m_write[31:24];
          out_mem[trunc_m_address+2] <= i_m_write[23:16];
          out_mem[trunc_m_address+1] <= i_m_write[15:8];
          out_mem[trunc_m_address+0] <= i_m_write[7:0];
        end
        4'b0001: begin
          out_mem[trunc_m_address+0] <= i_m_write[7:0];
        end
        4'b0010: begin
          out_mem[trunc_m_address+1] <= i_m_write[7:0];
        end
        4'b0100: begin
          out_mem[trunc_m_address+2] <= i_m_write[7:0];
        end
        4'b1000: begin
          out_mem[trunc_m_address+3] <= i_m_write[7:0];
        end
        endcase
      end else if (i_m_address[31:24] == 8'h04) begin //AdrStack: 0x04000000
        case(i_m_byte_enable)
        4'b1111: begin
          stack_mem[trunc_m_address+3] <= i_m_write[31:24];
          stack_mem[trunc_m_address+2] <= i_m_write[23:16];
          stack_mem[trunc_m_address+1] <= i_m_write[15:8];
          stack_mem[trunc_m_address+0] <= i_m_write[7:0];
        end
        4'b0001: begin
          stack_mem[trunc_m_address+0] <= i_m_write[7:0];
        end
        4'b0010: begin
          stack_mem[trunc_m_address+1] <= i_m_write[7:0];
        end
        4'b0100: begin
          stack_mem[trunc_m_address+2] <= i_m_write[7:0];
        end
        4'b1000: begin
          stack_mem[trunc_m_address+3] <= i_m_write[7:0];
        end
        endcase
      end
    end
  end
end


endmodule


//////////////////////////////////////////////////////////////////
//                                                              //
//  Multiplication Module for Amber 2 Core                      //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  64-bit Booth signed or unsigned multiply and                //
//  multiply-accumulate supported. It takes about 38 clock      //
//  cycles to complete an operation.                            //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////



// bit 0 go, bit 1 accumulate
// Command:
//  4'b01 :  MUL   - 32 bit multiplication
//  4'b11 :  MLA   - 32 bit multiply and accumulate
//
//  34-bit Booth adder
//  The adder needs to be 34 bit to deal with signed and unsigned 32-bit
//  multiplication inputs. This adds 1 extra bit. Then to deal with the
//  case of two max negative numbers another bit is required.
//

module a23_multiply (
input                       i_clk,
input                       i_rst,

input       [31:0]          i_a_in,         // Rds
input       [31:0]          i_b_in,         // Rm
input       [1:0]           i_function,
input                       i_execute,

output      [31:0]          o_out,
output      [1:0]           o_flags,        // [1] = N, [0] = Z
output                      o_done    // goes high 2 cycles before completion                                          
);


wire        enable;
wire        accumulate;

reg  [31:0] product;
reg  [3:0]  count;

assign enable         = i_function[0];
assign accumulate     = i_function[1];

assign o_out   = product;

assign o_flags = {o_out[31], o_out == 32'd0 }; 
assign o_done  = 1'b1;


always @(posedge i_clk or posedge i_rst) begin
  if (i_rst) begin
    product <= 32'b0;
    count <= 4'b0;
  end else if(enable) begin
    count <= count + 1;
    if (i_execute && count == 0) begin
      product <= i_a_in*i_b_in;
    end else if (i_execute && accumulate && count == 3) begin
      product <= product + i_a_in;
    end
  end else begin
    product <= 32'b0;
    count <= 4'b0;
  end
end

// wire [33:0] multiplier;
// wire [33:0] multiplier_bar;
// wire [33:0] sum;
// wire [33:0] sum34_b;

// reg  [5:0]  count;
// reg  [5:0]  count_nxt;
// reg  [67:0] product;
// reg  [67:0] product_nxt;
// reg  [1:0]  flags_nxt;
// wire [32:0] sum_acc1;           // the MSB is the carry out for the upper 32 bit addition
// assign multiplier     =  { 2'd0, i_a_in} ;
// assign multiplier_bar = ~{ 2'd0, i_a_in} + 34'd1 ;

// assign sum34_b        =  product[1:0] == 2'b01 ? multiplier     :
//                          product[1:0] == 2'b10 ? multiplier_bar :
//                                                  34'd0          ;


// // -----------------------------------
// // 34-bit adder - booth multiplication
// // -----------------------------------
// assign sum =  product[67:34] + sum34_b;
 
// // ------------------------------------
// // 33-bit adder - accumulate operations
// // ------------------------------------
// assign sum_acc1 = {1'd0, product[32:1]} + {1'd0, i_a_in};


// always @*
// begin
//   // Defaults
//   count_nxt           = count;
//   product_nxt         = product;
  
//   // update Negative and Zero flags
//   // Use registered value of product so this adds an extra cycle
//   // but this avoids having the 64-bit zero comparator on the
//   // main adder path
//   flags_nxt   = { product[32], product[32:1] == 32'd0 }; 
    

//   if ( count == 6'd0 )
//     product_nxt = {33'd0, 1'd0, i_b_in, 1'd0 } ;
//   else if ( count <= 6'd33 )
//     product_nxt = { sum[33], sum, product[33:1]} ;
//   else if ( count == 6'd34 && accumulate )
//   begin
//     // Note that bit 0 is not part of the product. It is used during the booth
//     // multiplication algorithm
//     product_nxt         = { product[64:33], sum_acc1[31:0], 1'd0}; // Accumulate
//   end
        
//   // Multiplication state counter
//   if (count == 6'd0)  // start
//     count_nxt   = enable ? 6'd1 : 6'd0;
//   else if ((count == 6'd34 && !accumulate) ||  // MUL
//            (count == 6'd35 &&  accumulate)  )  // MLA
//     count_nxt   = 6'd0;
//   else
//     count_nxt   = count + 1'd1;

// end


//   always @ ( posedge i_clk or posedge i_rst)
//   if (i_rst) begin
//     product         <= 'd0;
//     count           <= 'd0;
//     o_done          <= 'd0;
//   end else if (enable)
//   begin 
//     if(i_execute) begin
//           product         <= product_nxt;
//     end
//     count           <= count_nxt;
//     o_done          <= count == 6'd31;
//   end

// Outputs
// assign o_out   = product[32:1]; 
// assign o_flags = flags_nxt;
                     
endmodule

//////////////////////////////////////////////////////////////////
//                                                              //
//  Register Bank for Amber Core                                //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Contains 37 32-bit registers, 16 of which are visible       //
//  ina any one operating mode. Registers use real flipflops,   //
//  rather than SRAM. This makes sense for an FPGA              //
//  implementation, where flipflops are plentiful.              //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////

module a23_register_bank (

input                       i_clk,
input                       i_rst,
input       [3:0]           i_rm_sel,
input       [3:0]           i_rds_sel,
input       [3:0]           i_rn_sel,

input                       i_pc_wen,
input       [14:0]          i_reg_bank_wen,

input       [23:0]          i_pc,                   // program counter [25:2]
input       [31:0]          i_reg,

input       [3:0]           i_status_bits_flags,

output      [31:0]          o_rm,
output reg  [31:0]          o_rs,
output reg  [31:0]          o_rd,
output      [31:0]          o_rn,
output      [31:0]          o_pc

);

`include "a23_localparams.vh"
`include "a23_functions.vh"


reg  [31:0] r0  ;
reg  [31:0] r1  ;
reg  [31:0] r2  ;
reg  [31:0] r3  ;
reg  [31:0] r4  ;
reg  [31:0] r5  ;
reg  [31:0] r6  ;
reg  [31:0] r7  ;
reg  [31:0] r8  ;
reg  [31:0] r9  ;
reg  [31:0] r10 ;
reg  [31:0] r11 ;
reg  [31:0] r12 ;
reg  [31:0] r13 ;
reg  [31:0] r14 ;
reg  [23:0] r15 ;

wire  [31:0] r0_out;
wire  [31:0] r1_out;
wire  [31:0] r2_out;
wire  [31:0] r3_out;
wire  [31:0] r4_out;
wire  [31:0] r5_out;
wire  [31:0] r6_out;
wire  [31:0] r7_out;
wire  [31:0] r8_out;
wire  [31:0] r9_out;
wire  [31:0] r10_out;
wire  [31:0] r11_out;
wire  [31:0] r12_out;
wire  [31:0] r13_out;
wire  [31:0] r14_out;
wire  [31:0] r15_out_rm;
wire  [31:0] r15_out_rm_nxt;
wire  [31:0] r15_out_rn;

wire  [31:0] r8_rds;
wire  [31:0] r9_rds;
wire  [31:0] r10_rds;
wire  [31:0] r11_rds;
wire  [31:0] r12_rds;
wire  [31:0] r13_rds;
wire  [31:0] r14_rds;


// ========================================================
// Register Update
// ========================================================
always @ ( posedge i_clk or posedge i_rst)
  if (i_rst) begin
      r0       <= 'd0;
      r1       <= 'd0;
      r2       <= 'd0;
      r3       <= 'd0;
      r4       <= 'd0;
      r5       <= 'd0;
      r6       <= 'd0;
      r7       <= 'd0;
      r8       <= 'd0;
      r9       <= 'd0;
      r10      <= 'd0;
      r11      <= 'd0;
      r12      <= 'd0;
      r13      <= 'd0;
      r14      <= 'd0;
      r15      <= 24'h0;
  end else begin
      r0       <=  i_reg_bank_wen[0 ]              ? i_reg : r0;  
      r1       <=  i_reg_bank_wen[1 ]              ? i_reg : r1;  
      r2       <=  i_reg_bank_wen[2 ]              ? i_reg : r2;  
      r3       <=  i_reg_bank_wen[3 ]              ? i_reg : r3;  
      r4       <=  i_reg_bank_wen[4 ]              ? i_reg : r4;  
      r5       <=  i_reg_bank_wen[5 ]              ? i_reg : r5;  
      r6       <=  i_reg_bank_wen[6 ]              ? i_reg : r6;  
      r7       <=  i_reg_bank_wen[7 ]              ? i_reg : r7;  
      r8       <=  i_reg_bank_wen[8 ]              ? i_reg : r8;  
      r9       <=  i_reg_bank_wen[9 ]              ? i_reg : r9;  
      r10      <=  i_reg_bank_wen[10]              ? i_reg : r10; 
      r11      <=  i_reg_bank_wen[11]              ? i_reg : r11; 
      r12      <=  i_reg_bank_wen[12]              ? i_reg : r12; 
      r13      <=  i_reg_bank_wen[13]              ? i_reg : r13;
      r14      <=  i_reg_bank_wen[14]              ? i_reg : r14;
      r15      <=  i_pc_wen                        ?  i_pc : r15;
  end
    
    
// ========================================================
// Register Read based on Mode
// ========================================================
assign r0_out = r0;
assign r1_out = r1;
assign r2_out = r2;
assign r3_out = r3;
assign r4_out = r4;
assign r5_out = r5;
assign r6_out = r6;
assign r7_out = r7;
assign r8_out  = r8;
assign r9_out  = r9;
assign r10_out = r10;
assign r11_out = r11;
assign r12_out = r12;
assign r13_out = r13; 
assign r14_out = r14;


assign r15_out_rm     = { i_status_bits_flags, 
                          1'b1, 
                          1'b1, 
                          r15, 
                          2'b0};

assign r15_out_rm_nxt = { i_status_bits_flags, 
                          1'b1, 
                          1'b1, 
                          i_pc, 
                          2'b0};
                      
assign r15_out_rn     = {6'd0, r15, 2'd0};


// rds outputs
assign r8_rds  = r8;
assign r9_rds  = r9;
assign r10_rds = r10;
assign r11_rds = r11;
assign r12_rds = r12;
assign r13_rds = r13;
assign r14_rds = r14;

// ========================================================
// Program Counter out
// ========================================================
assign o_pc = r15_out_rn;

// ========================================================
// Rm Selector
// ========================================================
assign o_rm = i_rm_sel == 4'd0  ? r0_out  :
              i_rm_sel == 4'd1  ? r1_out  : 
              i_rm_sel == 4'd2  ? r2_out  : 
              i_rm_sel == 4'd3  ? r3_out  : 
              i_rm_sel == 4'd4  ? r4_out  : 
              i_rm_sel == 4'd5  ? r5_out  : 
              i_rm_sel == 4'd6  ? r6_out  : 
              i_rm_sel == 4'd7  ? r7_out  : 
              i_rm_sel == 4'd8  ? r8_out  : 
              i_rm_sel == 4'd9  ? r9_out  : 
              i_rm_sel == 4'd10 ? r10_out : 
              i_rm_sel == 4'd11 ? r11_out : 
              i_rm_sel == 4'd12 ? r12_out : 
              i_rm_sel == 4'd13 ? r13_out : 
              i_rm_sel == 4'd14 ? r14_out : 
                                  r15_out_rm ; 




// ========================================================
// Rds Selector
// ========================================================
always @*
    case (i_rds_sel)
       4'd0  :  o_rs = r0_out  ;
       4'd1  :  o_rs = r1_out  ; 
       4'd2  :  o_rs = r2_out  ; 
       4'd3  :  o_rs = r3_out  ; 
       4'd4  :  o_rs = r4_out  ; 
       4'd5  :  o_rs = r5_out  ; 
       4'd6  :  o_rs = r6_out  ; 
       4'd7  :  o_rs = r7_out  ; 
       4'd8  :  o_rs = r8_rds  ; 
       4'd9  :  o_rs = r9_rds  ; 
       4'd10 :  o_rs = r10_rds ; 
       4'd11 :  o_rs = r11_rds ; 
       4'd12 :  o_rs = r12_rds ; 
       4'd13 :  o_rs = r13_rds ; 
       4'd14 :  o_rs = r14_rds ; 
       default: o_rs = r15_out_rn ; 
    endcase

                                    

// ========================================================
// Rd Selector
// ========================================================
always @*
    case (i_rds_sel)
       4'd0  :  o_rd = r0_out  ;
       4'd1  :  o_rd = r1_out  ; 
       4'd2  :  o_rd = r2_out  ; 
       4'd3  :  o_rd = r3_out  ; 
       4'd4  :  o_rd = r4_out  ; 
       4'd5  :  o_rd = r5_out  ; 
       4'd6  :  o_rd = r6_out  ; 
       4'd7  :  o_rd = r7_out  ; 
       4'd8  :  o_rd = r8_rds  ; 
       4'd9  :  o_rd = r9_rds  ; 
       4'd10 :  o_rd = r10_rds ; 
       4'd11 :  o_rd = r11_rds ; 
       4'd12 :  o_rd = r12_rds ; 
       4'd13 :  o_rd = r13_rds ; 
       4'd14 :  o_rd = r14_rds ; 
       default: o_rd = r15_out_rm_nxt ; 
    endcase

                                    
// ========================================================
// Rn Selector
// ========================================================
assign o_rn = i_rn_sel == 4'd0  ? r0_out  :
              i_rn_sel == 4'd1  ? r1_out  : 
              i_rn_sel == 4'd2  ? r2_out  : 
              i_rn_sel == 4'd3  ? r3_out  : 
              i_rn_sel == 4'd4  ? r4_out  : 
              i_rn_sel == 4'd5  ? r5_out  : 
              i_rn_sel == 4'd6  ? r6_out  : 
              i_rn_sel == 4'd7  ? r7_out  : 
              i_rn_sel == 4'd8  ? r8_out  : 
              i_rn_sel == 4'd9  ? r9_out  : 
              i_rn_sel == 4'd10 ? r10_out : 
              i_rn_sel == 4'd11 ? r11_out : 
              i_rn_sel == 4'd12 ? r12_out : 
              i_rn_sel == 4'd13 ? r13_out : 
              i_rn_sel == 4'd14 ? r14_out : 
                                  r15_out_rn ; 


endmodule







//////////////////////////////////////////////////////////////////
//                                                              //
//  Amber 2 Core top-Level module                               //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Instantiates the core consisting of fetch, instruction      //
//  decode, execute, and co-processor.                          //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//  Modification:                                               //
//      - Mohammad Hashemi, mhashemi@wpi.edu                    //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////


module a23_core
(
input                       i_clk,
input                       i_rst,

output   [31:0]             o_m_address, //data memory
output   [31:0]             o_m_write,
output                      o_m_write_en,
output   [3:0]              o_m_byte_enable,
input    [31:0]             i_m_read,        

output                      terminate
);

wire      [31:0]          execute_address;
wire      [31:0]          execute_address_nxt;  // un-registered version of execute_address to the cache rams
wire      [31:0]          write_data;
wire                      write_enable;
wire      [31:0]          read_data;
wire      [3:0]           byte_enable;
wire                      status_bits_flags_wen;
                 
wire     [31:0]           imm32;                   
wire     [4:0]            imm_shift_amount;   
wire     [3:0]            condition;               
wire     [31:0]           read_data_s2;            
wire     [4:0]            read_data_alignment;     

wire     [3:0]            rm_sel;                  
wire     [3:0]            rds_sel;                 
wire     [3:0]            rn_sel;                  
wire     [3:0]            rm_sel_nxt;
wire     [3:0]            rds_sel_nxt;
wire     [3:0]            rn_sel_nxt;
wire     [1:0]            barrel_shift_amount_sel; 
wire     [1:0]            barrel_shift_data_sel;   
wire     [1:0]            barrel_shift_function; 
wire                      use_carry_in;  
wire     [8:0]            alu_function;            
wire     [1:0]            multiply_function;
wire     [3:0]            address_sel;             
wire     [1:0]            pc_sel;                  
wire     [1:0]            byte_enable_sel;         
wire     [2:0]            status_bits_sel;                
wire     [2:0]            reg_write_sel;
wire                      write_data_wen;
wire                      pc_wen;                  
wire     [14:0]           reg_bank_wen;

wire                      multiply_done;


assign terminate = ({execute_address[31:2], 2'd0} == 32'h00000018) && (execute_address_nxt == 32'h0000001c);

a23_fetch u_fetch (
    .i_clk                              ( i_clk                             ),
    .i_rst                              ( i_rst                             ),

    .i_address                          ( {execute_address[31:2], 2'd0}     ),
    .i_address_nxt                      ( execute_address_nxt               ),
    .i_write_data                       ( write_data                        ),
    .i_write_enable                     ( write_enable                      ),
    .o_read_data                        ( read_data                         ),
    .i_byte_enable                      ( byte_enable                       ),     
    .i_cache_enable                     ( 1'b0                              ),     
    .i_cache_flush                      ( 1'b0                              ), 
    .i_cacheable_area                   ( 32'b0                             ),
    
    .o_m_address                        ( o_m_address                       ),
    .o_m_write                          ( o_m_write                         ),
    .o_m_write_en                       ( o_m_write_en                      ),
    .o_m_byte_enable                    ( o_m_byte_enable                   ),
    .i_m_read                           ( i_m_read                          )
);


a23_decode u_decode (
    .i_clk                              ( i_clk                             ),
    .i_rst                              ( i_rst                             ),
    
    // Instruction fetch or data read signals
    .i_read_data                        ( read_data                         ),                                          
    .i_execute_address                  ( execute_address                   ),                                          
    
    .o_read_data                        ( read_data_s2                      ),                                          
    .o_read_data_alignment              ( read_data_alignment               ),                                          
    .i_multiply_done                    ( multiply_done                     ),  
    .o_imm32                            ( imm32                             ),
    .o_imm_shift_amount                 ( imm_shift_amount                  ),
    .o_condition                        ( condition                         ),
    .o_rm_sel                           ( rm_sel                            ),
    .o_rds_sel                          ( rds_sel                           ),
    .o_rn_sel                           ( rn_sel                            ),
    .o_rm_sel_nxt                       ( rm_sel_nxt                        ),
    .o_rds_sel_nxt                      ( rds_sel_nxt                       ),
    .o_rn_sel_nxt                       ( rn_sel_nxt                        ),
    .o_barrel_shift_amount_sel          ( barrel_shift_amount_sel           ),
    .o_barrel_shift_data_sel            ( barrel_shift_data_sel             ),
    .o_barrel_shift_function            ( barrel_shift_function             ),
    .o_use_carry_in                     ( use_carry_in                      ),
    .o_alu_function                     ( alu_function                      ),
    .o_multiply_function                ( multiply_function                 ),
    .o_address_sel                      ( address_sel                       ),
    .o_pc_sel                           ( pc_sel                            ),
    .o_byte_enable_sel                  ( byte_enable_sel                   ),
    .o_status_bits_sel                  ( status_bits_sel                   ),
    .o_reg_write_sel                    ( reg_write_sel                     ),
    .o_write_data_wen                   ( write_data_wen                    ),
    .o_pc_wen                           ( pc_wen                            ),
    .o_reg_bank_wen                     ( reg_bank_wen                      ),
    .o_status_bits_flags_wen            ( status_bits_flags_wen             )
);


a23_execute u_execute (
    .i_clk                              ( i_clk                             ),
    .i_rst                              ( i_rst                             ),

    .i_read_data                        ( read_data_s2                      ),
    .i_read_data_alignment              ( read_data_alignment               ), 
    
    .o_write_data                       ( write_data                        ),
    .o_address                          ( execute_address                   ),
    .o_address_nxt                      ( execute_address_nxt               ),

    .o_byte_enable                      ( byte_enable                       ),
    .o_write_enable                     ( write_enable                      ),
    .o_multiply_done                    ( multiply_done                     ),   
    .i_imm32                            ( imm32                             ),   
    .i_imm_shift_amount                 ( imm_shift_amount                  ),

    .i_condition                        ( condition                         ),
  
    .i_rm_sel                           ( rm_sel                            ),   
    .i_rds_sel                          ( rds_sel                           ),   
    .i_rn_sel                           ( rn_sel                            ),   
    .i_rm_sel_nxt                       ( rm_sel_nxt                        ),
    .i_rds_sel_nxt                      ( rds_sel_nxt                       ),
    .i_rn_sel_nxt                       ( rn_sel_nxt                        ),
    .i_barrel_shift_amount_sel          ( barrel_shift_amount_sel           ),   
    .i_barrel_shift_data_sel            ( barrel_shift_data_sel             ),   
    .i_barrel_shift_function            ( barrel_shift_function             ),   
    .i_use_carry_in                     ( use_carry_in                      ),
    .i_alu_function                     ( alu_function                      ),   
    .i_multiply_function                ( multiply_function                 ),   
    .i_address_sel                      ( address_sel                       ),   
    .i_pc_sel                           ( pc_sel                            ),   
    .i_byte_enable_sel                  ( byte_enable_sel                   ),   
    .i_status_bits_sel                  ( status_bits_sel                   ),   
    .i_reg_write_sel                    ( reg_write_sel                     ),

    .i_write_data_wen                   ( write_data_wen                    ),      
    .i_pc_wen                           ( pc_wen                            ),   
    .i_reg_bank_wen                     ( reg_bank_wen                      ),
    .i_status_bits_flags_wen            ( status_bits_flags_wen             )
);


endmodule

//////////////////////////////////////////////////////////////////
//                                                              //
//  Arithmetic Logic Unit (ALU) for Amber 2 Core                //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Supported functions: 32-bit add and subtract, AND, OR,      //
//  XOR, NOT, Zero extent 8-bit numbers                         //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////


module a23_alu (
input       [31:0]          i_a_in,
input       [31:0]          i_b_in,
input                       i_barrel_shift_carry,
input                       i_status_bits_carry,
input       [8:0]           i_function,


output      [31:0]          o_out,
output      [3:0]           o_flags       // negative, zero, carry, overflow
);

wire     [31:0]         a, b, b_not;
wire     [31:0]         and_out, or_out, xor_out;
wire     [31:0]         sign_ex8_out, sign_ex_16_out;
wire     [31:0]         zero_ex8_out, zero_ex_16_out;
wire     [32:0]         fadder_out;
wire                    swap_sel;
wire                    not_sel;
wire     [1:0]          cin_sel;
wire                    cout_sel;
wire     [3:0]          out_sel;
wire                    carry_in;
wire                    carry_out;
wire                    overflow_out;
wire                    fadder_carry_out;

assign  { swap_sel, not_sel, cin_sel, cout_sel, out_sel } = i_function;


// ========================================================
// A Select
// ========================================================
assign a     = (swap_sel ) ? i_b_in : i_a_in ;

// ========================================================
// B Select
// ========================================================
assign b     = (swap_sel ) ? i_a_in : i_b_in ;
                             
// ========================================================
// Not Select
// ========================================================
assign b_not     = (not_sel ) ? ~b : b ;
                             
// ========================================================
// Cin Select
// ========================================================
assign carry_in  = (cin_sel==2'd0 ) ? 1'd0                   :
                   (cin_sel==2'd1 ) ? 1'd1                   :
                                      i_status_bits_carry    ;  // add with carry

// ========================================================
// Cout Select
// ========================================================
assign carry_out = (cout_sel==1'd0 ) ? fadder_carry_out     :
                                       i_barrel_shift_carry ;

// For non-addition/subtractions that incorporate a shift 
// operation, C is set to the last bit
// shifted out of the value by the shifter.


// ========================================================
// Overflow out
// ========================================================
// Only assert the overflow flag when using the adder
assign  overflow_out    = out_sel == 4'd1 &&
                            // overflow if adding two positive numbers and get a negative number
                          ( (!a[31] && !b_not[31] && fadder_out[31]) ||
                            // or adding two negative numbers and get a positive number
                            (a[31] && b_not[31] && !fadder_out[31])     );


// ========================================================
// ALU Operations
// ========================================================

assign fadder_out       = { 1'd0,a} + {1'd0,b_not} + {32'd0,carry_in};
assign fadder_carry_out = fadder_out[32];
assign and_out          = a & b_not;
assign or_out           = a | b_not;
assign xor_out          = a ^ b_not;
assign zero_ex8_out     = {24'd0,  b_not[7:0]};
assign zero_ex_16_out   = {16'd0,  b_not[15:0]};
assign sign_ex8_out     = {{24{b_not[7]}},  b_not[7:0]};
assign sign_ex_16_out   = {{16{b_not[15]}}, b_not[15:0]};
                          
// ========================================================
// Out Select
// ========================================================
assign o_out = out_sel == 4'd0 ? b_not            : 
               out_sel == 4'd1 ? fadder_out[31:0] : 
               out_sel == 4'd2 ? zero_ex_16_out   :
               out_sel == 4'd3 ? zero_ex8_out     :
               out_sel == 4'd4 ? sign_ex_16_out   :
               out_sel == 4'd5 ? sign_ex8_out     :
               out_sel == 4'd6 ? xor_out          :
               out_sel == 4'd7 ? or_out           :
                                 and_out          ;

wire only_carry;
// activate for adc
assign only_carry = (out_sel == 4'd1)  && (cin_sel == 2'd2);

assign o_flags = only_carry ?
                 {1'b0, 1'b0, carry_out, 1'b0}:
                 {
                 o_out[31],      // negative
                 |o_out == 1'd0,  // zero
                 carry_out,       // carry
                 overflow_out     // overflow
                 };
                         
                                     
endmodule

//////////////////////////////////////////////////////////////////
//                                                              //
//  Barrel Shifter for Amber 2 Core                             //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Provides 32-bit shifts LSL, LSR, ASR and ROR                //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////


module a23_barrel_shift (

input       [31:0]          i_in,
input                       i_carry_in,
input       [7:0]           i_shift_amount,     // uses 8 LSBs of Rs, or a 5 bit immediate constant
input       [1:0]           i_function,

output      [31:0]          o_out,
output                      o_carry_out

);

`include "a23_localparams.vh"

  // MSB is carry out
wire [32:0] lsl_out;
wire [32:0] lsr_out;
wire [32:0] asr_out;
wire [32:0] ror_out;


// Logical shift right zero is redundant as it is the same as logical shift left zero, so
// the assembler will convert LSR #0 (and ASR #0 and ROR #0) into LSL #0, and allow
// lsr #32 to be specified.

// lsl #0 is a special case, where the shifter carry out is the old value of the status flags
// C flag. The contents of Rm are used directly as the second operand.
// assign lsl_out = i_shift_imm_zero         ? {i_carry_in, i_in              } :  // fall through case 
//                  i_shift_amount == 8'd 0  ? {i_carry_in, i_in              } :  // fall through case
//                  i_shift_amount == 8'd 1  ? {i_in[31],   i_in[30: 0],  1'd0} :
//                  i_shift_amount == 8'd 2  ? {i_in[30],   i_in[29: 0],  2'd0} :
//                  i_shift_amount == 8'd 3  ? {i_in[29],   i_in[28: 0],  3'd0} :
//                  i_shift_amount == 8'd 4  ? {i_in[28],   i_in[27: 0],  4'd0} :
//                  i_shift_amount == 8'd 5  ? {i_in[27],   i_in[26: 0],  5'd0} :
//                  i_shift_amount == 8'd 6  ? {i_in[26],   i_in[25: 0],  6'd0} :
//                  i_shift_amount == 8'd 7  ? {i_in[25],   i_in[24: 0],  7'd0} :
//                  i_shift_amount == 8'd 8  ? {i_in[24],   i_in[23: 0],  8'd0} :
//                  i_shift_amount == 8'd 9  ? {i_in[23],   i_in[22: 0],  9'd0} :
//                  i_shift_amount == 8'd10  ? {i_in[22],   i_in[21: 0], 10'd0} :
//                  i_shift_amount == 8'd11  ? {i_in[21],   i_in[20: 0], 11'd0} :
//                  i_shift_amount == 8'd12  ? {i_in[20],   i_in[19: 0], 12'd0} :
//                  i_shift_amount == 8'd13  ? {i_in[19],   i_in[18: 0], 13'd0} :
//                  i_shift_amount == 8'd14  ? {i_in[18],   i_in[17: 0], 14'd0} :
//                  i_shift_amount == 8'd15  ? {i_in[17],   i_in[16: 0], 15'd0} :
//                  i_shift_amount == 8'd16  ? {i_in[16],   i_in[15: 0], 16'd0} :
//                  i_shift_amount == 8'd17  ? {i_in[15],   i_in[14: 0], 17'd0} :
//                  i_shift_amount == 8'd18  ? {i_in[14],   i_in[13: 0], 18'd0} :
//                  i_shift_amount == 8'd19  ? {i_in[13],   i_in[12: 0], 19'd0} :
//                  i_shift_amount == 8'd20  ? {i_in[12],   i_in[11: 0], 20'd0} :
//                  i_shift_amount == 8'd21  ? {i_in[11],   i_in[10: 0], 21'd0} :
//                  i_shift_amount == 8'd22  ? {i_in[10],   i_in[ 9: 0], 22'd0} :
//                  i_shift_amount == 8'd23  ? {i_in[ 9],   i_in[ 8: 0], 23'd0} :
//                  i_shift_amount == 8'd24  ? {i_in[ 8],   i_in[ 7: 0], 24'd0} :
//                  i_shift_amount == 8'd25  ? {i_in[ 7],   i_in[ 6: 0], 25'd0} :
//                  i_shift_amount == 8'd26  ? {i_in[ 6],   i_in[ 5: 0], 26'd0} :
//                  i_shift_amount == 8'd27  ? {i_in[ 5],   i_in[ 4: 0], 27'd0} :
//                  i_shift_amount == 8'd28  ? {i_in[ 4],   i_in[ 3: 0], 28'd0} :
//                  i_shift_amount == 8'd29  ? {i_in[ 3],   i_in[ 2: 0], 29'd0} :
//                  i_shift_amount == 8'd30  ? {i_in[ 2],   i_in[ 1: 0], 30'd0} :
//                  i_shift_amount == 8'd31  ? {i_in[ 1],   i_in[ 0: 0], 31'd0} :
//                  i_shift_amount == 8'd32  ? {i_in[ 0],   32'd0             } :  // 32
//                                             {1'd0,       32'd0             } ;  // > 32
                                            

wire [32:0] lsl_out_struct;
lsl_struct #(.CTRL(5)) u_lsl_struct(i_in, i_shift_amount[4:0], lsl_out_struct);

assign lsl_out[32] = i_shift_amount == 5'd0  ? i_carry_in: lsl_out_struct[32];
assign lsl_out[31:0] = lsl_out_struct[31:0];

// The form of the shift field which might be expected to correspond to LSR #0 is used
// to encode LSR #32, which has a zero result with bit 31 of Rm as the carry output. 
                                           // carry out, < -------- out ---------->
// assign lsr_out = i_shift_imm_zero         ? {i_in[31], 32'd0             } :
//                  i_shift_amount == 8'd 0  ? {i_carry_in, i_in            } :  // fall through case
//                  i_shift_amount == 8'd 1  ? {i_in[ 0],  1'd0, i_in[31: 1]} :
//                  i_shift_amount == 8'd 2  ? {i_in[ 1],  2'd0, i_in[31: 2]} :
//                  i_shift_amount == 8'd 3  ? {i_in[ 2],  3'd0, i_in[31: 3]} :
//                  i_shift_amount == 8'd 4  ? {i_in[ 3],  4'd0, i_in[31: 4]} :
//                  i_shift_amount == 8'd 5  ? {i_in[ 4],  5'd0, i_in[31: 5]} :
//                  i_shift_amount == 8'd 6  ? {i_in[ 5],  6'd0, i_in[31: 6]} :
//                  i_shift_amount == 8'd 7  ? {i_in[ 6],  7'd0, i_in[31: 7]} :
//                  i_shift_amount == 8'd 8  ? {i_in[ 7],  8'd0, i_in[31: 8]} :
//                  i_shift_amount == 8'd 9  ? {i_in[ 8],  9'd0, i_in[31: 9]} :
//                  i_shift_amount == 8'd10  ? {i_in[ 9], 10'd0, i_in[31:10]} :
//                  i_shift_amount == 8'd11  ? {i_in[10], 11'd0, i_in[31:11]} :
//                  i_shift_amount == 8'd12  ? {i_in[11], 12'd0, i_in[31:12]} :
//                  i_shift_amount == 8'd13  ? {i_in[12], 13'd0, i_in[31:13]} :
//                  i_shift_amount == 8'd14  ? {i_in[13], 14'd0, i_in[31:14]} :
//                  i_shift_amount == 8'd15  ? {i_in[14], 15'd0, i_in[31:15]} :
//                  i_shift_amount == 8'd16  ? {i_in[15], 16'd0, i_in[31:16]} :
//                  i_shift_amount == 8'd17  ? {i_in[16], 17'd0, i_in[31:17]} :
//                  i_shift_amount == 8'd18  ? {i_in[17], 18'd0, i_in[31:18]} :
//                  i_shift_amount == 8'd19  ? {i_in[18], 19'd0, i_in[31:19]} :
//                  i_shift_amount == 8'd20  ? {i_in[19], 20'd0, i_in[31:20]} :
//                  i_shift_amount == 8'd21  ? {i_in[20], 21'd0, i_in[31:21]} :
//                  i_shift_amount == 8'd22  ? {i_in[21], 22'd0, i_in[31:22]} :
//                  i_shift_amount == 8'd23  ? {i_in[22], 23'd0, i_in[31:23]} :
//                  i_shift_amount == 8'd24  ? {i_in[23], 24'd0, i_in[31:24]} :
//                  i_shift_amount == 8'd25  ? {i_in[24], 25'd0, i_in[31:25]} :
//                  i_shift_amount == 8'd26  ? {i_in[25], 26'd0, i_in[31:26]} :
//                  i_shift_amount == 8'd27  ? {i_in[26], 27'd0, i_in[31:27]} :
//                  i_shift_amount == 8'd28  ? {i_in[27], 28'd0, i_in[31:28]} :
//                  i_shift_amount == 8'd29  ? {i_in[28], 29'd0, i_in[31:29]} :
//                  i_shift_amount == 8'd30  ? {i_in[29], 30'd0, i_in[31:30]} :
//                  i_shift_amount == 8'd31  ? {i_in[30], 31'd0, i_in[31   ]} :
//                  i_shift_amount == 8'd32  ? {i_in[31], 32'd0             } :
//                                             {1'd0,     32'd0             } ;  // > 32



wire [32:0] lsr_out_struct;
lsr_struct #(.CTRL(5)) u_lsr_struct(i_in, i_shift_amount[4:0], lsr_out_struct);

assign lsr_out[32] = i_shift_amount == 5'd0  ? i_carry_in: lsr_out_struct[32];
assign lsr_out[31:0] = lsr_out_struct[31:0];


// The form of the shift field which might be expected to give ASR #0 is used to encode
// ASR #32. Bit 31 of Rm is again used as the carry output, and each bit of operand 2 is
// also equal to bit 31 of Rm. The result is therefore all ones or all zeros, according to
// the value of bit 31 of Rm.

                                          // carry out, < -------- out ---------->
// assign asr_out = i_shift_imm_zero         ? {i_in[31], {32{i_in[31]}}             } :
//                  i_shift_amount == 8'd 0  ? {i_carry_in, i_in                     } :  // fall through case
//                  i_shift_amount == 8'd 1  ? {i_in[ 0], { 2{i_in[31]}}, i_in[30: 1]} :
//                  i_shift_amount == 8'd 2  ? {i_in[ 1], { 3{i_in[31]}}, i_in[30: 2]} :
//                  i_shift_amount == 8'd 3  ? {i_in[ 2], { 4{i_in[31]}}, i_in[30: 3]} :
//                  i_shift_amount == 8'd 4  ? {i_in[ 3], { 5{i_in[31]}}, i_in[30: 4]} :
//                  i_shift_amount == 8'd 5  ? {i_in[ 4], { 6{i_in[31]}}, i_in[30: 5]} :
//                  i_shift_amount == 8'd 6  ? {i_in[ 5], { 7{i_in[31]}}, i_in[30: 6]} :
//                  i_shift_amount == 8'd 7  ? {i_in[ 6], { 8{i_in[31]}}, i_in[30: 7]} :
//                  i_shift_amount == 8'd 8  ? {i_in[ 7], { 9{i_in[31]}}, i_in[30: 8]} :
//                  i_shift_amount == 8'd 9  ? {i_in[ 8], {10{i_in[31]}}, i_in[30: 9]} :
//                  i_shift_amount == 8'd10  ? {i_in[ 9], {11{i_in[31]}}, i_in[30:10]} :
//                  i_shift_amount == 8'd11  ? {i_in[10], {12{i_in[31]}}, i_in[30:11]} :
//                  i_shift_amount == 8'd12  ? {i_in[11], {13{i_in[31]}}, i_in[30:12]} :
//                  i_shift_amount == 8'd13  ? {i_in[12], {14{i_in[31]}}, i_in[30:13]} :
//                  i_shift_amount == 8'd14  ? {i_in[13], {15{i_in[31]}}, i_in[30:14]} :
//                  i_shift_amount == 8'd15  ? {i_in[14], {16{i_in[31]}}, i_in[30:15]} :
//                  i_shift_amount == 8'd16  ? {i_in[15], {17{i_in[31]}}, i_in[30:16]} :
//                  i_shift_amount == 8'd17  ? {i_in[16], {18{i_in[31]}}, i_in[30:17]} :
//                  i_shift_amount == 8'd18  ? {i_in[17], {19{i_in[31]}}, i_in[30:18]} :
//                  i_shift_amount == 8'd19  ? {i_in[18], {20{i_in[31]}}, i_in[30:19]} :
//                  i_shift_amount == 8'd20  ? {i_in[19], {21{i_in[31]}}, i_in[30:20]} :
//                  i_shift_amount == 8'd21  ? {i_in[20], {22{i_in[31]}}, i_in[30:21]} :
//                  i_shift_amount == 8'd22  ? {i_in[21], {23{i_in[31]}}, i_in[30:22]} :
//                  i_shift_amount == 8'd23  ? {i_in[22], {24{i_in[31]}}, i_in[30:23]} :
//                  i_shift_amount == 8'd24  ? {i_in[23], {25{i_in[31]}}, i_in[30:24]} :
//                  i_shift_amount == 8'd25  ? {i_in[24], {26{i_in[31]}}, i_in[30:25]} :
//                  i_shift_amount == 8'd26  ? {i_in[25], {27{i_in[31]}}, i_in[30:26]} :
//                  i_shift_amount == 8'd27  ? {i_in[26], {28{i_in[31]}}, i_in[30:27]} :
//                  i_shift_amount == 8'd28  ? {i_in[27], {29{i_in[31]}}, i_in[30:28]} :
//                  i_shift_amount == 8'd29  ? {i_in[28], {30{i_in[31]}}, i_in[30:29]} :
//                  i_shift_amount == 8'd30  ? {i_in[29], {31{i_in[31]}}, i_in[30   ]} :
//                  i_shift_amount == 8'd31  ? {i_in[30], {32{i_in[31]}}             } :
//                                             {i_in[31], {32{i_in[31]}}             } ; // >= 32
                                            

wire [32:0] asr_out_struct;
asr_struct #(.CTRL(5)) u_asr_struct(i_in, i_shift_amount[4:0], asr_out_struct);

assign asr_out[32] = i_shift_amount == 5'd0  ? i_carry_in: asr_out_struct[32];
assign asr_out[31:0] = asr_out_struct[31:0];

                                          // carry out, < ------- out --------->
// assign ror_out = i_shift_imm_zero              ? {i_in[ 0], i_carry_in,  i_in[31: 1]} :  // RXR, (ROR w/ imm 0)
//                  i_shift_amount[7:0] == 8'd 0  ? {i_carry_in, i_in                  } :  // fall through case
//                  i_shift_amount[4:0] == 5'd 0  ? {i_in[31], i_in                    } :  // Rs > 31
//                  i_shift_amount[4:0] == 5'd 1  ? {i_in[ 0], i_in[    0], i_in[31: 1]} :
//                  i_shift_amount[4:0] == 5'd 2  ? {i_in[ 1], i_in[ 1: 0], i_in[31: 2]} :
//                  i_shift_amount[4:0] == 5'd 3  ? {i_in[ 2], i_in[ 2: 0], i_in[31: 3]} :
//                  i_shift_amount[4:0] == 5'd 4  ? {i_in[ 3], i_in[ 3: 0], i_in[31: 4]} :
//                  i_shift_amount[4:0] == 5'd 5  ? {i_in[ 4], i_in[ 4: 0], i_in[31: 5]} :
//                  i_shift_amount[4:0] == 5'd 6  ? {i_in[ 5], i_in[ 5: 0], i_in[31: 6]} :
//                  i_shift_amount[4:0] == 5'd 7  ? {i_in[ 6], i_in[ 6: 0], i_in[31: 7]} :
//                  i_shift_amount[4:0] == 5'd 8  ? {i_in[ 7], i_in[ 7: 0], i_in[31: 8]} :
//                  i_shift_amount[4:0] == 5'd 9  ? {i_in[ 8], i_in[ 8: 0], i_in[31: 9]} :
//                  i_shift_amount[4:0] == 5'd10  ? {i_in[ 9], i_in[ 9: 0], i_in[31:10]} :
//                  i_shift_amount[4:0] == 5'd11  ? {i_in[10], i_in[10: 0], i_in[31:11]} :
//                  i_shift_amount[4:0] == 5'd12  ? {i_in[11], i_in[11: 0], i_in[31:12]} :
//                  i_shift_amount[4:0] == 5'd13  ? {i_in[12], i_in[12: 0], i_in[31:13]} :
//                  i_shift_amount[4:0] == 5'd14  ? {i_in[13], i_in[13: 0], i_in[31:14]} :
//                  i_shift_amount[4:0] == 5'd15  ? {i_in[14], i_in[14: 0], i_in[31:15]} :
//                  i_shift_amount[4:0] == 5'd16  ? {i_in[15], i_in[15: 0], i_in[31:16]} :
//                  i_shift_amount[4:0] == 5'd17  ? {i_in[16], i_in[16: 0], i_in[31:17]} :
//                  i_shift_amount[4:0] == 5'd18  ? {i_in[17], i_in[17: 0], i_in[31:18]} :
//                  i_shift_amount[4:0] == 5'd19  ? {i_in[18], i_in[18: 0], i_in[31:19]} :
//                  i_shift_amount[4:0] == 5'd20  ? {i_in[19], i_in[19: 0], i_in[31:20]} :
//                  i_shift_amount[4:0] == 5'd21  ? {i_in[20], i_in[20: 0], i_in[31:21]} :
//                  i_shift_amount[4:0] == 5'd22  ? {i_in[21], i_in[21: 0], i_in[31:22]} :
//                  i_shift_amount[4:0] == 5'd23  ? {i_in[22], i_in[22: 0], i_in[31:23]} :
//                  i_shift_amount[4:0] == 5'd24  ? {i_in[23], i_in[23: 0], i_in[31:24]} :
//                  i_shift_amount[4:0] == 5'd25  ? {i_in[24], i_in[24: 0], i_in[31:25]} :
//                  i_shift_amount[4:0] == 5'd26  ? {i_in[25], i_in[25: 0], i_in[31:26]} :
//                  i_shift_amount[4:0] == 5'd27  ? {i_in[26], i_in[26: 0], i_in[31:27]} :
//                  i_shift_amount[4:0] == 5'd28  ? {i_in[27], i_in[27: 0], i_in[31:28]} :
//                  i_shift_amount[4:0] == 5'd29  ? {i_in[28], i_in[28: 0], i_in[31:29]} :
//                  i_shift_amount[4:0] == 5'd30  ? {i_in[29], i_in[29: 0], i_in[31:30]} :
//                                                  {i_in[30], i_in[30: 0], i_in[31:31]} ;
                 
wire [32:0] ror_out_struct;
ror_struct #(.CTRL(5)) u_ror_struct(i_in, i_shift_amount[4:0], ror_out_struct);


assign ror_out[32] = i_shift_amount == 5'd0  ? i_carry_in: ror_out_struct[32];
assign ror_out[31:0] = ror_out_struct[31:0];

 
assign {o_carry_out, o_out} = i_function == LSL ? lsl_out :
                              i_function == LSR ? lsr_out :
                              i_function == ASR ? asr_out :
                                                  ror_out ;

endmodule


module ror_struct
#( 
  parameter CTRL=5, 
  parameter WIDTH=2**CTRL
)
( 
  input   [WIDTH-1:0] in,
  input   [ CTRL-1:0] shift,
  output  [WIDTH:0] out 
);

  wire [WIDTH:0] tmp [CTRL:0];
  assign tmp[CTRL] = {in[31], in};
  assign out = tmp[0];
  genvar i;
  generate
    for (i = 0; i < CTRL; i = i + 1) begin: mux
      assign tmp[i] = shift[i] ? {tmp[i+1][(2**i)-1], tmp[i+1][(2**i)-1:0],tmp[i+1][WIDTH-1:(2**i)]} : tmp[i+1];
    end
  endgenerate
endmodule


module asr_struct
#( 
  parameter CTRL=5, 
  parameter WIDTH=2**CTRL
)
( 
  input   [WIDTH-1:0] in,
  input   [ CTRL-1:0] shift,
  output  [WIDTH:0] out 
);

  wire sign = in[WIDTH -1];

  wire [WIDTH:0] tmp [CTRL:0];
  assign tmp[CTRL] = {in[0], in};
  assign out = tmp[0];
  genvar i;
  generate
    for (i = 0; i < CTRL; i = i + 1) begin: mux
      assign tmp[i] = shift[i] ? {tmp[i+1][(2**i)-1], {(2**i){sign}}, tmp[i+1][WIDTH-1:(2**i)]} : tmp[i+1];
    end
  endgenerate
endmodule


module lsr_struct
#( 
  parameter CTRL=5, 
  parameter WIDTH=2**CTRL
)
( 
  input   [WIDTH-1:0] in,
  input   [ CTRL-1:0] shift,
  output  [WIDTH:0] out 
);

  wire sign = 1'b0;

  wire [WIDTH:0] tmp [CTRL:0];
  assign tmp[CTRL] = {in[0], in};
  assign out = tmp[0];
  genvar i;
  generate
    for (i = 0; i < CTRL; i = i + 1) begin: mux
      assign tmp[i] = shift[i] ? {tmp[i+1][(2**i)-1], {(2**i){sign}}, tmp[i+1][WIDTH-1:(2**i)]} : tmp[i+1];
    end
  endgenerate
endmodule

module lsl_struct
#( 
  parameter CTRL=5, 
  parameter WIDTH=2**CTRL
)
( 
  input   [WIDTH-1:0] in,
  input   [ CTRL-1:0] shift,
  output  [WIDTH:0] out 
);

  wire [WIDTH:0] tmp [CTRL:0];
  assign tmp[CTRL] = {in[WIDTH-1], in};
  assign out = tmp[0];
  genvar i, j;
  generate
    for (i = 0; i < CTRL; i = i + 1) begin: mux
      assign tmp[i] = shift[i] ? {tmp[i+1][WIDTH-(2**i)], tmp[i+1][WIDTH-(2**i)-1:0], {(2**i){1'b0}}} : tmp[i+1];
    end
  endgenerate
endmodule
//////////////////////////////////////////////////////////////////
//                                                              //
//  Decode stage of Amber 2 Core                                //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  This module is the most complex part of the Amber core      //
//  It decodes and sequences all instructions and handles all   //
//  interrupts                                                  //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////
`include "global_defines.vh"

module a23_decode
(
input                       i_clk,
input                       i_rst,
input       [31:0]          i_read_data,
input       [31:0]          i_execute_address,              // Registered address output by execute stage
                                                            // 2 LSBs of read address used for calculating
                                                            // shift in LDRB ops
input                       i_multiply_done,                // multiply unit is nearly done


// --------------------------------------------------
// Control signals to execute stage
// --------------------------------------------------
output reg  [31:0]          o_read_data,
output reg  [4:0]           o_read_data_alignment,  // 2 LSBs of read address used for calculating shift in LDRB ops

output reg  [31:0]          o_imm32,
output reg  [4:0]           o_imm_shift_amount,
output wire [3:0]           o_condition,
output reg  [3:0]           o_rm_sel,
output reg  [3:0]           o_rds_sel,
output reg  [3:0]           o_rn_sel,
output      [3:0]           o_rm_sel_nxt,
output      [3:0]           o_rds_sel_nxt,
output      [3:0]           o_rn_sel_nxt,
output reg  [1:0]           o_barrel_shift_amount_sel,
output reg  [1:0]           o_barrel_shift_data_sel,
output reg  [1:0]           o_barrel_shift_function,
output reg  [8:0]           o_alu_function,
output reg                  o_use_carry_in,
output reg  [1:0]           o_multiply_function,
output wire [3:0]           o_address_sel,
output wire [1:0]           o_pc_sel,
output reg  [1:0]           o_byte_enable_sel,        // byte, halfword or word write
output reg  [2:0]           o_status_bits_sel,
output reg  [2:0]           o_reg_write_sel,

output reg                  o_write_data_wen,
output wire                 o_pc_wen,
output reg  [14:0]          o_reg_bank_wen,
output reg                  o_status_bits_flags_wen
);

`include "a23_localparams.vh"
`include "a23_functions.vh"

localparam [4:0] RST_WAIT1      = 5'd0,
                 RST_WAIT2      = 5'd1,
                 INT_WAIT1      = 5'd2,
                 INT_WAIT2      = 5'd3,
                 EXECUTE        = 5'd4,
                 PRE_FETCH_EXEC = 5'd5,  // Execute the Pre-Fetched Instruction
                 MEM_WAIT1      = 5'd6,  // conditionally decode current instruction, in case
                                         // previous instruction does not execute in S2
                 MEM_WAIT2      = 5'd7,
                 PC_STALL1      = 5'd8,  // Program Counter altered
                                         // conditionally decude current instruction, in case
                                         // previous instruction does not execute in S2
                 PC_STALL2      = 5'd9,
                 MTRANS_EXEC1   = 5'd10,
                 MTRANS_EXEC2   = 5'd11,
                 MTRANS_EXEC3   = 5'd12,
                 MTRANS_EXEC3B  = 5'd13,
                 MTRANS_EXEC4   = 5'd14,
                 //MTRANS5_ABORT  = 5'd15,
                 MULT_PROC1     = 5'd16,  // first cycle, save pre fetch instruction
                 MULT_PROC2     = 5'd17,  // do multiplication
                 MULT_STORE     = 5'd19;  // save RdLo
                 //MULT_ACCUMU    = 5'd20;  // Accumulate add lower 32 bits
                 //SWAP_WRITE     = 5'd22,
                 //SWAP_WAIT1     = 5'd23,
                 //SWAP_WAIT2     = 5'd24,
                 //COPRO_WAIT     = 5'd25;


// ========================================================
// Internal signals
// ========================================================
wire    [31:0]         instruction;
wire    [31:0]         instruction_address;     // instruction virtual address, follows
                                                // the instruction
wire    [1:0]          instruction_sel;
reg     [3:0]          itype;
wire    [3:0]          opcode;
wire    [7:0]          imm8;
wire    [31:0]         offset12;
wire    [31:0]         offset24;
wire    [4:0]          shift_imm;

wire                   opcode_compare;
wire                   mem_op;
wire                   load_op;
wire                   store_op;
wire                   write_pc;
wire                   immediate_shifter_operand;
wire                   rds_use_rs;
wire                   branch;
wire                   mem_op_pre_indexed;
wire                   mem_op_post_indexed;

// Flop inputs
wire    [31:0]         imm32_nxt;
wire    [4:0]          imm_shift_amount_nxt;
wire    [3:0]          condition_nxt;
wire                   shift_extend;

reg     [1:0]          barrel_shift_function_nxt;
wire    [8:0]          alu_function_nxt;
reg                    use_carry_in_nxt;
reg     [1:0]          multiply_function_nxt;

reg     [1:0]          barrel_shift_amount_sel_nxt;
reg     [1:0]          barrel_shift_data_sel_nxt;
reg     [3:0]          address_sel_nxt;
reg     [1:0]          pc_sel_nxt;
reg     [1:0]          byte_enable_sel_nxt;
reg     [2:0]          status_bits_sel_nxt;
reg     [2:0]          reg_write_sel_nxt;

// ALU Function signals
reg                    alu_swap_sel_nxt;
reg                    alu_not_sel_nxt;
reg     [1:0]          alu_cin_sel_nxt;
reg                    alu_cout_sel_nxt;
reg     [3:0]          alu_out_sel_nxt;

reg                    write_data_wen_nxt;
reg                    copro_write_data_wen_nxt;
reg                    pc_wen_nxt;
reg     [3:0]          reg_bank_wsel_nxt;
reg                    status_bits_flags_wen_nxt;

reg                    saved_current_instruction_wen;   // saved load instruction
reg                    pre_fetch_instruction_wen;       // pre-fetch instruction

reg     [4:0]          control_state;
reg     [4:0]          control_state_nxt;


reg     [31:0]         saved_current_instruction;
reg     [31:0]         saved_current_instruction_address;       // virtual address of abort instruction
reg     [31:0]         pre_fetch_instruction;
reg     [31:0]         pre_fetch_instruction_address;           // virtual address of abort instruction

wire                   instruction_valid;

reg     [3:0]          mtrans_reg;              // the current register being accessed as part of STM/LDM
reg     [3:0]          mtrans_reg_d1;     // delayed by 1 period
reg     [3:0]          mtrans_reg_d2;     // delayed by 2 periods
reg     [31:0]         mtrans_instruction_nxt;

wire   [31:0]          mtrans_base_reg_change;
wire   [4:0]           mtrans_num_registers;
wire                   use_saved_current_instruction;
wire                   use_pre_fetch_instruction;
reg                    mtrans_r15;
reg                    mtrans_r15_nxt;

wire                   regop_set_flags;



// ========================================================
// registers for output ports with non-zero initial values
// ========================================================
reg  [3:0]           condition_r;             // 4'he = al
reg  [3:0]           address_sel_r;
reg  [1:0]           pc_sel_r;
reg                  pc_wen_r;

assign o_condition              = condition_r;
assign o_address_sel            = address_sel_r;
assign o_pc_sel                 = pc_sel_r;
assign o_pc_wen                 = pc_wen_r;



// ========================================================
// Instruction Decode
// ========================================================

// for instructions that take more than one cycle
// the instruction is saved in the 'saved_mem_instruction'
// register and then that register is used for the rest of
// the execution of the instruction.
// But if the instruction does not execute because of the
// condition, then need to select the next instruction to
// decode
assign use_saved_current_instruction = ( control_state == MEM_WAIT1     ||
                                         control_state == MEM_WAIT2     ||
                                         control_state == MTRANS_EXEC1  ||
                                         control_state == MTRANS_EXEC2  ||
                                         control_state == MTRANS_EXEC3  ||
                                         control_state == MTRANS_EXEC3B ||
                                         control_state == MTRANS_EXEC4  ||
                                         control_state == MULT_PROC1    ||
                                         control_state == MULT_PROC2    ||
                                         //control_state == MULT_ACCUMU   ||
                                         control_state == MULT_STORE    );

assign use_pre_fetch_instruction = control_state == PRE_FETCH_EXEC;


assign instruction_sel  =         use_saved_current_instruction  ? 2'd1 :  // saved_current_instruction
                                  use_pre_fetch_instruction      ? 2'd2 :  // pre_fetch_instruction
                                                                   2'd0 ;  // o_read_data

assign instruction      =         instruction_sel == 2'd0 ? o_read_data               :
                                  instruction_sel == 2'd1 ? saved_current_instruction :
                                                            pre_fetch_instruction     ;
assign instruction_address =      instruction_sel == 2'd1 ? saved_current_instruction_address :
                                                            pre_fetch_instruction_address     ;

// Instruction Decode - Order is important!
always @*
    casez ({instruction[27:20], instruction[7:4]})
        12'b00010?001001 : itype = SWAP;
        12'b000000??1001 : itype = MULT;
        12'b00?????????? : itype = REGOP;
        12'b01?????????? : itype = TRANS;
        12'b100????????? : itype = MTRANS;
        12'b101????????? : itype = BRANCH;
        12'b110????????? : itype = CODTRANS;
        12'b1110???????0 : itype = COREGOP;
        12'b1110???????1 : itype = CORTRANS;
        default:           itype = SWI;
    endcase


// ========================================================
// Fixed fields within the instruction
// ========================================================

assign opcode        = instruction[24:21];
assign condition_nxt = instruction[31:28];

assign o_rm_sel_nxt    = instruction[3:0];

assign o_rn_sel_nxt    = branch  ? 4'd15              : // Use PC to calculate branch destination
                                   instruction[19:16] ;

assign o_rds_sel_nxt   = itype == MTRANS              ? mtrans_reg         :
                         branch                       ? 4'd15              : // Update the PC
                         rds_use_rs                   ? instruction[11:8]  :
                                                        instruction[15:12] ;


assign shift_imm     = instruction[11:7];

// this is used for RRX
assign shift_extend  = !instruction[25] && !instruction[4] && !(|instruction[11:7]) && instruction[6:5] == 2'b11;

assign offset12      = { 20'h0, instruction[11:0]};
assign offset24      = {{6{instruction[23]}}, instruction[23:0], 2'd0 }; // sign extend
assign imm8          = instruction[7:0];

assign immediate_shifter_operand = instruction[25];
assign rds_use_rs                = (itype == REGOP && !instruction[25] && instruction[4]) ||
                                   (itype == MULT &&
                                    (control_state == MULT_PROC1  ||
                                     control_state == MULT_PROC2  ||
                                     instruction_valid )) ;
assign branch                    = itype == BRANCH;
assign opcode_compare =
            opcode == CMP ||
            opcode == CMN ||
            opcode == TEQ ||
            opcode == TST ;


assign mem_op               = itype == TRANS;
assign load_op              = mem_op && instruction[20];
assign store_op             = mem_op && !instruction[20];
assign write_pc             = pc_wen_nxt && pc_sel_nxt != 2'd0;
assign regop_set_flags      = itype == REGOP && instruction[20];

assign mem_op_pre_indexed   =  instruction[24] && instruction[21];
assign mem_op_post_indexed  = !instruction[24];

assign imm32_nxt            =  // add 0 to Rm
                               itype == MULT               ? {  32'd0                      } :

                               // 4 x number of registers
                               itype == MTRANS             ? {  mtrans_base_reg_change     } :
                               itype == BRANCH             ? {  offset24                   } :
                               itype == TRANS              ? {  offset12                   } :
                               instruction[11:8] == 4'h0  ? {            24'h0, imm8[7:0] } :
                               instruction[11:8] == 4'h1  ? { imm8[1:0], 24'h0, imm8[7:2] } :
                               instruction[11:8] == 4'h2  ? { imm8[3:0], 24'h0, imm8[7:4] } :
                               instruction[11:8] == 4'h3  ? { imm8[5:0], 24'h0, imm8[7:6] } :
                               instruction[11:8] == 4'h4  ? { imm8[7:0], 24'h0            } :
                               instruction[11:8] == 4'h5  ? { 2'h0,  imm8[7:0], 22'h0     } :
                               instruction[11:8] == 4'h6  ? { 4'h0,  imm8[7:0], 20'h0     } :
                               instruction[11:8] == 4'h7  ? { 6'h0,  imm8[7:0], 18'h0     } :
                               instruction[11:8] == 4'h8  ? { 8'h0,  imm8[7:0], 16'h0     } :
                               instruction[11:8] == 4'h9  ? { 10'h0, imm8[7:0], 14'h0     } :
                               instruction[11:8] == 4'ha  ? { 12'h0, imm8[7:0], 12'h0     } :
                               instruction[11:8] == 4'hb  ? { 14'h0, imm8[7:0], 10'h0     } :
                               instruction[11:8] == 4'hc  ? { 16'h0, imm8[7:0], 8'h0      } :
                               instruction[11:8] == 4'hd  ? { 18'h0, imm8[7:0], 6'h0      } :
                               instruction[11:8] == 4'he  ? { 20'h0, imm8[7:0], 4'h0      } :
                                                            { 22'h0, imm8[7:0], 2'h0      } ;


assign imm_shift_amount_nxt = shift_imm ;
assign alu_function_nxt     = { alu_swap_sel_nxt,
                                alu_not_sel_nxt,
                                alu_cin_sel_nxt,
                                alu_cout_sel_nxt,
                                alu_out_sel_nxt  };


// ========================================================
// MTRANS Operations
// ========================================================

   // Bit 15 = r15
   // Bit 0  = R0
   // In LDM and STM instructions R0 is loaded or stored first
always @*
    casez (instruction[15:0])
    16'b???????????????1 : mtrans_reg = 4'h0 ;
    16'b??????????????10 : mtrans_reg = 4'h1 ;
    16'b?????????????100 : mtrans_reg = 4'h2 ;
    16'b????????????1000 : mtrans_reg = 4'h3 ;
    16'b???????????10000 : mtrans_reg = 4'h4 ;
    16'b??????????100000 : mtrans_reg = 4'h5 ;
    16'b?????????1000000 : mtrans_reg = 4'h6 ;
    16'b????????10000000 : mtrans_reg = 4'h7 ;
    16'b???????100000000 : mtrans_reg = 4'h8 ;
    16'b??????1000000000 : mtrans_reg = 4'h9 ;
    16'b?????10000000000 : mtrans_reg = 4'ha ;
    16'b????100000000000 : mtrans_reg = 4'hb ;
    16'b???1000000000000 : mtrans_reg = 4'hc ;
    16'b??10000000000000 : mtrans_reg = 4'hd ;
    16'b?100000000000000 : mtrans_reg = 4'he ;
    default              : mtrans_reg = 4'hf ;
    endcase


always @*
    casez (instruction[15:0])
    16'b???????????????1 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 1],  1'd0};
    16'b??????????????10 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 2],  2'd0};
    16'b?????????????100 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 3],  3'd0};
    16'b????????????1000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 4],  4'd0};
    16'b???????????10000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 5],  5'd0};
    16'b??????????100000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 6],  6'd0};
    16'b?????????1000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 7],  7'd0};
    16'b????????10000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 8],  8'd0};
    16'b???????100000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15: 9],  9'd0};
    16'b??????1000000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15:10], 10'd0};
    16'b?????10000000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15:11], 11'd0};
    16'b????100000000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15:12], 12'd0};
    16'b???1000000000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15:13], 13'd0};
    16'b??10000000000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15:14], 14'd0};
    16'b?100000000000000 : mtrans_instruction_nxt = {instruction[31:16], instruction[15   ], 15'd0};
    default              : mtrans_instruction_nxt = {instruction[31:16],                     16'd0};
    endcase


// number of registers to be stored
assign mtrans_num_registers =   {4'd0, instruction[15]} +
                                {4'd0, instruction[14]} +
                                {4'd0, instruction[13]} +
                                {4'd0, instruction[12]} +
                                {4'd0, instruction[11]} +
                                {4'd0, instruction[10]} +
                                {4'd0, instruction[ 9]} +
                                {4'd0, instruction[ 8]} +
                                {4'd0, instruction[ 7]} +
                                {4'd0, instruction[ 6]} +
                                {4'd0, instruction[ 5]} +
                                {4'd0, instruction[ 4]} +
                                {4'd0, instruction[ 3]} +
                                {4'd0, instruction[ 2]} +
                                {4'd0, instruction[ 1]} +
                                {4'd0, instruction[ 0]} ;

// 4 x number of registers to be stored
assign mtrans_base_reg_change = {25'd0, mtrans_num_registers, 2'd0};


// ========================================================
// Generate control signals
// ========================================================
always @(*)
    begin

    // Save an instruction to use later
    saved_current_instruction_wen   = 1'd0;
    pre_fetch_instruction_wen       = 1'd0;
    mtrans_r15_nxt                  = mtrans_r15;

    // default Mux Select values
    barrel_shift_amount_sel_nxt     = 'd0;  // don't shift the input
    barrel_shift_data_sel_nxt       = 'd0;  // immediate value
    barrel_shift_function_nxt       = 'd0;
    use_carry_in_nxt                = 'd0;
    multiply_function_nxt           = 'd0;
    address_sel_nxt                 = 'd0;
    pc_sel_nxt                      = 'd0;
    byte_enable_sel_nxt             = 'd0;
    status_bits_sel_nxt             = 'd0;
    reg_write_sel_nxt               = 'd0;

    // ALU Muxes
    alu_swap_sel_nxt                = 'd0;
    alu_not_sel_nxt                 = 'd0;
    alu_cin_sel_nxt                 = 'd0;
    alu_cout_sel_nxt                = 'd0;
    alu_out_sel_nxt                 = 'd0;

    // default Flop Write Enable values
    write_data_wen_nxt              = 'd0;
    pc_wen_nxt                      = 'd1;
    reg_bank_wsel_nxt               = 'hF;  // Don't select any
    status_bits_flags_wen_nxt       = 'd0;

    if ( instruction_valid ) begin
        if ( itype == REGOP ) begin
            if ( !opcode_compare ) begin
                // Check is the load destination is the PC
                if (instruction[15:12]  == 4'd15) begin
                    pc_sel_nxt      = 2'd1; // alu_out
                    address_sel_nxt = 4'd1; // alu_out
                end else
                    reg_bank_wsel_nxt = instruction[15:12];
            end

            if ( !immediate_shifter_operand )
                barrel_shift_function_nxt  = instruction[6:5];

            if ( !immediate_shifter_operand )
                barrel_shift_data_sel_nxt = 2'd2; // Shift value from Rm register

            if ( !immediate_shifter_operand && instruction[4] )
                barrel_shift_amount_sel_nxt = 2'd1; // Shift amount from Rs registter

            if ( !immediate_shifter_operand && !instruction[4] )
                barrel_shift_amount_sel_nxt = 2'd2; // Shift immediate amount

            // regops that do not change the overflow flag
            if ( opcode == AND || opcode == EOR || opcode == TST || opcode == TEQ ||
                 opcode == ORR || opcode == MOV || opcode == BIC || opcode == MVN )
                status_bits_sel_nxt = 3'd5;

            if ( opcode == ADD || opcode == CMN ) begin  // CMN is just like an ADD
                alu_out_sel_nxt  = 4'd1; // Add
                use_carry_in_nxt = shift_extend;
            end

            if ( opcode == ADC ) begin // Add with Carry
                alu_out_sel_nxt  = 4'd1; // Add
                alu_cin_sel_nxt  = 2'd2; // carry in from status_bits
                use_carry_in_nxt = shift_extend;
            end

            if ( opcode == SUB || opcode == CMP ) begin// Subtract
                alu_out_sel_nxt  = 4'd1; // Add
                alu_cin_sel_nxt  = 2'd1; // cin = 1
                alu_not_sel_nxt  = 1'd1; // invert B
            end

            // SBC (Subtract with Carry) subtracts the value of its
            // second operand and the value of NOT(Carry flag) from
            // the value of its first operand.
            //  Rd = Rn - shifter_operand - NOT(C Flag)
            if ( opcode == SBC ) begin// Subtract with Carry
                alu_out_sel_nxt  = 4'd1; // Add
                alu_cin_sel_nxt  = 2'd2; // carry in from status_bits
                alu_not_sel_nxt  = 1'd1; // invert B
                use_carry_in_nxt = 1'd1;
            end

            if ( opcode == RSB ) begin // Reverse Subtract
                alu_out_sel_nxt  = 4'd1; // Add
                alu_cin_sel_nxt  = 2'd1; // cin = 1
                alu_not_sel_nxt  = 1'd1; // invert B
                alu_swap_sel_nxt = 1'd1; // swap A and B
                end

            if ( opcode == RSC ) begin // Reverse Subtract with carry
                alu_out_sel_nxt  = 4'd1; // Add
                alu_cin_sel_nxt  = 2'd2; // carry in from status_bits
                alu_not_sel_nxt  = 1'd1; // invert B
                alu_swap_sel_nxt = 1'd1; // swap A and B
                use_carry_in_nxt = 1'd1;
                end

            if ( opcode == AND || opcode == TST ) begin // Logical AND, Test  (using AND operator)
                alu_out_sel_nxt  = 4'd8;  // AND
                alu_cout_sel_nxt = 1'd1;  // i_barrel_shift_carry
                end

            if ( opcode == EOR || opcode == TEQ ) begin // Logical Exclusive OR, Test Equivalence (using EOR operator)
                alu_out_sel_nxt  = 4'd6; // XOR
                alu_cout_sel_nxt = 1'd1; // i_barrel_shift_carry
                use_carry_in_nxt = 1'd1;
                end

            if ( opcode == ORR ) begin
                alu_out_sel_nxt  = 4'd7; // OR
                alu_cout_sel_nxt = 1'd1; // i_barrel_shift_carry
                use_carry_in_nxt = 1'd1;
                end

            if ( opcode == BIC ) begin // Bit Clear (using AND & NOT operators)
                alu_out_sel_nxt  = 4'd8;  // AND
                alu_not_sel_nxt  = 1'd1;  // invert B
                alu_cout_sel_nxt = 1'd1;  // i_barrel_shift_carry
                use_carry_in_nxt = 1'd1;
                end

            if ( opcode == MOV ) begin // Move
                alu_cout_sel_nxt = 1'd1;  // i_barrel_shift_carry
                use_carry_in_nxt = 1'd1;
                end

            if ( opcode == MVN ) begin // Move NOT
                alu_not_sel_nxt  = 1'd1; // invert B
                alu_cout_sel_nxt = 1'd1; // i_barrel_shift_carry
                use_carry_in_nxt = 1'd1;
                end
            end

        // Load & Store instructions
        if ( mem_op ) begin
            saved_current_instruction_wen   = 1'd1; // Save the memory access instruction to refer back to later
            pc_wen_nxt                      = 1'd0; // hold current PC value
            alu_out_sel_nxt                 = 4'd1; // Add

            if ( !instruction[23] ) begin // U: Subtract offset
                alu_cin_sel_nxt  = 2'd1; // cin = 1
                alu_not_sel_nxt  = 1'd1; // invert B
            end

            if ( store_op ) begin
                write_data_wen_nxt = 1'd1;
                if ( itype == TRANS && instruction[22] )
                    byte_enable_sel_nxt = 2'd1;         // Save byte
            end

                // need to update the register holding the address ?
                // This is Rn bits [19:16]
            if ( mem_op_pre_indexed || mem_op_post_indexed ) begin
                // Check is the load destination is the PC
                if ( o_rn_sel_nxt  == 4'd15 )
                    pc_sel_nxt = 2'd1;
                else
                    reg_bank_wsel_nxt = o_rn_sel_nxt;
            end

                // if post-indexed, then use Rn rather than ALU output, as address
            if ( mem_op_post_indexed )
               address_sel_nxt = 4'd4; // Rn
            else
               address_sel_nxt = 4'd1; // alu out

            if ( instruction[25] && itype ==  TRANS )
                barrel_shift_data_sel_nxt = 2'd2; // Shift value from Rm register

            if ( itype == TRANS && instruction[25] && shift_imm != 5'd0 ) begin
                barrel_shift_function_nxt   = instruction[6:5];
                barrel_shift_amount_sel_nxt = 2'd2; // imm_shift_amount
            end
        end

        if ( itype == BRANCH ) begin
            pc_sel_nxt      = 2'd3; // branch_pc
            address_sel_nxt = 4'd8; // branch_address
            alu_out_sel_nxt = 4'd1; // Add

            if ( instruction[24] ) begin // Link
                reg_bank_wsel_nxt  = 4'd14;  // Save PC to LR
                reg_write_sel_nxt = 3'd1;            // pc - 32'd4
            end
        end

        if ( itype == MTRANS ) begin
            saved_current_instruction_wen   = 1'd1; // Save the memory access instruction to refer back to later
            pc_wen_nxt                      = 1'd0; // hold current PC value
            alu_out_sel_nxt                 = 4'd1; // Add
            mtrans_r15_nxt                  = instruction[15];  // load or save r15 ?

            // Increment or Decrement
            if ( instruction[23] ) begin// increment
                
                if ( instruction[24] )    // increment before
                    address_sel_nxt = 4'd7; // Rn + 4
                else
                    address_sel_nxt = 4'd4; // Rn
            end else begin// decrement
                alu_cin_sel_nxt  = 2'd1; // cin = 1
                alu_not_sel_nxt  = 1'd1; // invert B
                if ( !instruction[24] )    // decrement after
                    address_sel_nxt  = 4'd6; // alu out + 4
                else
                    address_sel_nxt  = 4'd1; // alu out
            end

            // Load or store ?
            if ( !instruction[20] )  // Store
                write_data_wen_nxt = 1'd1;

            // update the base register ?
            if ( instruction[21] )  // the W bit
                reg_bank_wsel_nxt  = o_rn_sel_nxt;
        end


        if ( itype == MULT ) begin
            multiply_function_nxt[0]        = 1'd1; // set enable
                                                    // some bits can be changed just below
            saved_current_instruction_wen   = 1'd1; // Save the Multiply instruction to
                                                    // refer back to later
            pc_wen_nxt                      = 1'd0; // hold current PC value

            if ( instruction[21] )
                multiply_function_nxt[1]    = 1'd1; // accumulate
        end

        if ( regop_set_flags ) begin
            status_bits_flags_wen_nxt = 1'd1;

            // If <Rd> is r15, the ALU output is copied to the Status Bits.
            // Not allowed to use r15 for mul or lma instructions
            if ( instruction[15:12] == 4'd15 ) begin
                status_bits_sel_nxt       = 3'd1; // alu out
            end
        end

    end


    // previous instruction was either ldr or sdr
    // if it is currently executing in the execute stage do the following
    if ( control_state == MEM_WAIT1 ) begin
        // Save the next instruction to execute later
        // Do this even if this instruction does not execute because of Condition
        pre_fetch_instruction_wen   = 1'd1;
        address_sel_nxt             = 4'd3; // pc  (not pc + 4)
        pc_wen_nxt                  = 1'd0; // hold current PC value
    end


    // completion of load operation
    if ( control_state == MEM_WAIT2 && load_op ) begin
        barrel_shift_data_sel_nxt   = 2'd1;  // load word from memory
        barrel_shift_amount_sel_nxt = 2'd3;  // shift by address[1:0] x 8

        // shift needed
        if ( i_execute_address[1:0] != 2'd0 )
            barrel_shift_function_nxt = ROR;

        // load a byte
        if ( itype == TRANS && instruction[22] )
            alu_out_sel_nxt             = 4'd3;  // zero_extend8
        // Check if the load destination is the PC
        if (instruction[15:12]  == 4'd15) begin
            pc_sel_nxt      = 2'd1; // alu_out
            address_sel_nxt = 4'd1; // alu_out
        end else
            reg_bank_wsel_nxt = instruction[15:12];
    end


    // second cycle of multiple load or store
    if ( control_state == MTRANS_EXEC1 ) begin
        // Save the next instruction to execute later
        // Do this even if this instruction does not execute because of Condition
        pre_fetch_instruction_wen   = 1'd1;

        address_sel_nxt             = 4'd5;  // o_address
        pc_wen_nxt                  = 1'd0;  // hold current PC value
        if ( !instruction[20] ) // Store
            write_data_wen_nxt = 1'd1;
    end


    // third cycle of multiple load or store
    if ( control_state == MTRANS_EXEC2 ) begin
        address_sel_nxt             = 4'd5;  // o_address
        pc_wen_nxt                  = 1'd0;  // hold current PC value
        barrel_shift_data_sel_nxt   = 2'd1;  // load word from memory

        // Load or Store
        if ( instruction[20] ) // Load
                reg_bank_wsel_nxt = mtrans_reg_d2;
        else // Store
            write_data_wen_nxt = 1'd1;
    end

        // second or fourth cycle of multiple load or store
    if ( control_state == MTRANS_EXEC3 ) begin
        address_sel_nxt             = 4'd3; // pc  (not pc + 4)
        pc_wen_nxt                  = 1'd0;  // hold current PC value
        barrel_shift_data_sel_nxt   = 2'd1;  // load word from memory

        // Can never be loading the PC in this state, as the PC is always
        // the last register in the set to be loaded
        if ( instruction[20] ) // Load
            reg_bank_wsel_nxt = mtrans_reg_d2;
    end

    // state is used for LMD/STM of a single register
    if ( control_state == MTRANS_EXEC3B ) begin
        // Save the next instruction to execute later
        // Do this even if this instruction does not execute because of Condition
        pre_fetch_instruction_wen   = 1'd1;

        address_sel_nxt             = 4'd3;  // pc  (not pc + 4)
        pc_wen_nxt                  = 1'd0;  // hold current PC value

    end

    if ( control_state == MTRANS_EXEC4 ) begin
        barrel_shift_data_sel_nxt   = 2'd1;  // load word from memory
        if ( instruction[20] ) begin// Load
            if ( mtrans_reg_d2 == 4'd15 ) begin// load new value into PC
                address_sel_nxt = 4'd1; // alu_out - read instructions using new PC value
                pc_sel_nxt      = 2'd1; // alu_out
                pc_wen_nxt      = 1'd1; // write PC

                // ldm with S bit and pc: the Status bits are updated
                // Node this must be done only at the end
                // so the register set is the set in the mode before it
                // gets changed.
                if ( instruction[22] ) begin
                     status_bits_sel_nxt           = 3'd1; // alu out
                     status_bits_flags_wen_nxt     = 1'd1;
                end
            end else begin
                reg_bank_wsel_nxt = mtrans_reg_d2;
            end
        end
    end


    // Multiply or Multiply-Accumulate
    if ( control_state == MULT_PROC1 ) begin
        // Save the next instruction to execute later
        // Do this even if this instruction does not execute because of Condition
        pre_fetch_instruction_wen   = 1'd1;
        pc_wen_nxt                  = 1'd0;  // hold current PC value
        multiply_function_nxt       = o_multiply_function;
    end


        // Multiply or Multiply-Accumulate
        // Do multiplication
        // Wait for done or accumulate signal
    if ( control_state == MULT_PROC2 ) begin
        // Save the next instruction to execute later
        // Do this even if this instruction does not execute because of Condition
        pc_wen_nxt              = 1'd0;  // hold current PC value
        address_sel_nxt         = 4'd3;  // pc  (not pc + 4)
        multiply_function_nxt   = o_multiply_function;
    end 


    // Save RdLo
    // always last cycle of all multiply or multiply accumulate operations
    if ( control_state == MULT_STORE ) begin
        reg_write_sel_nxt     = 3'd2; // multiply_out
        multiply_function_nxt = o_multiply_function;

        reg_bank_wsel_nxt      = instruction[19:16]; // Rd
     
        if ( instruction[20] ) begin // the 'S' bit
            status_bits_sel_nxt       = 3'd4; // { multiply_flags, status_bits_flags[1:0] }
            status_bits_flags_wen_nxt = 1'd1;
        end
    end
end


// ========================================================
// Next State Logic
// ========================================================

assign instruction_valid = (control_state == EXECUTE || control_state == PRE_FETCH_EXEC);


 always @* begin
    // default is to hold the current state
    control_state_nxt = control_state;

    // Note: The order is important here
    if ( control_state == RST_WAIT1 )          
        control_state_nxt = RST_WAIT2;
    else if ( control_state == RST_WAIT2 )     
        control_state_nxt = EXECUTE;
    else if ( control_state == INT_WAIT1 )     
        control_state_nxt = INT_WAIT2;
    else if ( control_state == INT_WAIT2 )     
        control_state_nxt = EXECUTE;
    else if ( control_state == PC_STALL1 )     
        control_state_nxt = PC_STALL2;
    else if ( control_state == PC_STALL2 )     
        control_state_nxt = EXECUTE;
    else if ( control_state == MULT_STORE )    
        control_state_nxt = PRE_FETCH_EXEC;
    else if ( control_state == MEM_WAIT1 )     
        control_state_nxt = MEM_WAIT2;
    else if ( control_state == MEM_WAIT2) begin
        if ( write_pc ) // writing to the PC!!
            control_state_nxt = PC_STALL1;
        else
            control_state_nxt = PRE_FETCH_EXEC;
    end else if ( control_state == MTRANS_EXEC1 ) begin
        if (mtrans_instruction_nxt[15:0] != 16'd0)
            control_state_nxt = MTRANS_EXEC2;
        else   // if the register list holds a single register
            control_state_nxt = MTRANS_EXEC3;
    end else if ( control_state == MTRANS_EXEC2 && mtrans_num_registers == 5'd1 ) 
        // Stay in State MTRANS_EXEC2 until the full list of registers to
        // load or store has been processed
        control_state_nxt = MTRANS_EXEC3;
    else if ( control_state == MTRANS_EXEC3 )     
        control_state_nxt = MTRANS_EXEC4;
    else if ( control_state == MTRANS_EXEC3B )    
        control_state_nxt = MTRANS_EXEC4;
    else if ( control_state == MTRANS_EXEC4  ) begin
        if (write_pc) // writing to the PC!!
            control_state_nxt = PC_STALL1;
        else
            control_state_nxt = PRE_FETCH_EXEC;
    end else if ( control_state == MULT_PROC1 ) begin
        control_state_nxt = MULT_PROC2;
    end else if ( control_state == MULT_PROC2 ) begin
        if ( i_multiply_done )
            control_state_nxt = MULT_STORE;
    end else if ( instruction_valid ) begin
        control_state_nxt = EXECUTE;

        if ( mem_op )  // load or store word or byte
             control_state_nxt = MEM_WAIT1;
        if ( write_pc )
             control_state_nxt = PC_STALL1;
        if ( itype == MTRANS ) begin
            if ( mtrans_num_registers != 5'd0 ) begin
                // check for LDM/STM of a single register
                if ( mtrans_num_registers == 5'd1 )
                    control_state_nxt = MTRANS_EXEC3B;
                else
                    control_state_nxt = MTRANS_EXEC1;
            end else begin
                control_state_nxt = MTRANS_EXEC3;
            end
        end

        if ( itype == MULT )
            control_state_nxt = MULT_PROC1;
    end
end


// ========================================================
// Register Update
// ========================================================

always @ ( posedge i_clk  or posedge i_rst)
    if(i_rst) begin
        o_read_data                 <= 'b0;
        o_read_data_alignment       <= 'd0;
        o_imm32                     <= 'd0;
        o_imm_shift_amount          <= 'd0;
        condition_r                 <=  4'he;
        o_rm_sel                    <= 'd0;
        o_rds_sel                   <= 'd0;
        o_rn_sel                    <= 'd0;
        o_barrel_shift_amount_sel   <= 'd0;
        o_barrel_shift_data_sel     <= 'd0;
        o_barrel_shift_function     <= 'd0;
        o_alu_function              <= 'd0;
        o_use_carry_in              <= 'd0;
        o_multiply_function         <= 'd0;
        address_sel_r               <= 'd0;
        pc_sel_r                    <= 'd0;
        o_byte_enable_sel           <= 'd0;
        o_status_bits_sel           <= 'd0;
        o_reg_write_sel             <= 'd0;
        o_write_data_wen            <= 'd0;
        pc_wen_r                    <= 1'd1;
        o_reg_bank_wen              <= 'd0;
        o_status_bits_flags_wen     <= 'd0;
        mtrans_r15                  <= 'd0;
        control_state               <= RST_WAIT2;
        mtrans_reg_d1               <= 'd0;
        mtrans_reg_d2               <= 'd0;
    end else begin
        o_read_data                 <= i_read_data;
        o_read_data_alignment       <= {i_execute_address[1:0], 3'd0};
        o_imm32                     <= imm32_nxt;
        o_imm_shift_amount          <= imm_shift_amount_nxt;

        condition_r                 <= instruction_valid ? condition_nxt : condition_r;

        o_rm_sel                    <= o_rm_sel_nxt;
        o_rds_sel                   <= o_rds_sel_nxt;
        o_rn_sel                    <= o_rn_sel_nxt;
        o_barrel_shift_amount_sel   <= barrel_shift_amount_sel_nxt;
        o_barrel_shift_data_sel     <= barrel_shift_data_sel_nxt;
        o_barrel_shift_function     <= barrel_shift_function_nxt;
        o_alu_function              <= alu_function_nxt;
        o_use_carry_in              <= use_carry_in_nxt;
        o_multiply_function         <= multiply_function_nxt;
        address_sel_r               <= address_sel_nxt;
        pc_sel_r                    <= pc_sel_nxt;
        o_byte_enable_sel           <= byte_enable_sel_nxt;
        o_status_bits_sel           <= status_bits_sel_nxt;
        o_reg_write_sel             <= reg_write_sel_nxt;
        o_write_data_wen            <= write_data_wen_nxt;
        pc_wen_r                    <= pc_wen_nxt;
        o_reg_bank_wen              <= decode ( reg_bank_wsel_nxt );
        o_status_bits_flags_wen     <= status_bits_flags_wen_nxt;

        mtrans_r15                  <= mtrans_r15_nxt;
        control_state               <= control_state_nxt;
        mtrans_reg_d1               <= mtrans_reg;
        mtrans_reg_d2               <= mtrans_reg_d1;
    end



always @ ( posedge i_clk or posedge i_rst)
    if(i_rst) begin
      saved_current_instruction              <= 'd0;
      saved_current_instruction_address      <= 'd0;
      pre_fetch_instruction                  <= 'd0;
      pre_fetch_instruction_address          <= 'd0;
    end else begin
        // sometimes this is a pre-fetch instruction
        // e.g. two ldr instructions in a row. The second ldr will be saved
        // to the pre-fetch instruction register
        // then when its decoded, a copy is saved to the saved_current_instruction
        // register
        if      (itype == MTRANS)
            begin
            saved_current_instruction              <= mtrans_instruction_nxt;
            saved_current_instruction_address      <= instruction_address;
            end
        else if (saved_current_instruction_wen)
            begin
            saved_current_instruction              <= instruction;
            saved_current_instruction_address      <= instruction_address;
            end

        if      (pre_fetch_instruction_wen)
        begin
            pre_fetch_instruction                  <= o_read_data;
        end
    end
endmodule

//////////////////////////////////////////////////////////////////
//                                                              //
//  Execute stage of Amber 2 Core                               //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Executes instructions. Instantiates the register file, ALU  //
//  multiplication unit and barrel shifter. This stage is       //
//  relitively simple. All the complex stuff is done in the     //
//  decode stage.                                               //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////

`include "a23_config_defines.vh"

module a23_execute (

input                       i_clk,
input                       i_rst,
input       [31:0]          i_read_data,
input       [4:0]           i_read_data_alignment,  // 2 LSBs of address in [4:3], appended 
                                                    // with 3 zeros
output reg  [31:0]          o_write_data,
output wire [31:0]          o_address,
                                                    // wishbone access
output      [31:0]          o_address_nxt,          // un-registered version of address to the 
                                                    // cache rams address ports
output reg                  o_write_enable,
output reg  [3:0]           o_byte_enable,
                                                    // low = instruction fetch
output                      o_multiply_done,


// --------------------------------------------------
// Control signals from Instruction Decode stage
// --------------------------------------------------
input      [31:0]           i_imm32,
input      [4:0]            i_imm_shift_amount,
input      [3:0]            i_condition,
input                       i_use_carry_in,         // e.g. add with carry instruction

input      [3:0]            i_rm_sel,
input      [3:0]            i_rds_sel,
input      [3:0]            i_rn_sel,
input      [3:0]            i_rm_sel_nxt,
input      [3:0]            i_rds_sel_nxt,
input      [3:0]            i_rn_sel_nxt,
input      [1:0]            i_barrel_shift_amount_sel,
input      [1:0]            i_barrel_shift_data_sel,
input      [1:0]            i_barrel_shift_function,
input      [8:0]            i_alu_function,
input      [1:0]            i_multiply_function,
input      [3:0]            i_address_sel,
input      [1:0]            i_pc_sel,
input      [1:0]            i_byte_enable_sel,
input      [2:0]            i_status_bits_sel,
input      [2:0]            i_reg_write_sel,
input                       i_write_data_wen,
                                                    // in case of data abort
input                       i_pc_wen,
input      [14:0]           i_reg_bank_wen,
input                       i_status_bits_flags_wen
);

`include "a23_localparams.vh"
`include "a23_functions.vh"

// ========================================================
// Internal signals
// ========================================================
wire [31:0]         write_data_nxt;
wire [3:0]          byte_enable_nxt;
wire [31:0]         pc_plus4;
wire [31:0]         pc_minus4;
wire [31:0]         address_plus4;
wire [31:0]         alu_plus4;
wire [31:0]         rn_plus4;
wire [31:0]         alu_out;
wire [3:0]          alu_flags;
wire [31:0]         rm;
wire [31:0]         rs;
wire [31:0]         rd;
wire [31:0]         rn;
wire [31:0]         pc;
wire [31:0]         pc_nxt;
wire [31:0]         branch_pc_nxt;
wire                write_enable_nxt;
wire [7:0]          shift_amount;
wire [31:0]         barrel_shift_in;
wire [31:0]         barrel_shift_out;
wire                barrel_shift_carry;
wire                barrel_shift_carry_alu;

wire [3:0]          status_bits_flags_nxt;
reg  [3:0]          status_bits_flags;

wire                execute;           // high when condition execution is true
wire [31:0]         reg_write_nxt;
wire                pc_wen;
wire [14:0]         reg_bank_wen;
wire [3:0]          reg_bank_wsel;
wire [31:0]         multiply_out;
wire [1:0]          multiply_flags;

wire                address_update;
wire                write_data_update;
wire                byte_enable_update;
wire                write_enable_update;
wire                status_bits_flags_update;

wire [31:0]         alu_out_pc_filtered;
wire [31:0]         branch_address_nxt;

wire                carry_in;

reg  [31:0]         address_r;


// ========================================================
// Status Bits Select
// ========================================================
assign status_bits_flags_nxt     = i_status_bits_sel == 3'd0 ? alu_flags                           :
                                   i_status_bits_sel == 3'd1 ? alu_out          [31:28]            :
                                   //i_status_bits_sel == 3'd3 ? i_copro_read_data[31:28]            :
                                   //  update flags after a multiply operation
                                   i_status_bits_sel == 3'd4 ? { multiply_flags, status_bits_flags[1:0] } :
                                   // regops that do not change the overflow flag
                                   i_status_bits_sel == 3'd5 ? { alu_flags[3:1], status_bits_flags[0] } :
                                                               4'b1111 ;

// ========================================================
// Adders
// ========================================================
assign pc_plus4      = pc        + 32'd4;
assign pc_minus4     = pc        - 32'd4;
assign address_plus4 = address_r + 32'd4;
assign alu_plus4     = alu_out   + 32'd4;
assign rn_plus4      = rn        + 32'd4;


// ========================================================
// Barrel Shift Amount Select
// ========================================================
// An immediate shift value of 0 is translated into 32
assign shift_amount = i_barrel_shift_amount_sel == 2'd0 ? 8'd0                           :
                      i_barrel_shift_amount_sel == 2'd1 ? rs[7:0]                        :
                      i_barrel_shift_amount_sel == 2'd2 ? {3'd0, i_imm_shift_amount    } :
                                                          {3'd0, i_read_data_alignment } ;

// ========================================================
// Barrel Shift Data Select
// ========================================================
assign barrel_shift_in = i_barrel_shift_data_sel == 2'd0 ? i_imm32       :
                         i_barrel_shift_data_sel == 2'd1 ? i_read_data   :
                                                           rm            ;
                            
// ========================================================
// Address Select
// ========================================================

// If rd is the pc, then seperate the address bits from the status bits for
// generating the next address to fetch
assign alu_out_pc_filtered = pc_wen && i_pc_sel == 2'd1 ? pcf(alu_out) : alu_out;


assign branch_address_nxt = (!execute) ? pc_minus4 : alu_out_pc_filtered;

// if current instruction does not execute because it does not meet the condition
// then address advances to next instruction
assign o_address_nxt = (i_address_sel == 4'd0) ? pc_plus4              :
                       (i_address_sel == 4'd1) ? alu_out_pc_filtered   :
                       (i_address_sel == 4'd3) ? pc                    :
                       (i_address_sel == 4'd4) ? rn                    :
                       (i_address_sel == 4'd5) ? address_plus4         :  // MTRANS address incrementer
                       (i_address_sel == 4'd6) ? alu_plus4             :  // MTRANS decrement after
                       (i_address_sel == 4'd7) ? rn_plus4              :  // MTRANS increment before
                                                 branch_address_nxt    ;

// ========================================================
// Program Counter Select
// ========================================================

assign branch_pc_nxt = (!execute) ? pc_minus4 : alu_out;

// If current instruction does not execute because it does not meet the condition
// then PC advances to next instruction
assign pc_nxt = i_pc_sel == 2'd0 ? pc_plus4              :
                i_pc_sel == 2'd1 ? alu_out               :
                                   branch_pc_nxt         ;


// ========================================================
// Register Write Select
// ========================================================
wire [31:0] save_int_pc_m4;

assign save_int_pc_m4 = { status_bits_flags, 
                          1'b1, 
                          1'b1, 
                          pc_minus4[25:2], 
                          2'b0      };

assign reg_write_nxt = i_reg_write_sel == 3'd0 ? alu_out               :
                       // save pc to lr on an interrupt                    
                       i_reg_write_sel == 3'd1 ? save_int_pc_m4        :
                                                 multiply_out          ;  


// ========================================================
// Byte Enable Select
// ========================================================
assign byte_enable_nxt = i_byte_enable_sel == 2'd0  ? 4'b1111 :  // word write
                         i_byte_enable_sel == 2'd2  ?            // halfword write, never happen
                         ( o_address_nxt[1] == 1'd0 ? 4'b0011 : 
                                                      4'b1100  ) :
                           
                         o_address_nxt[1:0] == 2'd0 ? 4'b0001 :  // byte write
                         o_address_nxt[1:0] == 2'd1 ? 4'b0010 :
                         o_address_nxt[1:0] == 2'd2 ? 4'b0100 :
                                                      4'b1000 ;


// ========================================================
// Write Data Select
// ========================================================
assign write_data_nxt = i_byte_enable_sel == 2'd0 ? rd            :
                                                    {4{rd[ 7:0]}} ;


// ========================================================
// Conditional Execution
// ========================================================
assign execute = conditional_execute ( i_condition, status_bits_flags );
            
// allow the PC to increment to the next instruction when current
// instruction does not execute
assign pc_wen       = i_pc_wen ;//|| !execute;

// only update register bank if current instruction executes
assign reg_bank_wen = {{15{execute}} & i_reg_bank_wen};

// ========================================================
// Write Enable
// ========================================================
// This must be de-asserted when execute is fault
assign write_enable_nxt = execute && i_write_data_wen;


// ========================================================
// Register Update
// ========================================================

assign status_bits_flags_update        = execute && i_status_bits_flags_wen;

always @( posedge i_clk or posedge i_rst)
    if(i_rst) begin
      o_write_enable          <= 'd0;
      o_write_data            <= 'd0;
      address_r               <= 'd0;
      o_byte_enable           <= 'd0;
      status_bits_flags       <= 'd0;
    end else begin
      o_write_enable          <= write_enable_nxt;
      o_write_data            <= write_data_nxt; 
      address_r               <= o_address_nxt;
      o_byte_enable           <= byte_enable_nxt;
      status_bits_flags       <= status_bits_flags_update       ? status_bits_flags_nxt        : status_bits_flags;
    end

assign o_address = address_r;


// ========================================================
// Instantiate Barrel Shift
// ========================================================

assign carry_in = i_use_carry_in ? status_bits_flags[1] : 1'd0;

a23_barrel_shift u_barrel_shift  (
    .i_in             ( barrel_shift_in           ),
    .i_carry_in       ( carry_in                  ),
    .i_shift_amount   ( shift_amount              ),
    .i_function       ( i_barrel_shift_function   ),
    .o_out            ( barrel_shift_out          ),
    .o_carry_out      ( barrel_shift_carry        )
    );



// ========================================================
// Instantiate ALU
// ========================================================
assign barrel_shift_carry_alu =  i_barrel_shift_data_sel == 2'd0 ? 
                                  (i_imm_shift_amount[4:1] == 0 ? status_bits_flags[1] : i_imm32[31]) : 
                                   barrel_shift_carry;

a23_alu u_alu (
    .i_a_in                  ( rn                      ),
    .i_b_in                  ( barrel_shift_out        ),
    .i_barrel_shift_carry    ( barrel_shift_carry_alu  ),
    .i_status_bits_carry     ( status_bits_flags[1]    ),
    .i_function              ( i_alu_function          ),
    .o_out                   ( alu_out                 ),
    .o_flags                 ( alu_flags               )
    );

// ========================================================
// Instantiate Booth 64-bit Multiplier-Accumulator
// ========================================================
a23_multiply u_multiply (
    .i_clk          ( i_clk                 ),
    .i_rst          ( i_rst                 ),
    .i_a_in         ( rs                    ),
    .i_b_in         ( rm                    ),
    .i_function     ( i_multiply_function   ),
    .i_execute      ( execute               ),
    .o_out          ( multiply_out          ),
    .o_flags        ( multiply_flags        ),  // [1] = N, [0] = Z
    .o_done         ( o_multiply_done       )
    );


// ========================================================
// Instantiate Register Bank
// ========================================================
a23_register_bank u_register_bank(
    .i_clk                   ( i_clk                     ),
    .i_rst                   ( i_rst                     ),
    .i_rm_sel                ( i_rm_sel                  ),
    .i_rds_sel               ( i_rds_sel                 ),
    .i_rn_sel                ( i_rn_sel                  ),
    .i_pc_wen                ( pc_wen                    ),
    .i_reg_bank_wen          ( reg_bank_wen              ),
    .i_pc                    ( pc_nxt[25:2]              ),
    .i_reg                   ( reg_write_nxt             ),
    .i_status_bits_flags     ( status_bits_flags         ),
    .o_rm                    ( rm                        ),
    .o_rs                    ( rs                        ),
    .o_rd                    ( rd                        ),
    .o_rn                    ( rn                        ),
    .o_pc                    ( pc                        )
    );

endmodule

//////////////////////////////////////////////////////////////////
//                                                              //
//  Fetch - Instantiates the fetch stage sub-modules of         //
//  the Amber 2 Core                                            //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Instantiates the Cache and Wishbone I/F                     //
//  Also contains a little bit of logic to decode memory        //
//  accesses to decide if they are cached or not                //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////


module a23_fetch
(
input                       i_clk,
input                       i_rst,

input       [31:0]          i_address,
input       [31:0]          i_address_nxt,      // un-registered version of address to the cache rams
input       [31:0]          i_write_data,
input                       i_write_enable,
output       [31:0]         o_read_data,
input       [3:0]           i_byte_enable,
input                       i_cache_enable,     // cache enable
input                       i_cache_flush,      // cache flush
input       [31:0]          i_cacheable_area,   // each bit corresponds to 2MB address space
output   [31:0]             o_m_address, //memory
output   [31:0]             o_m_write,
output                      o_m_write_en,
output   [3:0]              o_m_byte_enable,
input    [31:0]             i_m_read
);

assign o_m_address     = i_address;
assign o_m_write       = i_write_data;
assign o_m_write_en    = i_write_enable;
assign o_m_byte_enable = i_byte_enable;
assign o_read_data     = i_m_read;

endmodule
module a23_gc_main
#(
  // mem size in words (32bit)
  parameter CODE_MEM_SIZE  = 64  ,   //Code:    0x00000000
  parameter G_MEM_SIZE     = 64  ,   //AdrGarbler: 0x01000000
  parameter E_MEM_SIZE     = 64  ,   //AdrEvaluator:   0x02000000
  parameter OUT_MEM_SIZE   = 64  ,   //AdrOut:   0x03000000
  parameter STACK_MEM_SIZE = 64      //AdrStack:  0x04000000
)
(
  input                           clk,
  input                           rst,
  input  [CODE_MEM_SIZE*32-1:0]   p_init,
  input  [G_MEM_SIZE   *32-1:0]   g_init,
  input  [E_MEM_SIZE   *32-1:0]   e_init,
  output [OUT_MEM_SIZE *32-1:0]   o,
  output                          terminate
);

wire   [31:0]             m_address;
wire   [31:0]             m_write;
wire                      m_write_en;
wire   [3:0]              m_byte_enable;
wire   [31:0]             m_read;

a23_core u_a23_core
(
  .i_clk             (clk               ),
  .i_rst             (rst               ),
  .o_m_address       (m_address         ),
  .o_m_write         (m_write           ),
  .o_m_write_en      (m_write_en        ),
  .o_m_byte_enable   (m_byte_enable     ),
  .i_m_read          (m_read            ),
  .terminate         (terminate         )
);

a23_mem
#(
  .CODE_MEM_SIZE     (CODE_MEM_SIZE),
  .G_MEM_SIZE        (G_MEM_SIZE),
  .E_MEM_SIZE        (E_MEM_SIZE),
  .OUT_MEM_SIZE      (OUT_MEM_SIZE),
  .STACK_MEM_SIZE    (STACK_MEM_SIZE)
)
u_a23_mem
(
  .i_clk              (clk              ),
  .i_rst              (rst              ),

  .p_init             (p_init           ),
  .g_init             (g_init           ),
  .e_init             (e_init           ),
  .o                  (o                ),

  .i_m_address        (m_address        ),
  .i_m_write          (m_write          ),
  .i_m_write_en       (m_write_en       ),
  .i_m_byte_enable    (m_byte_enable    ),
  .o_m_read           (m_read           )
);




endmodule
module a23_mem
#
(
  // mem size in words (32bit)
  parameter CODE_MEM_SIZE  = 64  ,   //Code:    0x00000000
  parameter G_MEM_SIZE     = 64  ,   //AdrGarbler: 0x01000000
  parameter E_MEM_SIZE     = 64  ,   //AdrEvaluator:   0x02000000
  parameter OUT_MEM_SIZE   = 64  ,   //AdrOut:   0x03000000
  parameter STACK_MEM_SIZE = 64      //AdrStack:  0x04000000
)
(
input                           i_clk,
input                           i_rst,

input  [CODE_MEM_SIZE*32-1:0]   p_init,
input  [G_MEM_SIZE   *32-1:0]   g_init,
input  [E_MEM_SIZE   *32-1:0]   e_init,
output [OUT_MEM_SIZE *32-1:0]   o,

input   [31:0]                  i_m_address,
input   [31:0]                  i_m_write,
input                           i_m_write_en,
input   [3:0]                   i_m_byte_enable,
output  [31:0]                  o_m_read
);

reg [7:0]  p_mem     [4*CODE_MEM_SIZE-1:0];
reg [7:0]  g_mem     [4*G_MEM_SIZE-1:0];
reg [7:0]  e_mem     [4*E_MEM_SIZE-1:0];
reg [7:0]  out_mem   [4*OUT_MEM_SIZE-1:0];
reg [7:0]  stack_mem [4*STACK_MEM_SIZE-1:0];

genvar gi;


// instruction memory
wire [7:0]  p_init_byte [4*CODE_MEM_SIZE-1:0];
wire [7:0]  g_init_byte [4*G_MEM_SIZE-1:0];
wire [7:0]  e_init_byte [4*E_MEM_SIZE-1:0];
generate
  for (gi = 0; gi < 4*CODE_MEM_SIZE; gi = gi + 1) begin:code_gen
    assign p_init_byte[gi] = p_init[8*(gi+1)-1:8*gi];
  end
  for (gi = 0; gi < 4*G_MEM_SIZE; gi = gi + 1)begin: g_gen
    assign g_init_byte[gi] = g_init[8*(gi+1)-1:8*gi];
  end
  for (gi = 0; gi < 4*E_MEM_SIZE; gi = gi + 1)begin: e_gen
    assign e_init_byte[gi] = e_init[8*(gi+1)-1:8*gi];
  end
  for (gi = 0; gi < 4*OUT_MEM_SIZE; gi = gi + 1) begin:out_gen
    assign o[8*(gi+1)-1:8*gi] = out_mem[gi];
  end
endgenerate


wire [23:0] trunc_m_address;
assign trunc_m_address = {i_m_address[23:2], 2'b0};

assign  o_m_read =  (i_m_address[31:24] == 8'h00) ? {p_mem[trunc_m_address+3], p_mem[trunc_m_address+2], p_mem[trunc_m_address+1], p_mem[trunc_m_address]}  ://Code:  0x00000000
                    (i_m_address[31:24] == 8'h01) ? {g_mem[trunc_m_address+3], g_mem[trunc_m_address+2], g_mem[trunc_m_address+1], g_mem[trunc_m_address]}  ://AdrGarbler: 0x01000000
                    (i_m_address[31:24] == 8'h02) ? {e_mem[trunc_m_address+3], e_mem[trunc_m_address+2], e_mem[trunc_m_address+1], e_mem[trunc_m_address]}  ://AdrEvaluator:   0x02000000
                    (i_m_address[31:24] == 8'h03) ? {out_mem[trunc_m_address+3], out_mem[trunc_m_address+2], out_mem[trunc_m_address+1], out_mem[trunc_m_address]}  ://AdrOut:   0x03000000
                    (i_m_address[31:24] == 8'h04) ? {stack_mem[trunc_m_address+3], stack_mem[trunc_m_address+2], stack_mem[trunc_m_address+1], stack_mem[trunc_m_address]}  ://AdrStack:  0x04000000
                                                     32'b0;

integer i;
always @(posedge i_clk or posedge i_rst) begin
  if (i_rst) begin
    for(i=0;i<4*CODE_MEM_SIZE;i=i+1) begin
      p_mem[i] <= p_init_byte[i];
    end
    for(i=0;i<4*G_MEM_SIZE;i=i+1) begin
      g_mem[i] <= g_init_byte[i];
    end
    for(i=0;i<4*E_MEM_SIZE;i=i+1) begin
      e_mem[i] <= e_init_byte[i];
    end
    for(i=0;i<4*OUT_MEM_SIZE;i=i+1) begin
      out_mem[i] <= 8'b0;
    end
    for(i=0;i<4*STACK_MEM_SIZE;i=i+1) begin
      stack_mem[i] <= 8'b0;
    end
  end else begin
    for(i=0;i<4*CODE_MEM_SIZE;i=i+1) begin
      p_mem[i] <= p_mem[i];
    end
    for(i=0;i<4*G_MEM_SIZE;i=i+1) begin
      g_mem[i] <= g_mem[i];
    end
    for(i=0;i<4*E_MEM_SIZE;i=i+1) begin
      e_mem[i] <= e_mem[i];
    end
    for(i=0;i<4*OUT_MEM_SIZE;i=i+1) begin
      out_mem[i] <= out_mem[i];
    end
    for(i=0;i<4*STACK_MEM_SIZE;i=i+1) begin
      stack_mem[i] <= stack_mem[i];
    end
    if (i_m_write_en) begin // AdrGarbler and AdrEvaluator are const
      if(i_m_address[31:24] == 8'h00) begin //Code: 0x00000000
        case(i_m_byte_enable)
        4'b1111: begin
          p_mem[trunc_m_address+3] <= i_m_write[31:24];
          p_mem[trunc_m_address+2] <= i_m_write[23:16];
          p_mem[trunc_m_address+1] <= i_m_write[15:8];
          p_mem[trunc_m_address+0] <= i_m_write[7:0];
        end
        4'b0001: begin
          p_mem[trunc_m_address+0] <= i_m_write[7:0];
        end
        4'b0010: begin
          p_mem[trunc_m_address+1] <= i_m_write[7:0];
        end
        4'b0100: begin
          p_mem[trunc_m_address+2] <= i_m_write[7:0];
        end
        4'b1000: begin
          p_mem[trunc_m_address+3] <= i_m_write[7:0];
        end
        endcase
      end else if(i_m_address[31:24] == 8'h03) begin //AdrOut: 0x03000000
        case(i_m_byte_enable)
        4'b1111: begin
          out_mem[trunc_m_address+3] <= i_m_write[31:24];
          out_mem[trunc_m_address+2] <= i_m_write[23:16];
          out_mem[trunc_m_address+1] <= i_m_write[15:8];
          out_mem[trunc_m_address+0] <= i_m_write[7:0];
        end
        4'b0001: begin
          out_mem[trunc_m_address+0] <= i_m_write[7:0];
        end
        4'b0010: begin
          out_mem[trunc_m_address+1] <= i_m_write[7:0];
        end
        4'b0100: begin
          out_mem[trunc_m_address+2] <= i_m_write[7:0];
        end
        4'b1000: begin
          out_mem[trunc_m_address+3] <= i_m_write[7:0];
        end
        endcase
      end else if (i_m_address[31:24] == 8'h04) begin //AdrStack: 0x04000000
        case(i_m_byte_enable)
        4'b1111: begin
          stack_mem[trunc_m_address+3] <= i_m_write[31:24];
          stack_mem[trunc_m_address+2] <= i_m_write[23:16];
          stack_mem[trunc_m_address+1] <= i_m_write[15:8];
          stack_mem[trunc_m_address+0] <= i_m_write[7:0];
        end
        4'b0001: begin
          stack_mem[trunc_m_address+0] <= i_m_write[7:0];
        end
        4'b0010: begin
          stack_mem[trunc_m_address+1] <= i_m_write[7:0];
        end
        4'b0100: begin
          stack_mem[trunc_m_address+2] <= i_m_write[7:0];
        end
        4'b1000: begin
          stack_mem[trunc_m_address+3] <= i_m_write[7:0];
        end
        endcase
      end
    end
  end
end


endmodule


//////////////////////////////////////////////////////////////////
//                                                              //
//  Multiplication Module for Amber 2 Core                      //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  64-bit Booth signed or unsigned multiply and                //
//  multiply-accumulate supported. It takes about 38 clock      //
//  cycles to complete an operation.                            //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////



// bit 0 go, bit 1 accumulate
// Command:
//  4'b01 :  MUL   - 32 bit multiplication
//  4'b11 :  MLA   - 32 bit multiply and accumulate
//
//  34-bit Booth adder
//  The adder needs to be 34 bit to deal with signed and unsigned 32-bit
//  multiplication inputs. This adds 1 extra bit. Then to deal with the
//  case of two max negative numbers another bit is required.
//

module a23_multiply (
input                       i_clk,
input                       i_rst,

input       [31:0]          i_a_in,         // Rds
input       [31:0]          i_b_in,         // Rm
input       [1:0]           i_function,
input                       i_execute,

output      [31:0]          o_out,
output      [1:0]           o_flags,        // [1] = N, [0] = Z
output                      o_done    // goes high 2 cycles before completion                                          
);


wire        enable;
wire        accumulate;

reg  [31:0] product;
reg  [3:0]  count;

assign enable         = i_function[0];
assign accumulate     = i_function[1];

assign o_out   = product;

assign o_flags = {o_out[31], o_out == 32'd0 }; 
assign o_done  = 1'b1;


always @(posedge i_clk or posedge i_rst) begin
  if (i_rst) begin
    product <= 32'b0;
    count <= 4'b0;
  end else if(enable) begin
    count <= count + 1;
    if (i_execute && count == 0) begin
      product <= i_a_in*i_b_in;
    end else if (i_execute && accumulate && count == 3) begin
      product <= product + i_a_in;
    end
  end else begin
    product <= 32'b0;
    count <= 4'b0;
  end
end

// wire [33:0] multiplier;
// wire [33:0] multiplier_bar;
// wire [33:0] sum;
// wire [33:0] sum34_b;

// reg  [5:0]  count;
// reg  [5:0]  count_nxt;
// reg  [67:0] product;
// reg  [67:0] product_nxt;
// reg  [1:0]  flags_nxt;
// wire [32:0] sum_acc1;           // the MSB is the carry out for the upper 32 bit addition
// assign multiplier     =  { 2'd0, i_a_in} ;
// assign multiplier_bar = ~{ 2'd0, i_a_in} + 34'd1 ;

// assign sum34_b        =  product[1:0] == 2'b01 ? multiplier     :
//                          product[1:0] == 2'b10 ? multiplier_bar :
//                                                  34'd0          ;


// // -----------------------------------
// // 34-bit adder - booth multiplication
// // -----------------------------------
// assign sum =  product[67:34] + sum34_b;
 
// // ------------------------------------
// // 33-bit adder - accumulate operations
// // ------------------------------------
// assign sum_acc1 = {1'd0, product[32:1]} + {1'd0, i_a_in};


// always @*
// begin
//   // Defaults
//   count_nxt           = count;
//   product_nxt         = product;
  
//   // update Negative and Zero flags
//   // Use registered value of product so this adds an extra cycle
//   // but this avoids having the 64-bit zero comparator on the
//   // main adder path
//   flags_nxt   = { product[32], product[32:1] == 32'd0 }; 
    

//   if ( count == 6'd0 )
//     product_nxt = {33'd0, 1'd0, i_b_in, 1'd0 } ;
//   else if ( count <= 6'd33 )
//     product_nxt = { sum[33], sum, product[33:1]} ;
//   else if ( count == 6'd34 && accumulate )
//   begin
//     // Note that bit 0 is not part of the product. It is used during the booth
//     // multiplication algorithm
//     product_nxt         = { product[64:33], sum_acc1[31:0], 1'd0}; // Accumulate
//   end
        
//   // Multiplication state counter
//   if (count == 6'd0)  // start
//     count_nxt   = enable ? 6'd1 : 6'd0;
//   else if ((count == 6'd34 && !accumulate) ||  // MUL
//            (count == 6'd35 &&  accumulate)  )  // MLA
//     count_nxt   = 6'd0;
//   else
//     count_nxt   = count + 1'd1;

// end


//   always @ ( posedge i_clk or posedge i_rst)
//   if (i_rst) begin
//     product         <= 'd0;
//     count           <= 'd0;
//     o_done          <= 'd0;
//   end else if (enable)
//   begin 
//     if(i_execute) begin
//           product         <= product_nxt;
//     end
//     count           <= count_nxt;
//     o_done          <= count == 6'd31;
//   end

// Outputs
// assign o_out   = product[32:1]; 
// assign o_flags = flags_nxt;
                     
endmodule

//////////////////////////////////////////////////////////////////
//                                                              //
//  Register Bank for Amber Core                                //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Contains 37 32-bit registers, 16 of which are visible       //
//  ina any one operating mode. Registers use real flipflops,   //
//  rather than SRAM. This makes sense for an FPGA              //
//  implementation, where flipflops are plentiful.              //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////

module a23_register_bank (

input                       i_clk,
input                       i_rst,
input       [3:0]           i_rm_sel,
input       [3:0]           i_rds_sel,
input       [3:0]           i_rn_sel,

input                       i_pc_wen,
input       [14:0]          i_reg_bank_wen,

input       [23:0]          i_pc,                   // program counter [25:2]
input       [31:0]          i_reg,

input       [3:0]           i_status_bits_flags,

output      [31:0]          o_rm,
output reg  [31:0]          o_rs,
output reg  [31:0]          o_rd,
output      [31:0]          o_rn,
output      [31:0]          o_pc

);

`include "a23_localparams.vh"
`include "a23_functions.vh"


reg  [31:0] r0  ;
reg  [31:0] r1  ;
reg  [31:0] r2  ;
reg  [31:0] r3  ;
reg  [31:0] r4  ;
reg  [31:0] r5  ;
reg  [31:0] r6  ;
reg  [31:0] r7  ;
reg  [31:0] r8  ;
reg  [31:0] r9  ;
reg  [31:0] r10 ;
reg  [31:0] r11 ;
reg  [31:0] r12 ;
reg  [31:0] r13 ;
reg  [31:0] r14 ;
reg  [23:0] r15 ;

wire  [31:0] r0_out;
wire  [31:0] r1_out;
wire  [31:0] r2_out;
wire  [31:0] r3_out;
wire  [31:0] r4_out;
wire  [31:0] r5_out;
wire  [31:0] r6_out;
wire  [31:0] r7_out;
wire  [31:0] r8_out;
wire  [31:0] r9_out;
wire  [31:0] r10_out;
wire  [31:0] r11_out;
wire  [31:0] r12_out;
wire  [31:0] r13_out;
wire  [31:0] r14_out;
wire  [31:0] r15_out_rm;
wire  [31:0] r15_out_rm_nxt;
wire  [31:0] r15_out_rn;

wire  [31:0] r8_rds;
wire  [31:0] r9_rds;
wire  [31:0] r10_rds;
wire  [31:0] r11_rds;
wire  [31:0] r12_rds;
wire  [31:0] r13_rds;
wire  [31:0] r14_rds;


// ========================================================
// Register Update
// ========================================================
always @ ( posedge i_clk or posedge i_rst)
  if (i_rst) begin
      r0       <= 'd0;
      r1       <= 'd0;
      r2       <= 'd0;
      r3       <= 'd0;
      r4       <= 'd0;
      r5       <= 'd0;
      r6       <= 'd0;
      r7       <= 'd0;
      r8       <= 'd0;
      r9       <= 'd0;
      r10      <= 'd0;
      r11      <= 'd0;
      r12      <= 'd0;
      r13      <= 'd0;
      r14      <= 'd0;
      r15      <= 24'h0;
  end else begin
      r0       <=  i_reg_bank_wen[0 ]              ? i_reg : r0;  
      r1       <=  i_reg_bank_wen[1 ]              ? i_reg : r1;  
      r2       <=  i_reg_bank_wen[2 ]              ? i_reg : r2;  
      r3       <=  i_reg_bank_wen[3 ]              ? i_reg : r3;  
      r4       <=  i_reg_bank_wen[4 ]              ? i_reg : r4;  
      r5       <=  i_reg_bank_wen[5 ]              ? i_reg : r5;  
      r6       <=  i_reg_bank_wen[6 ]              ? i_reg : r6;  
      r7       <=  i_reg_bank_wen[7 ]              ? i_reg : r7;  
      r8       <=  i_reg_bank_wen[8 ]              ? i_reg : r8;  
      r9       <=  i_reg_bank_wen[9 ]              ? i_reg : r9;  
      r10      <=  i_reg_bank_wen[10]              ? i_reg : r10; 
      r11      <=  i_reg_bank_wen[11]              ? i_reg : r11; 
      r12      <=  i_reg_bank_wen[12]              ? i_reg : r12; 
      r13      <=  i_reg_bank_wen[13]              ? i_reg : r13;
      r14      <=  i_reg_bank_wen[14]              ? i_reg : r14;
      r15      <=  i_pc_wen                        ?  i_pc : r15;
  end
    
    
// ========================================================
// Register Read based on Mode
// ========================================================
assign r0_out = r0;
assign r1_out = r1;
assign r2_out = r2;
assign r3_out = r3;
assign r4_out = r4;
assign r5_out = r5;
assign r6_out = r6;
assign r7_out = r7;
assign r8_out  = r8;
assign r9_out  = r9;
assign r10_out = r10;
assign r11_out = r11;
assign r12_out = r12;
assign r13_out = r13; 
assign r14_out = r14;


assign r15_out_rm     = { i_status_bits_flags, 
                          1'b1, 
                          1'b1, 
                          r15, 
                          2'b0};

assign r15_out_rm_nxt = { i_status_bits_flags, 
                          1'b1, 
                          1'b1, 
                          i_pc, 
                          2'b0};
                      
assign r15_out_rn     = {6'd0, r15, 2'd0};


// rds outputs
assign r8_rds  = r8;
assign r9_rds  = r9;
assign r10_rds = r10;
assign r11_rds = r11;
assign r12_rds = r12;
assign r13_rds = r13;
assign r14_rds = r14;

// ========================================================
// Program Counter out
// ========================================================
assign o_pc = r15_out_rn;

// ========================================================
// Rm Selector
// ========================================================
assign o_rm = i_rm_sel == 4'd0  ? r0_out  :
              i_rm_sel == 4'd1  ? r1_out  : 
              i_rm_sel == 4'd2  ? r2_out  : 
              i_rm_sel == 4'd3  ? r3_out  : 
              i_rm_sel == 4'd4  ? r4_out  : 
              i_rm_sel == 4'd5  ? r5_out  : 
              i_rm_sel == 4'd6  ? r6_out  : 
              i_rm_sel == 4'd7  ? r7_out  : 
              i_rm_sel == 4'd8  ? r8_out  : 
              i_rm_sel == 4'd9  ? r9_out  : 
              i_rm_sel == 4'd10 ? r10_out : 
              i_rm_sel == 4'd11 ? r11_out : 
              i_rm_sel == 4'd12 ? r12_out : 
              i_rm_sel == 4'd13 ? r13_out : 
              i_rm_sel == 4'd14 ? r14_out : 
                                  r15_out_rm ; 




// ========================================================
// Rds Selector
// ========================================================
always @*
    case (i_rds_sel)
       4'd0  :  o_rs = r0_out  ;
       4'd1  :  o_rs = r1_out  ; 
       4'd2  :  o_rs = r2_out  ; 
       4'd3  :  o_rs = r3_out  ; 
       4'd4  :  o_rs = r4_out  ; 
       4'd5  :  o_rs = r5_out  ; 
       4'd6  :  o_rs = r6_out  ; 
       4'd7  :  o_rs = r7_out  ; 
       4'd8  :  o_rs = r8_rds  ; 
       4'd9  :  o_rs = r9_rds  ; 
       4'd10 :  o_rs = r10_rds ; 
       4'd11 :  o_rs = r11_rds ; 
       4'd12 :  o_rs = r12_rds ; 
       4'd13 :  o_rs = r13_rds ; 
       4'd14 :  o_rs = r14_rds ; 
       default: o_rs = r15_out_rn ; 
    endcase

                                    

// ========================================================
// Rd Selector
// ========================================================
always @*
    case (i_rds_sel)
       4'd0  :  o_rd = r0_out  ;
       4'd1  :  o_rd = r1_out  ; 
       4'd2  :  o_rd = r2_out  ; 
       4'd3  :  o_rd = r3_out  ; 
       4'd4  :  o_rd = r4_out  ; 
       4'd5  :  o_rd = r5_out  ; 
       4'd6  :  o_rd = r6_out  ; 
       4'd7  :  o_rd = r7_out  ; 
       4'd8  :  o_rd = r8_rds  ; 
       4'd9  :  o_rd = r9_rds  ; 
       4'd10 :  o_rd = r10_rds ; 
       4'd11 :  o_rd = r11_rds ; 
       4'd12 :  o_rd = r12_rds ; 
       4'd13 :  o_rd = r13_rds ; 
       4'd14 :  o_rd = r14_rds ; 
       default: o_rd = r15_out_rm_nxt ; 
    endcase

                                    
// ========================================================
// Rn Selector
// ========================================================
assign o_rn = i_rn_sel == 4'd0  ? r0_out  :
              i_rn_sel == 4'd1  ? r1_out  : 
              i_rn_sel == 4'd2  ? r2_out  : 
              i_rn_sel == 4'd3  ? r3_out  : 
              i_rn_sel == 4'd4  ? r4_out  : 
              i_rn_sel == 4'd5  ? r5_out  : 
              i_rn_sel == 4'd6  ? r6_out  : 
              i_rn_sel == 4'd7  ? r7_out  : 
              i_rn_sel == 4'd8  ? r8_out  : 
              i_rn_sel == 4'd9  ? r9_out  : 
              i_rn_sel == 4'd10 ? r10_out : 
              i_rn_sel == 4'd11 ? r11_out : 
              i_rn_sel == 4'd12 ? r12_out : 
              i_rn_sel == 4'd13 ? r13_out : 
              i_rn_sel == 4'd14 ? r14_out : 
                                  r15_out_rn ; 


endmodule







