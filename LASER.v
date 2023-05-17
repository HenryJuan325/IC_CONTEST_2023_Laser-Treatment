`timescale 1ns/10ps
module LASER (
input CLK,
input RST,
input [3:0] X,
input [3:0] Y,
output reg [3:0] C1X,
output reg [3:0] C1Y,
output reg [3:0] C2X,
output reg [3:0] C2Y,
output reg DONE);

// ----------------------------------------------------
// parameter & genvar
// ----------------------------------------------------
parameter Width = 6'd40;
parameter pipe  = 2'd2;


//----------cao---------------// 

parameter S_LOAD1  = 3'b000;
parameter S_INPUT  = 3'b001;//1
parameter S_STEP1  = 3'b011;//3
parameter S_STEPB  = 3'b010;//2
parameter S_LOADB  = 3'b110;
parameter S_STEPA  = 3'b100;//4
parameter S_LOADA  = 3'b101;
parameter S_DONE   = 3'b111;
reg [2:0]c_state, n_state;

genvar i , j;

// ----------------------------------------------------
// regs & wire
// ----------------------------------------------------

//----------cao---------------// 

reg [3:0]dotx_r[39:0];
reg [3:0]doty_r[39:0]; 
reg [5:0]in_cnt;

//----------henry---------------// 
reg [39:0] current_flag;
reg [29:0] current_temp;
reg [39:0] previous_flag;
reg [5:0] current_sum;
reg [5:0] sum_temp;
wire [5:0] sum_add;
wire[5:0] current_sum_w;
reg [5:0] previous_sum;
reg [5:0] total;
wire [5:0] current_total;
wire current_sum_flag;

reg [3:0] max_xA;
reg [3:0] max_yA;
reg [3:0] max_xB;
reg [3:0] max_yB;

wire [9:0] flag_33, flag_40, flag_04, flag_before;
wire [8:0]temp[39:0];
reg [7:0] pos;

wire [4:0] diff_x[39:0];
wire [4:0] diff_y[39:0];
wire [3:0] diff_x_abs[39:0];
wire [3:0] diff_y_abs[39:0];
wire [9:0]flag;
wire total_flag;
// dotx_r, doty_r
reg  [1:0]pipe_cnt;
wire eof_pipe;

reg [3:0]previous_x;
reg [3:0]previous_y;
// ----------------------------------------------------
// design
// ----------------------------------------------------
assign sum_add = current_sum_w + sum_temp;
assign current_sum_flag = current_sum > sum_add;
always @(posedge CLK) begin
        case (c_state)
            S_INPUT: max_xA <= 4'd0;
            S_STEP1: max_xA <= (current_sum_flag) ? max_xA : pos[3:0]; 
            S_STEPA: max_xA <= (current_sum_flag) ? max_xA : pos[3:0];
            default: max_xA <= max_xA;                                          
        endcase                                                                 
end                                                                             
always @(posedge CLK) begin                                      
        case (c_state)                                                          
            S_INPUT: max_yA <= 4'd0;                                            
            S_STEP1: max_yA <= (current_sum_flag) ? max_yA : pos[7:4]; 
            S_STEPA: max_yA <= (current_sum_flag) ? max_yA : pos[7:4];
            default: max_yA <= max_yA;
        endcase
end
always @(posedge CLK) begin
        case (c_state)
            S_INPUT: max_xB <= 4'd0;
            S_STEPB: max_xB <= (current_sum_flag) ?  max_xB : pos[3:0];
            default: max_xB <= max_xB;                   
        endcase                                          
end                                                      
always @(posedge CLK) begin               
        case (c_state)                                   
            S_INPUT: max_yB <= 4'd0;                     
            S_STEPB: max_yB <= (current_sum_flag) ?  max_yB : pos[7:4];
            default: max_yB <= max_yB;
        endcase
end

always @(posedge CLK /*or posedge RST*/) begin
    //if (RST) previous_x <= 4'd0;
    //else begin

        case (c_state)
			S_INPUT: previous_x <=4'd0;
            S_LOAD1: previous_x <= max_xB;
            S_LOADB: previous_x <= max_xA;
			S_LOADA: previous_x <= max_xB;
            default: previous_x <= previous_x;
        endcase
    //end
end

always @(posedge CLK /*or posedge RST*/) begin
    //if (RST) previous_y <= 4'd0;
    //else begin
        case (c_state)
			S_INPUT: previous_y <=4'd0;
            S_LOAD1: previous_y <= max_yB;
            S_LOADB: previous_y <= max_yA;
			S_LOADA: previous_y <= max_yB;
            default: previous_y <= previous_y;
        endcase
    //end
end

always @(posedge CLK /*or posedge RST*/) begin
    //if (RST) pipe_cnt <= 1'd0;
    //else begin
        case (c_state)
			S_INPUT: pipe_cnt  <=1'd0;
            S_STEP1: pipe_cnt <= pipe_cnt + 1'd1;
			S_STEPA: pipe_cnt <= pipe_cnt + 1'd1;
			S_STEPB: pipe_cnt <= pipe_cnt + 1'd1;
            default: pipe_cnt <= pipe_cnt;
        endcase
    //end
end

assign eof_pipe = (&pipe_cnt);

always @(posedge CLK /*or posedge RST*/) begin
    //if (RST) sum_temp <= 5'd0;
   //else begin
		case (c_state)
			S_INPUT: sum_temp  <=5'd0;
            S_STEP1:if(eof_pipe)
						sum_temp <=0;
					else
						sum_temp <= sum_temp + current_sum_w;
			S_STEPA:if(eof_pipe)
						sum_temp <=0;
					else
						sum_temp <= sum_temp + current_sum_w;
			S_STEPB: 
					if(eof_pipe)
						sum_temp <=0;
					else
						sum_temp <= sum_temp + current_sum_w;
            default: sum_temp <= sum_temp;
        endcase
        
    //end
end

assign current_sum_w = flag[0] + flag[1] + flag[2] + flag[3] + flag[4]
					  +flag[5] + flag[6] + flag[7] + flag[8] + flag[9];
					  //+flag[10]+ flag[11]+ flag[12]+ flag[13]+ flag[14]
					  //+flag[15]+ flag[16]+ flag[17]+ flag[18]+ flag[19];
					  //+flag[20]+ flag[21]+ flag[22]+ flag[23]+ flag[24]
					  //+flag[25]+ flag[26]+ flag[27]+ flag[28]+ flag[29]
					  //+flag[30]+ flag[31]+ flag[32]+ flag[33]+ flag[34]
					  //+flag[35]+ flag[36]+ flag[37]+ flag[38]+ flag[39];
					  

always @(posedge CLK) begin
        case (c_state)
            S_INPUT: current_sum <= 6'd0;
            S_STEP1: current_sum <= (eof_pipe)?((current_sum_flag) ? current_sum : sum_add ): current_sum;
			S_LOAD1: current_sum <= 6'd0;                                      
            S_STEPB: current_sum <= (eof_pipe)?((current_sum_flag) ? current_sum : sum_add ): current_sum;
            S_LOADB: current_sum <= 6'd0;                                      
            S_STEPA: current_sum <= (eof_pipe)?((current_sum_flag) ? current_sum : sum_add ): current_sum;
            S_LOADA: current_sum <= 6'd0;
            default: current_sum <= current_sum;
        endcase
end

reg [3:0] sel_dotx[10 - 1:0];
reg [3:0] sel_doty[10 - 1:0];
reg  sel_pre [10 - 1:0];
wire [3:0] sel_d1[10 - 1:0];
wire [3:0] sel_d2[10 - 1:0];
wire [3:0] sel_d3[10 - 1:0];
wire [3:0] sel_d4[10 - 1:0];
always @(posedge CLK) begin
		if(c_state == S_STEP1 || c_state == S_STEPA || c_state == S_STEPB)
            current_temp <= {current_temp[19:0], flag_before};
		else
			current_temp <= 0;

end	

generate
for (i = 0; i < 10; i = i + 1) begin
	always@(*)begin
		//case(pipe_cnt)
		//2'b00: sel_dotx[i] = dotx_r[i+30];
		//2'b01: sel_dotx[i] = dotx_r[i+20];
		//2'b10: sel_dotx[i] = dotx_r[i+10];
		//2'b11: sel_dotx[i] = dotx_r[i];
		//default: sel_dotx[i] = 3'd0;
		//endcase
		sel_dotx[i] = dotx_r[i+30];
	end
	always@(*)begin
		//case(pipe_cnt)
		//2'b00: sel_doty[i] = doty_r[i+30];
		//2'b01: sel_doty[i] = doty_r[i+20];
		//2'b10: sel_doty[i] = doty_r[i+10];
		//2'b11: sel_doty[i] = doty_r[i];
		//default: sel_doty[i] = 3'd0;
		//endcase
		sel_doty[i] = doty_r[i+30];
	end
	always@(*)begin
		case(pipe_cnt)
		2'b00: sel_pre[i] = previous_flag[i+30];
		2'b01: sel_pre[i] = previous_flag[i+20];
		2'b10: sel_pre[i] = previous_flag[i+10];
		2'b11: sel_pre[i] = previous_flag[i];
		default: sel_pre[i] = 1'd0;
		endcase
	end
	
	//assign sel_dotx[i] = (pipe_cnt)? dotx_r[i] : dotx_r[i + Width/pipe];
	//assign sel_doty[i] = (pipe_cnt)? doty_r[i] : doty_r[i + Width/pipe];
    //assign sel_pre[i] =  (pipe_cnt)? previous_flag[i] : previous_flag[i + Width/pipe];
	//assign diff_x[i] = sel_dotx[i] - pos[3:0];
    //assign diff_y[i] = sel_doty[i] - pos[7:4];
    //assign diff_x_abs[i] = (diff_x[i][3:0]^{4{diff_x[i][4]}}) + {2'd0,diff_x[i][4]};
    //assign diff_y_abs[i] = (diff_y[i][3:0]^{4{diff_y[i][4]}}) + {2'd0,diff_y[i][4]};
	//assign sel_d1[i] = (sel_dotx[i] > pos[3:0])? sel_dotx[i] :pos[3:0];
	//assign sel_d2[i] = (sel_dotx[i] > pos[3:0])? pos[3:0] : sel_dotx[i];
	//assign sel_d3[i] = (sel_doty[i] > pos[7:4])? sel_doty[i] :pos[7:4];
	//assign sel_d4[i] = (sel_doty[i] > pos[7:4])? pos[7:4] : sel_doty[i];
	
	assign diff_x_abs[i] = (sel_dotx[i] > pos[3:0])? sel_dotx[i] - pos[3:0] : pos[3:0] - sel_dotx[i];
    assign diff_y_abs[i] = (sel_doty[i] > pos[7:4])? sel_doty[i] - pos[7:4] : pos[7:4] - sel_doty[i];
	//assign diff_x_abs[i] = sel_d1[i] - sel_d2[i];
	//assign diff_y_abs[i] = sel_d3[i] - sel_d4[i];
	

    // assign flag_33[i] = (&diff_x_abs[i][1:0]) && (&diff_y_abs[i][1:0]);
    assign flag_33[i] = (&diff_x_abs[i][1:0] ) & (&diff_y_abs[i][1:0] );
    assign flag_40[i] = ((diff_x_abs[i] == 4'd4) && (diff_y_abs[i] != 4'd0));
    assign flag_04[i] = ((diff_y_abs[i] == 4'd4) && (diff_x_abs[i] != 4'd0));
    assign flag_before[i] = (!(flag_33[i] || (flag_40[i]) || (flag_04[i]) || diff_x_abs[i] > 4'd4 || diff_y_abs[i] > 4'd4)); 
	//assign temp[i] = (diff_x_abs[i]*diff_x_abs[i] + diff_y_abs[i]*diff_y_abs[i]);
	//assign flag_before[i] = (temp[i] <= 9'd16);
	assign flag[i] = ( flag_before[i] | sel_pre[i]);

end
endgenerate




generate
for (i = 0; i < 40; i = i + 1) begin
    always @(posedge CLK) begin
            case (c_state)
                //S_STEP1: previous_flag[i] <= (current_sum < current_sum_w) ? flag[i] : current_flag[i]; // area down
                S_INPUT: previous_flag[i] <= 1'b0;
				S_LOAD1: previous_flag[i] <= current_flag[i]; // area down
                S_LOADB: previous_flag[i] <= current_flag[i]; 
                S_LOADA: previous_flag[i] <= current_flag[i];
                default: previous_flag[i] <= previous_flag[i];
            endcase
    end
	if(i <10)begin
		always @(posedge CLK) begin
				case (c_state)
					S_INPUT: current_flag[i] <= 1'b0;
					S_STEP1: current_flag[i] <= (eof_pipe)?(current_sum_flag) ? current_flag[i] : flag_before[i] : current_flag[i];
					S_LOAD1: current_flag[i] <= 1'b0;                                        
					S_STEPB: current_flag[i] <= (eof_pipe)?(current_sum_flag) ? current_flag[i] : flag_before[i] : current_flag[i];
					S_LOADB: current_flag[i] <= 1'b0;                                        
					S_STEPA: current_flag[i] <= (eof_pipe)?(current_sum_flag) ? current_flag[i] : flag_before[i] : current_flag[i];
					S_LOADA: current_flag[i] <= 1'b0;
					default: current_flag[i] <= current_flag[i];
				endcase
		end
	end else begin
		always @(posedge CLK) begin
				case (c_state)
					S_INPUT: current_flag[i] <= 1'b0;
					S_STEP1: current_flag[i] <=(eof_pipe)?(current_sum_flag) ? current_flag[i] :  current_temp[i-10] : current_flag[i];
							//if(eof_pipe && !current_sum_flag) 
								//current_flag[i] <= current_temp[i-10];
					S_LOAD1: current_flag[i] <= 1'b0;                                                             
					S_STEPB: current_flag[i] <= (eof_pipe)?(current_sum_flag) ? current_flag[i] : current_temp[i-10] : current_flag[i];
					S_LOADB: current_flag[i] <= 1'b0;                                                             
					S_STEPA: current_flag[i] <= (eof_pipe)?(current_sum_flag) ? current_flag[i] : current_temp[i-10] : current_flag[i];
					S_LOADA: current_flag[i] <= 1'b0;
					default: current_flag[i] <= current_flag[i];
				endcase
		end
	end
end
endgenerate

always @(posedge CLK or posedge RST) begin
    if (RST) pos <= 8'd0;
    else if(c_state == S_STEP1 || c_state == S_STEPB || c_state == S_STEPA) pos <= pos + {7'd0,eof_pipe};
    else pos <= 8'd0;
	//if (RST) pos <= 8'd0;
	//else if(c_state == S_STEP1)
	//	pos <= pos + {7'd0,eof_pipe};
	//else if(c_state == S_STEPB)
	//	pos <= pos + {7'd0,eof_pipe};
    //else if(c_state == S_STEPA)
	//	pos <= pos + {7'd0,eof_pipe};
	//else 
	//	pos <= 8'd0;
end






//========================================
//	FSM
//========================================
always@(posedge CLK, posedge RST)begin
	if(RST)
		c_state <= S_INPUT;
	else
		c_state <= n_state;
end

always@(*)begin
	case(c_state)
	//S_RST : n_state =S_INPUT;
	S_INPUT: if(in_cnt == 6'd39) n_state =S_STEP1;
			 else			     n_state =S_INPUT;
	S_STEP1: if(&pos & eof_pipe) n_state = S_LOAD1;
			 else				 n_state = S_STEP1;
	S_LOAD1: n_state = S_STEPB;
	S_STEPB: if(&pos & eof_pipe) 			 n_state = S_LOADB;
			 else				 n_state = S_STEPB;
	S_LOADB: if(previous_x == max_xB && previous_y == max_yB)
				n_state = S_DONE;
			 else
				n_state = S_STEPA;
	S_STEPA: if(&pos & eof_pipe) 			 n_state = S_LOADA;
			 else			     n_state = S_STEPA;
	S_LOADA: if(previous_x == max_xA && previous_y == max_yA)
				n_state = S_DONE;
			 else
				n_state = S_STEPB;
	S_DONE: n_state = S_INPUT;
	default:n_state = S_INPUT;
	endcase
end

// ----------------------------------------------------
// INPUT
// ----------------------------------------------------

always@(posedge CLK, posedge RST)begin
	if(RST)begin
		in_cnt <= 6'b0;
	end else begin
		if(c_state == S_INPUT && (!DONE))
			in_cnt <= in_cnt + 6'd1;
		else
			in_cnt <= 6'b0;
	end
end

generate
	for( i =0; i< 40; i= i + 1) begin 
		if(i == 39)begin
			always@(posedge CLK) begin //, posedge RST
				if(c_state == S_INPUT && (!DONE))
					dotx_r[i] <= X;
				else if(c_state == S_STEP1 || c_state == S_STEPB || c_state == S_STEPA)
					dotx_r[i] <= dotx_r[i-10];
				
			end
		end else begin
			always@(posedge CLK) begin //, posedge RST
					if(c_state == S_INPUT)
						dotx_r[i] <= dotx_r[i+1];
					else if(c_state == S_STEP1 || c_state == S_STEPB || c_state == S_STEPA)begin
						if(i <10)
							dotx_r[i] <= dotx_r[30+i];
						else
							dotx_r[i] <= dotx_r[i-10];
					end
				
			end
		end
	end
endgenerate

generate
	for( i =0; i< 40; i= i + 1) begin 
		if(i == 39)begin
			always@(posedge CLK) begin
					if(c_state == S_INPUT && (!DONE))
						doty_r[i] <= Y;
					else if(c_state == S_STEP1 || c_state == S_STEPB || c_state == S_STEPA)
					doty_r[i] <= doty_r[i-10];
			end
		end else begin
			always@(posedge CLK) begin
					if(c_state == S_INPUT)
						doty_r[i] <= doty_r[i+1];
					else if(c_state == S_STEP1 || c_state == S_STEPB || c_state == S_STEPA)begin
						if(i <10)
							doty_r[i] <= doty_r[30+i];
						else
							doty_r[i] <= doty_r[i-10];
					end
				
			end
		end
	end
endgenerate

// ----------------------------------------------------
// OUTPUT
// ----------------------------------------------------
always@(posedge CLK, posedge RST)begin
	if(RST)begin
		DONE <= 1'b0;
	end else begin
		if(c_state == S_DONE)
			DONE <= 1'b1;
		else
			DONE <= 1'b0;
	end
end

always@(posedge CLK, posedge RST)begin
	if(RST)begin
		C1X <= 4'b0;
	end else begin
		if(c_state == S_DONE)
			C1X <= max_xA;//total_max_xA;
		else
			C1X <= 4'b0;
	end
end

always@(posedge CLK, posedge RST)begin
	if(RST)begin
		C1Y <= 4'b0;
	end else begin
		if(c_state == S_DONE)
			C1Y <= max_yA;//total_max_yA;
		else
			C1Y <= 4'b0;
	end
end

always@(posedge CLK, posedge RST)begin
	if(RST)begin
		C2X <= 4'b0;
	end else begin
		if(c_state == S_DONE)
			C2X <= max_xB;//total_max_xB;
		else
			C2X <= 4'b0;
	end
end

always@(posedge CLK, posedge RST)begin
	if(RST)begin
		C2Y <= 4'b0;
	end else begin
		if(c_state == S_DONE)
			C2Y <= max_yB;//total_max_yB;
		else
			C2Y <= 4'b0;
	end
end


endmodule


