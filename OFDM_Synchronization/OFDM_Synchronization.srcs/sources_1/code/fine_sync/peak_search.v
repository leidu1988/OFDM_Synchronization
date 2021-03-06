`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/01/16 20:29:12
// Design Name: 
// Module Name: peak_search
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module peak_search #(
	parameter LAMBDA_WIDTH   = 71, // <=71
	parameter RAM_ADDR_WIDTH = 10
	)
	(
	axis_aclk          ,
	axis_areset        ,
	
	i_work_ctrl_en     ,
	i_work_ctrl        ,
	
	i_lambda_data_valid,
	i_lambda_data_32   ,
	i_lambda_data_31   ,
	i_lambda_data_30   ,
	i_lambda_data_29   ,
	i_lambda_data_28   ,
	i_lambda_data_27   ,
	i_lambda_data_26   ,
	i_lambda_data_25   ,
	i_lambda_data_24   ,
	i_lambda_data_23   ,
	i_lambda_data_22   ,
	i_lambda_data_21   ,
	i_lambda_data_20   ,
	i_lambda_data_19   ,
	i_lambda_data_18   ,
	i_lambda_data_17   ,
	i_lambda_data_16   ,
	i_lambda_data_15   ,
	i_lambda_data_14   ,
	i_lambda_data_13   ,
	i_lambda_data_12   ,
	i_lambda_data_11   ,
	i_lambda_data_10   ,
	i_lambda_data_9    ,
	i_lambda_data_8    ,
	i_lambda_data_7    ,
	i_lambda_data_6    ,
	i_lambda_data_5    ,
	i_lambda_data_4    ,
	i_lambda_data_3    ,
	i_lambda_data_2    ,
	i_lambda_data_1    ,
	i_lambda_data_addr ,
	
	o_fine_sync_ok     ,
	o_channel_length   ,
	o_cp_start_addr 
	);
	input                axis_aclk          ;
	input                axis_areset        ;
	
	input                i_work_ctrl_en     ;
	input                i_work_ctrl        ; // 1'b0: 停止工作；1'b1: 开始工作
	
	input                i_lambda_data_valid;
	input  signed [70:0] i_lambda_data_32   ;
	input  signed [70:0] i_lambda_data_31   ;
	input  signed [70:0] i_lambda_data_30   ;
	input  signed [70:0] i_lambda_data_29   ;
	input  signed [70:0] i_lambda_data_28   ;
	input  signed [70:0] i_lambda_data_27   ;
	input  signed [70:0] i_lambda_data_26   ;
	input  signed [70:0] i_lambda_data_25   ;
	input  signed [70:0] i_lambda_data_24   ;
	input  signed [70:0] i_lambda_data_23   ;
	input  signed [70:0] i_lambda_data_22   ;
	input  signed [70:0] i_lambda_data_21   ;
	input  signed [70:0] i_lambda_data_20   ;
	input  signed [70:0] i_lambda_data_19   ;
	input  signed [70:0] i_lambda_data_18   ;
	input  signed [70:0] i_lambda_data_17   ;
	input  signed [70:0] i_lambda_data_16   ;
	input  signed [70:0] i_lambda_data_15   ;
	input  signed [70:0] i_lambda_data_14   ;
	input  signed [70:0] i_lambda_data_13   ;
	input  signed [70:0] i_lambda_data_12   ;
	input  signed [70:0] i_lambda_data_11   ;
	input  signed [70:0] i_lambda_data_10   ;
	input  signed [70:0] i_lambda_data_9    ;
	input  signed [70:0] i_lambda_data_8    ;
	input  signed [70:0] i_lambda_data_7    ;
	input  signed [70:0] i_lambda_data_6    ;
	input  signed [70:0] i_lambda_data_5    ;
	input  signed [70:0] i_lambda_data_4    ;
	input  signed [70:0] i_lambda_data_3    ;
	input  signed [70:0] i_lambda_data_2    ;
	input  signed [70:0] i_lambda_data_1    ;
	input         [15:0] i_lambda_data_addr ;
	
	output               o_fine_sync_ok     ;
	output        [4:0]  o_channel_length   ;
	output        [15:0] o_cp_start_addr    ;
	
//================================================================================
// variable
//================================================================================
	// state
	localparam IDLE    = 3'd0,
	           SEARCH  = 3'd3,
	           CONFIRM = 3'd6;
	
	reg        [2:0]                state      ;
	reg        [2:0]                state_dly1 ;
	reg        [7:0]                search_cnt ;
	reg        [2:0]                confirm_cnt;
	
	reg        [11:0]               i_lambda_data_valid_buf;
	
	reg signed [LAMBDA_WIDTH-1:0]   i_lambda_data_buf[0:31];
	
	reg signed [LAMBDA_WIDTH:0]     lambda_data_diff[0:15];
	reg signed [LAMBDA_WIDTH-1:0]   data_2_max[0:15]      ;
	reg                             data_2_max_y[0:15]    ;
	
	reg signed [LAMBDA_WIDTH:0]     data_2_max_diff[0:7]  ;
	reg signed [LAMBDA_WIDTH-1:0]   data_4_max[0:7]       ;
	reg        [1:0]                data_4_max_y[0:7]     ;
	
	reg signed [LAMBDA_WIDTH:0]     data_4_max_diff[0:3]  ;
	reg signed [LAMBDA_WIDTH-1:0]   data_8_max[0:3]       ;
	reg        [2:0]                data_8_max_y[0:3]     ;
	
	reg signed [LAMBDA_WIDTH:0]     data_8_max_diff[0:1]  ;
	reg signed [LAMBDA_WIDTH-1:0]   data_16_max[0:1]      ;
	reg        [3:0]                data_16_max_y[0:1]    ;
	
	reg signed [LAMBDA_WIDTH:0]     data_16_max_diff      ;
	reg signed [LAMBDA_WIDTH-1:0]   data_32_max           ;
	reg        [4:0]                data_32_max_y         ;
	reg        [RAM_ADDR_WIDTH-1:0] data_32_max_addr      ;
	
	reg signed [LAMBDA_WIDTH:0]     data_32_peak_minus_max;
	reg signed [LAMBDA_WIDTH-1:0]   data_32_peak     ;
	reg        [4:0]                data_32_peak_y   ;
	reg        [RAM_ADDR_WIDTH-1:0] data_32_peak_addr;
	
	reg                             fine_sync_ok     ;
	reg        [4:0]                channel_length   ;
	reg        [RAM_ADDR_WIDTH-1:0] cp_start_addr    ;
	
//================================================================================
// state
//================================================================================
	always @(posedge axis_aclk or posedge axis_areset) begin
		if(axis_areset == 1'b1) begin
			state <= IDLE;
		end
		else begin
			case(state)
				IDLE: begin
					if((i_work_ctrl_en==1'b1) && (i_work_ctrl==1'b1)) begin
						state <= SEARCH;
					end
					else begin
						state <= IDLE;
					end
				end
				SEARCH: begin
					if((i_work_ctrl_en==1'b1) && (i_work_ctrl==1'b0)) begin
						state <= IDLE;
					end
					else if(search_cnt >= 8'd195) begin
						state <= CONFIRM;
					end
					else begin
						state <= SEARCH;
					end
				end
				CONFIRM: begin
					if((i_work_ctrl_en==1'b1) && (i_work_ctrl==1'b0)) begin
						state <= IDLE;
					end
					else if(confirm_cnt == 3'd7) begin
						state <= IDLE;
					end
					else begin
						state <= CONFIRM;
					end
				end
				default: begin
					state <= IDLE;
				end
			endcase
		end
	end
	
	always @(posedge axis_aclk or posedge axis_areset) begin
		if(axis_areset == 1'b1) begin
			search_cnt  <= 8'd0;
			confirm_cnt <= 3'd0;
		end
		else begin
			case(state)
				// IDLE: begin
				// end
				SEARCH: begin
					if(i_lambda_data_valid_buf[11] == 1'b1) begin
						search_cnt <= search_cnt + 1'd1;
					end
					else begin
						search_cnt <= search_cnt;
					end
					confirm_cnt <= 3'd0;
				end
				CONFIRM: begin
					search_cnt  <= 8'd0;
					confirm_cnt <= confirm_cnt + 1'd1;
				end
				default: begin
					search_cnt  <= 8'd0;
					confirm_cnt <= 3'd0;
				end
			endcase
		end
	end
	
	always @(posedge axis_aclk or posedge axis_areset) begin
		if(axis_areset == 1'b1) begin
			state_dly1 <= IDLE;
		end
		else begin
			state_dly1 <= state;
		end
	end
	
//================================================================================
// timing
//================================================================================
	always @(posedge axis_aclk or posedge axis_areset) begin
		if(axis_areset == 1'b1) begin
			i_lambda_data_valid_buf <= 12'h000;
		end
		else begin
			case(state)
				// IDLE: begin
				// end
				SEARCH: begin
					// 后面的工作都是由它驱动的
					i_lambda_data_valid_buf <= {i_lambda_data_valid_buf[10:0],i_lambda_data_valid};
				end
				// CONFIRM: begin
				// end
				default: begin
					i_lambda_data_valid_buf <= 12'h000;
				end
			endcase
		end
	end
	
//================================================================================
// y search
//================================================================================
	always @(posedge axis_aclk or posedge axis_areset) begin
		if(axis_areset == 1'b1) begin
			i_lambda_data_buf[0]  <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[1]  <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[2]  <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[3]  <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[4]  <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[5]  <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[6]  <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[7]  <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[8]  <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[9]  <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[10] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[11] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[12] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[13] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[14] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[15] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[16] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[17] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[18] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[19] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[20] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[21] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[22] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[23] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[24] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[25] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[26] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[27] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[28] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[29] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[30] <= {(LAMBDA_WIDTH){1'b1}};
			i_lambda_data_buf[31] <= {(LAMBDA_WIDTH){1'b1}};
		end
		else if(i_lambda_data_valid == 1'b1) begin
			i_lambda_data_buf[0]  <= i_lambda_data_32[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[1]  <= i_lambda_data_31[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[2]  <= i_lambda_data_30[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[3]  <= i_lambda_data_29[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[4]  <= i_lambda_data_28[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[5]  <= i_lambda_data_27[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[6]  <= i_lambda_data_26[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[7]  <= i_lambda_data_25[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[8]  <= i_lambda_data_24[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[9]  <= i_lambda_data_23[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[10] <= i_lambda_data_22[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[11] <= i_lambda_data_21[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[12] <= i_lambda_data_20[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[13] <= i_lambda_data_19[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[14] <= i_lambda_data_18[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[15] <= i_lambda_data_17[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[16] <= i_lambda_data_16[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[17] <= i_lambda_data_15[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[18] <= i_lambda_data_14[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[19] <= i_lambda_data_13[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[20] <= i_lambda_data_12[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[21] <= i_lambda_data_11[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[22] <= i_lambda_data_10[LAMBDA_WIDTH-1:0];
			i_lambda_data_buf[23] <= i_lambda_data_9[LAMBDA_WIDTH-1:0] ;
			i_lambda_data_buf[24] <= i_lambda_data_8[LAMBDA_WIDTH-1:0] ;
			i_lambda_data_buf[25] <= i_lambda_data_7[LAMBDA_WIDTH-1:0] ;
			i_lambda_data_buf[26] <= i_lambda_data_6[LAMBDA_WIDTH-1:0] ;
			i_lambda_data_buf[27] <= i_lambda_data_5[LAMBDA_WIDTH-1:0] ;
			i_lambda_data_buf[28] <= i_lambda_data_4[LAMBDA_WIDTH-1:0] ;
			i_lambda_data_buf[29] <= i_lambda_data_3[LAMBDA_WIDTH-1:0] ;
			i_lambda_data_buf[30] <= i_lambda_data_2[LAMBDA_WIDTH-1:0] ;
			i_lambda_data_buf[31] <= i_lambda_data_1[LAMBDA_WIDTH-1:0] ;
		end
		else begin
			i_lambda_data_buf[0]  <= i_lambda_data_buf[0] ;
			i_lambda_data_buf[1]  <= i_lambda_data_buf[1] ;
			i_lambda_data_buf[2]  <= i_lambda_data_buf[2] ;
			i_lambda_data_buf[3]  <= i_lambda_data_buf[3] ;
			i_lambda_data_buf[4]  <= i_lambda_data_buf[4] ;
			i_lambda_data_buf[5]  <= i_lambda_data_buf[5] ;
			i_lambda_data_buf[6]  <= i_lambda_data_buf[6] ;
			i_lambda_data_buf[7]  <= i_lambda_data_buf[7] ;
			i_lambda_data_buf[8]  <= i_lambda_data_buf[8] ;
			i_lambda_data_buf[9]  <= i_lambda_data_buf[9] ;
			i_lambda_data_buf[10] <= i_lambda_data_buf[10];
			i_lambda_data_buf[11] <= i_lambda_data_buf[11];
			i_lambda_data_buf[12] <= i_lambda_data_buf[12];
			i_lambda_data_buf[13] <= i_lambda_data_buf[13];
			i_lambda_data_buf[14] <= i_lambda_data_buf[14];
			i_lambda_data_buf[15] <= i_lambda_data_buf[15];
			i_lambda_data_buf[16] <= i_lambda_data_buf[16];
			i_lambda_data_buf[17] <= i_lambda_data_buf[17];
			i_lambda_data_buf[18] <= i_lambda_data_buf[18];
			i_lambda_data_buf[19] <= i_lambda_data_buf[19];
			i_lambda_data_buf[20] <= i_lambda_data_buf[20];
			i_lambda_data_buf[21] <= i_lambda_data_buf[21];
			i_lambda_data_buf[22] <= i_lambda_data_buf[22];
			i_lambda_data_buf[23] <= i_lambda_data_buf[23];
			i_lambda_data_buf[24] <= i_lambda_data_buf[24];
			i_lambda_data_buf[25] <= i_lambda_data_buf[25];
			i_lambda_data_buf[26] <= i_lambda_data_buf[26];
			i_lambda_data_buf[27] <= i_lambda_data_buf[27];
			i_lambda_data_buf[28] <= i_lambda_data_buf[28];
			i_lambda_data_buf[29] <= i_lambda_data_buf[29];
			i_lambda_data_buf[30] <= i_lambda_data_buf[30];
			i_lambda_data_buf[31] <= i_lambda_data_buf[31];
		end
	end
	
/* 1/2 */
	genvar i1;
	generate
		for(i1=0; i1<16; i1=i1+1) begin
			always @(posedge axis_aclk or posedge axis_areset) begin
				if(axis_areset == 1'b1) begin
					lambda_data_diff[i1] <= 'd0;
				end
				else if(i_lambda_data_valid_buf[0] == 1'b1) begin
					lambda_data_diff[i1] <= {i_lambda_data_buf[2*i1][LAMBDA_WIDTH-1],i_lambda_data_buf[2*i1]}
					                        - {i_lambda_data_buf[2*i1+1][LAMBDA_WIDTH-1],i_lambda_data_buf[2*i1+1]};
				end
				else begin
					lambda_data_diff[i1] <= lambda_data_diff[i1];
				end
			end
			always @(posedge axis_aclk or posedge axis_areset) begin
				if(axis_areset == 1'b1) begin
					data_2_max[i1]   <= 'd0;
					data_2_max_y[i1] <= 1'b0;
				end
				else if(i_lambda_data_valid_buf[1] == 1'b1) begin
					if(lambda_data_diff[i1][LAMBDA_WIDTH] == 1'b0) begin
						data_2_max[i1]   <= i_lambda_data_buf[2*i1];
						data_2_max_y[i1] <= 1'b0;
					end
					else begin
						data_2_max[i1]   <= i_lambda_data_buf[2*i1+1];
						data_2_max_y[i1] <= 1'b1;
					end
				end
				else begin
					data_2_max[i1]   <= data_2_max[i1];
					data_2_max_y[i1] <= data_2_max_y[i1];
				end
			end
		end
	endgenerate
	
/* 1/4 */
	genvar i2;
	generate
		for(i2=0; i2<8; i2=i2+1) begin
			always @(posedge axis_aclk or posedge axis_areset) begin
				if(axis_areset == 1'b1) begin
					data_2_max_diff[i2] <= 'd0;
				end
				else if(i_lambda_data_valid_buf[2] == 1'b1) begin
					data_2_max_diff[i2] <= {data_2_max[2*i2][LAMBDA_WIDTH-1],data_2_max[2*i2]}
					                       - {data_2_max[2*i2+1][LAMBDA_WIDTH-1],data_2_max[2*i2+1]};
				end
				else begin
					data_2_max_diff[i2] <= data_2_max_diff[i2];
				end
			end
			always @(posedge axis_aclk or posedge axis_areset) begin
				if(axis_areset == 1'b1) begin
					data_4_max[i2]   <= 'd0;
					data_4_max_y[i2] <= 1'b0;
				end
				else if(i_lambda_data_valid_buf[3] == 1'b1) begin
					if(data_2_max_diff[i2][LAMBDA_WIDTH] == 1'b0) begin
						data_4_max[i2]   <= data_2_max[2*i2];
						data_4_max_y[i2] <= {1'b0,data_2_max_y[2*i2]};
					end
					else begin
						data_4_max[i2]   <= data_2_max[2*i2+1];
						data_4_max_y[i2] <= {1'b1,data_2_max_y[2*i2+1]};
					end
				end
				else begin
					data_4_max[i2]   <= data_4_max[i2];
					data_4_max_y[i2] <= data_4_max_y[i2];
				end
			end
		end
	endgenerate
	
/* 1/8 */
	genvar i3;
	generate
		for(i3=0; i3<4; i3=i3+1) begin
			always @(posedge axis_aclk or posedge axis_areset) begin
				if(axis_areset == 1'b1) begin
					data_4_max_diff[i3] <= 'd0;
				end
				else if(i_lambda_data_valid_buf[4] == 1'b1) begin
					data_4_max_diff[i3] <= {data_4_max[2*i3][LAMBDA_WIDTH-1],data_4_max[2*i3]}
					                       - {data_4_max[2*i3+1][LAMBDA_WIDTH-1],data_4_max[2*i3+1]};
				end
				else begin
					data_4_max_diff[i3] <= data_4_max_diff[i3];
				end
			end
			always @(posedge axis_aclk or posedge axis_areset) begin
				if(axis_areset == 1'b1) begin
					data_8_max[i3]   <= 'd0;
					data_8_max_y[i3] <= 1'b0;
				end
				else if(i_lambda_data_valid_buf[5] == 1'b1) begin
					if(data_4_max_diff[i3][LAMBDA_WIDTH] == 1'b0) begin
						data_8_max[i3]   <= data_4_max[2*i3];
						data_8_max_y[i3] <= {1'b0,data_4_max_y[2*i3]};
					end
					else begin
						data_8_max[i3]   <= data_4_max[2*i3+1];
						data_8_max_y[i3] <= {1'b1,data_4_max_y[2*i3+1]};
					end
				end
				else begin
					data_8_max[i3]   <= data_8_max[i3];
					data_8_max_y[i3] <= data_8_max_y[i3];
				end
			end
		end
	endgenerate
	
/* 1/16 */
	genvar i4;
	generate
		for(i4=0; i4<2; i4=i4+1) begin
			always @(posedge axis_aclk or posedge axis_areset) begin
				if(axis_areset == 1'b1) begin
					data_8_max_diff[i4] <= 'd0;
				end
				else if(i_lambda_data_valid_buf[6] == 1'b1) begin
					data_8_max_diff[i4] <= {data_8_max[2*i4][LAMBDA_WIDTH-1],data_8_max[2*i4]}
					                       - {data_8_max[2*i4+1][LAMBDA_WIDTH-1],data_8_max[2*i4+1]};
				end
				else begin
					data_8_max_diff[i4] <= data_8_max_diff[i4];
				end
			end
			always @(posedge axis_aclk or posedge axis_areset) begin
				if(axis_areset == 1'b1) begin
					data_16_max[i4]   <= 'd0;
					data_16_max_y[i4] <= 1'b0;
				end
				else if(i_lambda_data_valid_buf[7] == 1'b1) begin
					if(data_8_max_diff[i4][LAMBDA_WIDTH] == 1'b0) begin
						data_16_max[i4]   <= data_8_max[2*i4];
						data_16_max_y[i4] <= {1'b0,data_8_max_y[2*i4]};
					end
					else begin
						data_16_max[i4]   <= data_8_max[2*i4+1];
						data_16_max_y[i4] <= {1'b1,data_8_max_y[2*i4+1]};
					end
				end
				else begin
					data_16_max[i4]   <= data_16_max[i4];
					data_16_max_y[i4] <= data_16_max_y[i4];
				end
			end
		end
	endgenerate
	
/* 1/32 */
	always @(posedge axis_aclk or posedge axis_areset) begin
		if(axis_areset == 1'b1) begin
			data_16_max_diff <= 'd0;
		end
		else if(i_lambda_data_valid_buf[8] == 1'b1) begin
			data_16_max_diff <= {data_16_max[0][LAMBDA_WIDTH-1],data_16_max[0]}
			                    - {data_16_max[1][LAMBDA_WIDTH-1],data_16_max[1]};
		end
		else begin
			data_16_max_diff <= data_16_max_diff;
		end
	end
	always @(posedge axis_aclk or posedge axis_areset) begin
		if(axis_areset == 1'b1) begin
			data_32_max      <= 'd0;
			data_32_max_y    <= 1'b0;
			data_32_max_addr <= 'd0;
		end
		else if(i_lambda_data_valid_buf[9] == 1'b1) begin
			if(data_16_max_diff[LAMBDA_WIDTH] == 1'b0) begin
				data_32_max   <= data_16_max[0];
				data_32_max_y <= {1'b0,data_16_max_y[0]};
			end
			else begin
				data_32_max   <= data_16_max[1];
				data_32_max_y <= {1'b1,data_16_max_y[1]};
			end
			data_32_max_addr <= i_lambda_data_addr[RAM_ADDR_WIDTH-1:0] - 1'd1;
		end
		else begin
			data_32_max      <= data_32_max;
			data_32_max_y    <= data_32_max_y;
			data_32_max_addr <= data_32_max_addr;
		end
	end
	
//================================================================================
// x search
//================================================================================
	always @(posedge axis_aclk or posedge axis_areset) begin
		if(axis_areset == 1'b1) begin
			data_32_peak_minus_max <= 'd0;
		end
		else if(i_lambda_data_valid_buf[10] == 1'b1) begin
			data_32_peak_minus_max <= {data_32_peak[LAMBDA_WIDTH-1],data_32_peak}
			                          - {data_32_max[LAMBDA_WIDTH-1],data_32_max};
		end
		else begin
			data_32_peak_minus_max <= data_32_peak_minus_max;
		end
	end
	
	always @(posedge axis_aclk or posedge axis_areset) begin
		if(axis_areset == 1'b1) begin
			data_32_peak      <= 'd0;
			data_32_peak_y    <= 5'd0;
			data_32_peak_addr <= 'd0;
		end
		else begin
			case(state)
				// IDLE: begin
				// end
				SEARCH: begin
					if(i_lambda_data_valid_buf[11] == 1'b1) begin
						if(data_32_peak_minus_max[LAMBDA_WIDTH] == 1'b0) begin // 大小一样，不更新，即以最早为准
							data_32_peak      <= data_32_peak;
							data_32_peak_y    <= data_32_peak_y;
							data_32_peak_addr <= data_32_peak_addr;
						end
						else begin
							data_32_peak      <= data_32_max;
							data_32_peak_y    <= data_32_max_y;
							data_32_peak_addr <= data_32_max_addr;
						end
					end
					else begin
						data_32_peak      <= data_32_peak;
						data_32_peak_y    <= data_32_peak_y;
						data_32_peak_addr <= data_32_peak_addr;
					end
				end
				CONFIRM: begin
					data_32_peak      <= data_32_peak;
					data_32_peak_y    <= data_32_peak_y;
					data_32_peak_addr <= data_32_peak_addr;
				end
				default: begin
					data_32_peak      <= 'd0;
					data_32_peak_y    <= 5'd0;
					data_32_peak_addr <= 'd0;
				end
			endcase
		end
	end
	
	always @(posedge axis_aclk or posedge axis_areset) begin
		if(axis_areset == 1'b1) begin
			fine_sync_ok   <= 1'b0;
			channel_length <= 5'd0;
			cp_start_addr  <= 'd0;
		end
		else begin
			case(state)
				// IDLE: begin
				// end
				// SEARCH: begin
				// end
				CONFIRM: begin
					if((state_dly1==SEARCH) && (data_32_peak[LAMBDA_WIDTH-1]==1'b0)) begin
						fine_sync_ok   <= 1'b1;
						channel_length <= data_32_peak_y + 1'd1;
						cp_start_addr  <= data_32_peak_addr - {{(RAM_ADDR_WIDTH-6){1'b0}},6'd32}
						                  - {{(RAM_ADDR_WIDTH-5){1'b0}},data_32_peak_y};
					end
					else begin
						fine_sync_ok   <= 1'b0;
						channel_length <= channel_length;
						cp_start_addr  <= cp_start_addr ;
					end
				end
				default: begin
					fine_sync_ok   <= 1'b0;
					channel_length <= 5'd0;
					cp_start_addr  <= 'd0;
				end
			endcase
		end
	end
	
	assign o_fine_sync_ok   = fine_sync_ok;
	assign o_channel_length = channel_length;
	assign o_cp_start_addr  = {{(16-RAM_ADDR_WIDTH){1'b0}},cp_start_addr};
	
endmodule
