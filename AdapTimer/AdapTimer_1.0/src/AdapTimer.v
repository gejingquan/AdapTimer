`timescale 1ns / 1ps


module AdapTimer(
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
(*mark_debug = "true"*)reg [7:0]      resolution_register;
(*mark_debug = "true"*)reg [7:0]      safe_resolution_register;
(*mark_debug = "true"*)reg [63:0]     safetimer;
(*mark_debug = "true"*)reg [63:0]     temp_safetimer;
(*mark_debug = "true"*)reg [63:0]     high_resolution_timer;
(*mark_debug = "true"*)reg            flush_start;
(*mark_debug = "true"*)reg            timer_en;
(*mark_debug = "true"*)reg [31:0]     safe_counter;


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
// 精度控制器resolution_register/safe_resolution_register,以及flush操作开始信号flush_start
// ==================================================================
always @(posedge clock or negedge resetn)
	begin
	if(resetn == 1'b0)
		begin
		resolution_register      <= 8'h10;
		safe_resolution_register <= 8'h10;
		flush_start              <= 1'b0;
		timer_en                 <= 1'b0;
		end
	else
		begin
		case(control_register)
			32'h1://降低分辨率
				begin
				resolution_register <= resolution_register + 1'b1;
				end
			32'h2://提高分辨率
				begin
				resolution_register <= resolution_register - 1'b1;
				end
			32'h3://确定安全分辨率
				begin
				safe_resolution_register <= resolution_register;
				timer_en <= 1'b1;
				end
			32'h4://运行flush操作
				begin
				flush_start <= 1'b1;
				end
			default:
				begin
				resolution_register <= resolution_register;
				timer_en <= timer_en;
				flush_start <= 1'b0;
				end
		endcase
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
				safe_counter <= 32'h1000;
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