`timescale 1ns / 1ps


module AdapTimer2(
	input                     resetn,
	input                     clock,
	input                     slv_reg_wren,
	input [2:0]               axi_awaddr,
	input [31:0]              S_AXI_WDATA,
(*mark_debug = "true"*)output reg [63:0]         adaptimer
);

// ==================================================================
// 内部reg
// ==================================================================
(*mark_debug = "true"*)reg [63:0]     clock_counter;
(*mark_debug = "true"*)reg [31:0]     control_register;
(*mark_debug = "true"*)reg [31:0]     safe_resolution_register;
(*mark_debug = "true"*)reg [31:0]     safe_counter_threshold;
(*mark_debug = "true"*)reg [31:0]     safe_counter;
(*mark_debug = "true"*)reg            flush_start;
(*mark_debug = "true"*)reg            timer_en;
(*mark_debug = "true"*)reg [63:0]     safetimer;
(*mark_debug = "true"*)reg [63:0]     temp_safetimer;
(*mark_debug = "true"*)reg [63:0]     high_resolution_timer;


// ==================================================================
// clock_counter计数器
// ==================================================================	
always @(posedge clock or negedge resetn) 
	begin
	if(resetn == 1'b0) 
		begin
		clock_counter <=64'h0;
		end
	else
		begin
		clock_counter <= clock_counter+1'b1;
		end
	end

// ==================================================================
// 控制精度的寄存器control_register
// ==================================================================
always @(posedge clock or negedge resetn)
	begin
	if(resetn == 1'b0)
		begin
		control_register <= 32'h0;
		end
	else	
		if(slv_reg_wren)
			begin
			case(axi_awaddr)
				4'h0:
					begin
					control_register <= S_AXI_WDATA[31:0];
					end
				default:
					begin
					control_register <= control_register; 
					end
			endcase
			end
		else
			begin
			control_register <= 32'h0;
			end
	end	

// ==================================================================
// 安全精度寄存器safe_resolution_register,timer使能信号timer_en，以及flush操作开始信号flush_start
// ==================================================================
always @(posedge clock or negedge resetn)
	begin
	if(resetn == 1'b0)
		begin
		safe_resolution_register <= 32'h0;
		safe_counter_threshold   <=32'h0;
		flush_start              <= 1'b0;
		timer_en                 <= 1'b0;
		end
	else
		begin
		case(control_register[31:24])
			32'h1://设置安全分辨率safe_resolution
				begin
				safe_resolution_register[23:0] <= control_register[23:0];
				end
			32'h2://设置安全持续时间safe_counter
				begin
				safe_counter_threshold[23:0] <= control_register[23:0];
				end
			32'h3://计时器开始
				begin
				timer_en <= 1'b1;
				end
			32'h4://运行flush操作
				begin
				flush_start <= 1'b1;
				end
			default:
				begin
				timer_en <= timer_en;
				flush_start <= 1'b0;
				end
		endcase
		end
	end




// ==================================================================
// 安全精度持续时间计时器safe_counter
// ==================================================================

always @(posedge clock or negedge resetn) 
	begin
    if ( resetn == 1'b0 ) 
		begin
        safe_counter <= 32'h0000;
		end
    else 
		begin
		case(flush_start)
			1'b1:
				begin
				safe_counter[23:0] <= safe_counter_threshold;
				end
			default:
				begin
				if(safe_counter != 32'h0)
					begin
					safe_counter <= safe_counter-1'b1;
					end
				else
					begin
					safe_counter <= safe_counter;
					end	
				end	
		endcase	
		end
	end	

// ==================================================================
// 自适应精度计时器high_resolution_timer
// ==================================================================	
always @(posedge clock or negedge resetn)
	begin
	if(resetn==1'b0)
		begin
		high_resolution_timer <=64'h0;
		end
	else
		begin
		high_resolution_timer <= clock_counter;
		end	
	end	
	

// ==================================================================
// 自适应精度计时器safetimer
// ==================================================================	
always @(posedge clock or negedge resetn)
	begin
	if(resetn==1'b0)
		begin
		safetimer <=64'h0;
		end
	else
		begin
		temp_safetimer <= clock_counter >> safe_resolution_register;
		safetimer <= temp_safetimer << safe_resolution_register;
		end	
	end
	

// ==================================================================
// 自适应精度计时器adaptimer
// ==================================================================	
always @(posedge clock or negedge resetn)
	begin
	if(resetn==1'b0)
		begin
		adaptimer <=64'h0;
		end
	else
		begin
		if(safe_counter != 32'h0)
			begin
			adaptimer <= safetimer;
			end
		else
			begin
			if(timer_en == 1'b0)
				begin
				adaptimer <= safetimer;
				end
			else
				begin
				adaptimer <= high_resolution_timer;
				end
			end		
		end	
	end

	
endmodule
	
	
	
	